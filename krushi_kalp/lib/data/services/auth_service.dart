import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
    } catch (_) {
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

    final webClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID'] ?? '';

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

  // NEW: Sign Up with Email and Password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signUp(email: email, password: password);
  }

  // Helper to create profile if it doesn't exist
  Future<void> ensureProfileExists(User user) async {
    try {
      final profile = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (profile == null) {
        

        // Extract real name from Google Auth metadata (usually 'full_name' or 'name')
        final metadata = user.userMetadata ?? {};
        final String displayName = metadata['full_name'] ??
            metadata['name'] ??
            user.email?.split('@')[0] ??
            'User';

        await Supabase.instance.client.from('users').insert({
          'id': user.id,
          'email': user.email,
          'username': displayName,
          'language': 'en', // Default Language
          // 'role': 'Student', // Omitted: Let DB default 'Student' apply to avoid Enum errors
          // 'created_at': DateTime.now().toIso8601String(), // Let DB handle default
        });
      } else {
        
      }
    } catch (e) {
      
      // Don't block login if profile fails, but might cause issues later
    }
  }

  // Sign out
  Future<void> signOut() async {
    final user = currentUser;
    if (user != null) {
      await clearSession(user.id);
      CrashlyticsService.instance.log('User signing out: ${user.email}');
      await CrashlyticsService.instance.clearUser();
    }
    try {
      await GoogleSignIn().signOut();
    } catch (e) {
      
    }
    await _supabase.auth.signOut();
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
    } catch (e) {
      
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
    } catch (e) {
      
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
    } catch (e) {
      
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
    } catch (e) {
      
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
    } catch (e) {
      
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
        return response['role'] as String?;
      }
    } catch (e) {
      
    }
    return null;
  }

  Future<int?> getUserDbId(String authId) async {
    try {
      final response = await _supabase
          .from('users')
          .select('user_id')
          .eq('id', authId)
          .maybeSingle();
      return response?['user_id'] as int?;
    } catch (e) {
      
      return null;
    }
  }
}
