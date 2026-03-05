import 'package:flutter/foundation.dart'; // For kIsWeb

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:google_sign_in/google_sign_in.dart'; // Standard import

class AuthService {
  // Get the current user
  User? get currentUser {
    try {
      return Supabase.instance.client.auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  // Listen to auth state changes
  Stream<AuthState> get onAuthStateChange =>
      Supabase.instance.client.auth.onAuthStateChange;

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
      await _ensureProfileExists(user);
      await updateSessionId(user.id); // Generate new session
    }
  }

  // Sign In with Email and Password (Web Priority)
  Future<void> signInWithEmailPassword(String email, String password) async {
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user != null) {
        await _ensureProfileExists(user);
        await updateSessionId(user.id);
      }
    } catch (e) {
      debugPrint('Error signing in with email: $e');
      rethrow; // Pass error to UI
    }
  }

  // Helper to create profile if it doesn't exist
  Future<void> _ensureProfileExists(User user) async {
    try {
      final profile = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (profile == null) {
        debugPrint('Creating new profile for ${user.email}');
        await Supabase.instance.client.from('users').insert({
          'id': user.id,
          'email': user.email,
          'username': user.email?.split('@')[0] ?? 'User',
          'language': 'en', // Default Language
          // 'role': 'Student', // Omitted: Let DB default 'Student' apply to avoid Enum errors
          // 'created_at': DateTime.now().toIso8601String(), // Let DB handle default
        });
      } else {
        debugPrint('Profile exists: ${profile['language']}');
      }
    } catch (e) {
      debugPrint('Error checking/creating profile: $e');
      // Don't block login if profile fails, but might cause issues later
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _clearSessionId(); // Clear DB session first
    try {
      await GoogleSignIn().signOut();
    } catch (e) {
      debugPrint('Error signing out of Google: $e');
    }
    await Supabase.instance.client.auth.signOut();
  }

  // NEW: Update Session ID on Login
  Future<void> updateSessionId(String userId) async {
    final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    // Ideally use UUID, but timestamp is sufficient for this purpose
    try {
      await Supabase.instance.client
          .from('users')
          .update({'session_id': sessionId}).eq('id', userId);

      // Store local session ID (using shared_preferences if available, or just rely on re-fetch?)
      // We need to store it locally to compare later.
      // Since this Service is not persistent state provider, we will rely on AuthProvider to manage the "active" session.
      // But we can store it in a static variable or SharedPreferences here if needed.
      // Actually, AuthProvider should handle the "Monitoring" part.
    } catch (e) {
      debugPrint('Error updating session ID: $e');
    }
  }

  // NEW: Clear Session ID on Logout (Optional, but good practice)
  Future<void> _clearSessionId() async {
    final user = currentUser;
    if (user == null) return;
    try {
      await Supabase.instance.client
          .from('users')
          .update({'session_id': null}).eq('id', user.id);
    } catch (e) {
      debugPrint('Error clearing session ID: $e');
    }
  }

  // Check if user is logged in
  bool get isLoggedIn => currentUser != null;

  // NEW: Fetch User Role
  Future<String?> getUserRole() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final response = await Supabase.instance.client
          .from('users')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();

      if (response != null) {
        return response['role'] as String?;
      }
    } catch (e) {
      debugPrint('Error fetching user role: $e');
    }
    return null;
  }
}
