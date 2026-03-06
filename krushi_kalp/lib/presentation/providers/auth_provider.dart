import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/services/auth_service.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../utils/network_utils.dart';
import '../utils/navigator_key.dart';
import '../screens/login_screen.dart';
import '../../data/services/fcm_service.dart';
import '../../data/services/encryption_service.dart';
import '../../data/services/download_service.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  String? _userRole;
  bool _isLoading = false;
  bool _isAuthCheckComplete = false;
  String? _localSessionId;
  RealtimeChannel? _sessionSubscription;
  bool _isExplicitLogin = false;

  static String get _webClientId => dotenv.env['GOOGLE_WEB_CLIENT_ID'] ?? '';

  User? get currentUser => _currentUser;
  String? get userRole => _userRole;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _userRole == 'Admin';
  bool get isAuthCheckComplete => _isAuthCheckComplete;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    try {
      _currentUser = AuthService.instance.currentUser;
      if (_currentUser != null) {
        await _fetchUserRole();
        await _initSessionMonitoring(); // Now enabled
        _startPeriodicSessionCheck(); // Periodic fallback
      }
      _isAuthCheckComplete = true;
      notifyListeners();

      AuthService.instance.onAuthStateChange.listen((data) async {
        try {
          final AuthChangeEvent event = data.event;
          final Session? session = data.session;

          _currentUser = session?.user;
          if (event == AuthChangeEvent.signedIn) {
            await _fetchUserRole();
            await _initSessionMonitoring(); // Now enabled
          } else if (event == AuthChangeEvent.signedOut) {
            _userRole = null;
            _currentUser = null;
            _localSessionId = null;
            await _sessionSubscription?.unsubscribe();
            _sessionSubscription = null;
          }
          notifyListeners();
        } catch (e) {
          debugPrint('AuthProvider: Error in auth state change: $e');
        }
      });
    } catch (e) {
      debugPrint('AuthProvider: Error in _init: $e');
      _isAuthCheckComplete = true; // Ensure UI doesn't hang
      notifyListeners();
    }
  }

  Future<void> _initSessionMonitoring() async {
    if (_currentUser == null) return;

    try {
      final response = await AuthService.instance.supabaseClient
          .from('users')
          .select('session_id')
          .eq('id', _currentUser!.id)
          .maybeSingle();

      if (response != null) {
        final remoteSessionId = response['session_id'] as String?;

        // Check Local Persistence
        final prefs = await SharedPreferences.getInstance();
        final rawSession = prefs.getString('session_id');
        _localSessionId = rawSession != null
            ? EncryptionService.decryptData(rawSession)
            : null;

        if (remoteSessionId != null) {
          if (_localSessionId == null) {
            // Local session missing but remote exists (e.g. fresh install or cleared data).
            // Trust the remote session for Auto-Login.
            debugPrint(
              'AuthProvider: Syncing local session from remote: $remoteSessionId',
            );
            _localSessionId = remoteSessionId;
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(
              'session_id',
              EncryptionService.encryptData(remoteSessionId),
            );
          } else if (remoteSessionId != _localSessionId) {
            // Both exist but mismatch -> Force Logout
            if (_isExplicitLogin) {
              debugPrint(
                'Session Mismatch during Explicit Login - Ignoring as we will overwrite session.',
              );
              return;
            }
            debugPrint(
              'Session Mismatch on Init! Remote: $remoteSessionId, Local: $_localSessionId',
            );
            _handleForceLogout();
            return;
          }
        }
      }

      // Ensure clean unsubscribe
      if (_sessionSubscription != null) {
        AuthService.instance.removeChannel(_sessionSubscription!);
        _sessionSubscription = null;
      }

      _sessionSubscription = AuthService.instance.getSessionChannel(
        _currentUser!.id,
      );
      debugPrint("AuthProvider: Monitoring Channel for ${_currentUser!.id}");

      _sessionSubscription!
          .onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'users',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'id',
          value: _currentUser!.id,
        ),
        callback: (payload) {
          debugPrint(
            'AuthProvider: Realtime Payload Received: ${payload.toString()}',
          );
          final newSessionId = payload.newRecord['session_id'] as String?;
          debugPrint(
            'AuthProvider: Session Update Received. New: $newSessionId, Local: $_localSessionId',
          );
          if (newSessionId != null &&
              _localSessionId != null &&
              newSessionId != _localSessionId) {
            debugPrint('Session Mismatch! Force Logout triggered.');
            _handleForceLogout();
          }
        },
      )
          .subscribe((status, error) {
        debugPrint(
          'AuthProvider: Session Channel Status: $status, Error: $error',
        );
      });
    } catch (e) {
      debugPrint('Error initializing session monitoring: $e');
    }
  }

  // Periodic fallback in case WebSocket disconnects
  Timer? _sessionTimer;
  void _startPeriodicSessionCheck() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      await _verifySession();
    });
  }

  Future<void> _verifySession() async {
    if (_currentUser == null || _localSessionId == null) return;
    try {
      final remoteSessionId = await AuthService.instance.getSessionId(
        _currentUser!.id,
      );
      if (remoteSessionId != null && remoteSessionId != _localSessionId) {
        // Grace period check: if local session is very new, ignore mismatch to allow DB sync
        final now = DateTime.now().millisecondsSinceEpoch;
        final localTs = int.tryParse(_localSessionId ?? '0') ?? 0;

        if ((now - localTs) < 15000) {
          debugPrint(
            'Periodic Check: Ignoring mismatch during 15s grace period.',
          );
          return;
        }

        debugPrint(
          'Periodic Check: Session Mismatch! Remote: $remoteSessionId, Local: $_localSessionId',
        );
        _handleForceLogout();
      }
    } catch (e) {
      debugPrint("Error in periodic session check: $e");
    }
  }

  Future<void> _handleForceLogout() async {
    if (_currentUser == null) return;

    // Clear state before showing dialog to prevent infinite loops
    await signOut(clearDbSession: false);

    final context = navigatorKey.currentContext;
    if (context != null) {
      // Use pushAndRemoveUntil to clear navigation stack
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );

      // Show alert after navigation
      Future.delayed(const Duration(milliseconds: 500), () {
        if (navigatorKey.currentContext != null) {
          showDialog(
            context: navigatorKey.currentContext!,
            barrierDismissible: false,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Security Alert'),
              content: const Text(
                'This account was recently logged into from another device. For your security, you have been logged out of this session.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      });
    }
  }

  Future<void> _fetchUserRole() async {
    if (_currentUser == null) return;
    try {
      _userRole = await AuthService.instance.getUserRole(_currentUser!.id);
    } catch (e) {
      debugPrint('AuthProvider: Error fetching role: $e');
      if (NetworkUtils.isNetworkError(e)) {
        // Network is offline — DO NOT sign out.
        // The user's local Supabase session is still valid; their role
        // will be re-fetched next time connectivity returns and they log in.
        // Signing out here was causing crashes when the no-internet gate
        // and auth state changes collided.
        debugPrint(
          'AuthProvider: Network offline — retaining current auth state.',
        );
        return;
      }
    }
  }

  Future<void> signInWithGoogle() async {
    _setLoading(true);
    _isExplicitLogin = true;
    try {
      if (kIsWeb) {
        debugPrint('Google Sign-In: Initializing Web Client ID: $_webClientId');
      } else {
        debugPrint('Google Sign-In: Initializing Mobile Flow');
      }

      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: kIsWeb ? _webClientId : null,
        serverClientId: kIsWeb ? null : _webClientId,
        scopes: const ['email', 'profile', 'openid'],
      );

      // Force account picker by clearing previous session
      if (await googleSignIn.isSignedIn()) {
        try {
          await googleSignIn.disconnect();
        } catch (_) {}
      }
      await googleSignIn.signOut();

      final GoogleSignInAccount? googleUser =
          await googleSignIn.signIn().timeout(
                const Duration(seconds: 30), // Increased for interactive flow
                onTimeout: () =>
                    throw 'Connection timeout while connecting to Google Sign In. Please check your internet.',
              );

      if (googleUser == null) {
        debugPrint('Google Sign-In: User cancelled sign-in flow.');
        _setLoading(false);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication.timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw 'Timeout retrieving authentication tokens.',
      );
      final String? accessToken = googleAuth.accessToken;
      final String? idToken = googleAuth.idToken;

      debugPrint(
        'Google Sign-In: Access Token: ${accessToken?.substring(0, 10)}...',
      );
      debugPrint(
        'Google Sign-In: ID Token: ${idToken != null ? "FOUND" : "NULL"}',
      );

      if (idToken == null) {
        throw 'No ID Token found. Web: Check Authorized Origins/Redirect URIs. Mobile: Check SHA-1/google-services.json.';
      }

      final response = await AuthService.instance
          .signInWithIdToken(
            provider: OAuthProvider.google,
            idToken: idToken,
            accessToken: accessToken,
          )
          .timeout(
            const Duration(seconds: 30), // Increased from 10s
            onTimeout: () =>
                throw 'Connection timeout while communicating with server.',
          );

      if (response.user != null) {
        await _handleAuthSuccess(response.user!);
      }
    } catch (e) {
      debugPrint('AuthProvider: Error signing in: $e');
      // Specific error messaging
      if (e.toString().contains('ClientException')) {
        debugPrint(
          'CRITICAL: ClientException detected. This usually means URL/Port mismatch.',
        );
        debugPrint(
          'Ensure "http://localhost:3000" is Authorized in Google Cloud Console.',
        );
      }
      rethrow;
    } finally {
      _isExplicitLogin = false;
      _setLoading(false);
    }
  }

  Future<void> signInWithEmailPassword(String email, String password) async {
    _setLoading(true);
    _isExplicitLogin = true;
    try {
      try {
        final response = await AuthService.instance.signInWithEmailPassword(
          email,
          password,
        );
        if (response.user != null) {
          await _handleAuthSuccess(response.user!);
        }
      } on AuthException catch (e) {
        // If login failed (e.g. invalid credentials), try signing up
        if (e.message.contains('Invalid login credentials') ||
            e.statusCode == '400') {
          debugPrint("Login failed, attempting Sign Up for: $email");
          final signUpResponse = await AuthService.instance.signUp(
            email: email,
            password: password,
          );

          if (signUpResponse.user != null) {
            // If session exists, mapped to auto-login (Confirm Email might be off)
            if (signUpResponse.session != null) {
              await _handleAuthSuccess(signUpResponse.user!);
            } else {
              // Email confirmation might be required
              // But for now, we just return, caller can check state or we throw info
              // However, without session, isLoggedIn remains false.
              throw const AuthException(
                'Account created. Please verify your email if required.',
              );
            }
          }
        } else {
          rethrow;
        }
      }
    } catch (e) {
      debugPrint('AuthProvider: Error in email auth flow: $e');
      rethrow;
    } finally {
      _isExplicitLogin = false;
      _setLoading(false);
    }
  }

  Future<void> _handleAuthSuccess(User user) async {
    await AuthService.instance.ensureProfileExists(user);
    await _fetchUserRole();

    // Update Session ID LOCALLY FIRST
    final newSessionId = DateTime.now().millisecondsSinceEpoch.toString();
    _localSessionId = newSessionId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'session_id',
      EncryptionService.encryptData(newSessionId),
    );

    try {
      await AuthService.instance.updateSessionId(user.id, newSessionId);
    } catch (e) {
      debugPrint('Error updating session ID: $e');
    }

    // Capture FCM Token for the newly logged-in user
    try {
      await FCMService().initialize();
    } catch (e) {
      debugPrint("Error initializing FCM after login: $e");
    }

    // Migrate files downloaded before the per-user directory system was enforced.
    // This is safe to call every login — it's a no-op if nothing needs moving.
    try {
      await DownloadService().migrateOldDownloads(user.id);
    } catch (e) {
      debugPrint('AuthProvider: Migration error (non-critical): $e');
    }
  }

  Future<void> signOut({bool clearDbSession = true}) async {
    _setLoading(true);
    try {
      if (clearDbSession && _currentUser != null) {
        try {
          await AuthService.instance.clearSession(_currentUser!.id);
        } catch (e) {
          debugPrint("Error clearing session: $e");
        }
      }

      // Supabase Sign Out
      await AuthService.instance.signOut();

      // FCM Cleanup
      try {
        await FCMService().handleLogout();
      } catch (e) {
        debugPrint("Error on FCM logout: $e");
      }

      // Google Sign Out (Force account picker next time)
      try {
        final GoogleSignIn googleSignIn = GoogleSignIn(
          clientId: kIsWeb ? _webClientId : null,
          serverClientId: kIsWeb ? null : _webClientId,
        );
        await googleSignIn.signOut();
        // await googleSignIn.disconnect(); // Optional: Revoke permissions completely
      } catch (e) {
        debugPrint("Error signing out of Google: $e");
      }

      _currentUser = null;
      _userRole = null;
      _localSessionId = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('session_id');
      await _sessionSubscription?.unsubscribe();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _sessionSubscription?.unsubscribe();
    super.dispose();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
