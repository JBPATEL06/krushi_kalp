import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/env/env.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/crashlytics_service.dart';

class AuthService {
  // Singleton
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static AuthService get instance => _instance;

  final _supabase = Supabase.instance.client;

  SupabaseClient get supabaseClient => _supabase;

  // Get the current user
  User? get currentUser {
    try {
      return _supabase.auth.currentUser;
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'Get current user failed');
      return null;
    }
  }

  // Listen to auth state changes
  Stream<AuthState> get onAuthStateChange => _supabase.auth.onAuthStateChange;

  // Sign in with Google (Native Flow)
  Future<void> signInWithGoogle() async {
    // 1. Perform Native Google Login
    // Note: You must configure SHA-1 in Google Cloud for Android to work.
    // 'serverClientId' is REQUIRED for Android to get the valid ID token (use your WEB Client ID here).

    final webClientId = Env.googleWebClientId;

    final GoogleSignIn googleSignIn = GoogleSignIn(
      // For WEB, we must explicitly pass 'clientId' and NOT 'serverClientId'
      clientId: kIsWeb ? webClientId : null,
      serverClientId: kIsWeb ? null : webClientId,
    );

    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

    if (googleUser == null) {
      // User canceled the sign-in flow
      return;
    }

    // 2. Obtain the auth details (ID Token & Access Token)
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    final String? accessToken = googleAuth.accessToken;
    final String? idToken = googleAuth.idToken;

    if (idToken == null) {
      throw 'No ID Token found. Make sure your Web Client ID is correct.';
    }

    // 3. Sign in to Supabase using the tokens
    final response = await Supabase.instance.client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );

    // 4. Check & Create Profile (Auto-Signup)
    final user = response.user;
    if (user != null) {
      await ensureProfileExists(user);
      await updateSessionId(user.id);

      // Tag user in Crashlytics
      await CrashlyticsService.instance.setUser(user.id);
      CrashlyticsService.instance
          .log('User signed in with Google: ${user.email}');
    }
  }

  // Sign In with Email and Password (Web Priority)
  Future<AuthResponse> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final user = response.user;
    if (user != null) {
      await ensureProfileExists(user);
      await updateSessionId(user.id);

      // Tag user in Crashlytics
      await CrashlyticsService.instance.setUser(user.id);
      CrashlyticsService.instance
          .log('User signed in with Email: ${user.email}');
    }
    return response;
  }

  Future<AuthResponse> signInWithIdToken({
    required OAuthProvider provider,
    required String idToken,
    String? accessToken,
  }) async {
    final response = await _supabase.auth.signInWithIdToken(
      provider: provider,
      idToken: idToken,
      accessToken: accessToken,
    );

    final user = response.user;
    if (user != null) {
      await ensureProfileExists(user);
      await updateSessionId(user.id);

      // Tag user in Crashlytics
      await CrashlyticsService.instance.setUser(user.id);
      CrashlyticsService.instance
          .log('User signed in with ID Token: ${user.email}');
    }
    return response;
  }

  Future<void> linkGoogleAccount() async {
    final webClientId = Env.googleWebClientId;
    
    final GoogleSignIn googleSignIn = GoogleSignIn(
      clientId: kIsWeb ? webClientId : null,
      serverClientId: kIsWeb ? null : webClientId,
    );

    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    if (googleUser == null) return;

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final String? idToken = googleAuth.idToken;
    final String? accessToken = googleAuth.accessToken;

    if (idToken == null) throw 'No ID Token found';

    // Link the provider by signing in with the ID token while already authenticated
    await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
    
    CrashlyticsService.instance.log('User linked Google account: ${googleUser.email}');
  }

  // NEW: Sign Up with Email and Password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
  }

  // Helper to create profile if it doesn't exist
  Future<void> ensureProfileExists(User user, [String? providedName]) async {
    try {
      final profile = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (profile == null) {
        // Extract real name from:
        // 1. Provided name (from manual signup)
        // 2. Google Auth metadata (usually 'full_name' or 'name')
        // 3. Fallback to email prefix
        final metadata = user.userMetadata ?? {};
        final String displayName = providedName ?? 
            metadata['full_name'] ??
            metadata['name'] ??
            user.email?.split('@')[0] ??
            'User';

        await Supabase.instance.client.from('users').insert({
          'id': user.id,
          'email': user.email,
          'username': displayName,
          'language': 'en', // Default Language
        });
      }
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'Profile sync failed during sign-in');
    }
  }

  // Sign out
  Future<void> signOut() async {
    final user = currentUser;
    try {
      if (user != null) {
        await clearSession(user.id);
        CrashlyticsService.instance.log('User signing out: ${user.email}');
        await CrashlyticsService.instance.clearUser();
      }
    } catch (e, stack) {
      CrashlyticsService.instance
          .recordError(e, stack, reason: 'Logout session cleanup failed');
    } finally {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_role');
      await _supabase.auth.signOut();
    }
  }

  // NEW: Update Session ID on Login
  Future<void> updateSessionId(String userId, [String? sessionId]) async {
    final finalSessionId = sessionId ??
        DateTime.now().millisecondsSinceEpoch.toString() +
            userId.substring(0, 4);
    try {
      await _supabase
          .from('users')
          .update({'session_id': finalSessionId}).eq('id', userId);
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'Session ID update failed');
    }
  }

  Future<String?> getSessionId(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select('session_id')
          .eq('id', userId)
          .maybeSingle();
      return response?['session_id'] as String?;
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'Get session ID failed');
      return null;
    }
  }

  RealtimeChannel getUserChannel(String userId) {
    return _supabase.channel('public:users:$userId');
  }

  void removeChannel(RealtimeChannel channel) {
    _supabase.removeChannel(channel);
  }

  // NEW: Clear Session ID on Logout
  Future<void> clearSession(String userId) async {
    try {
      await _supabase
          .from('users')
          .update({'session_id': null}).eq('id', userId);
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'Session clear failed');
    }
  }

  RealtimeChannel getSessionChannel(String userId) {
    return _supabase.channel('public:users:id=eq.$userId').onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'users',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: userId,
          ),
          callback: (payload) {}, // Handled by listener in Provider
        );
  }

  // --- PROFILE MANAGEMENT ---

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response =
          await _supabase.from('users').select().eq('id', userId).maybeSingle();
      return response;
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'Get user profile failed');
      return null;
    }
  }

  Stream<Map<String, dynamic>?> streamUserProfile(String userId) {
    return _supabase
        .from('users')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((rows) => rows.isNotEmpty ? rows.first : null);
  }

  Future<void> updateProfile(String userId, Map<String, dynamic> data) async {
    try {
      await _supabase.from('users').update(data).eq('id', userId);
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'Update profile failed');
      throw Exception('Failed to update profile: $e');
    }
  }

  // Check if user is logged in
  bool get isLoggedIn => currentUser != null;

  // NEW: Fetch User Role
  Future<String?> getUserRole([String? userId]) async {
    final targetId = userId ?? currentUser?.id;
    if (targetId == null) return null;

    try {
      final response = await _supabase
          .from('users')
          .select('role')
          .eq('id', targetId)
          .maybeSingle();

      if (response != null) {
        final role = response['role'] as String?;
        if (role != null) {
          // Cache the role for main.dart optimization
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_role', role);
        }
        return role;
      }
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'Get user role failed');
    }
    return null;
  }

  /// Synchronous-ish way to get role from cache (used in main.dart)
  Future<String?> getCachedRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_role');
  }

  Future<int?> getUserDbId(String authId) async {
    try {
      final response = await _supabase
          .from('users')
          .select('user_id')
          .eq('id', authId)
          .maybeSingle();
      return response?['user_id'] as int?;
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'Get user DB ID failed');
      return null;
    }
  }

  // --- PASSWORD RECOVERY ---

  /// Triggers a password reset email from Supabase.
  Future<void> resetPasswordForEmail(String email) async {
    try {
      // 'redirectTo' should be your app's deep link (e.g., io.supabase.krushikalp://login-callback/)
      // Supabase uses this to redirect the user after they click the link.
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: kIsWeb ? null : 'io.supabase.krushikalp://reset-callback/',
      );
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'Reset password request failed');
      rethrow;
    }
  }

  /// Updates the password for the currently authenticated user (session).
  Future<void> updateUserPassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'Update password failed');
      rethrow;
    }
  }
}
