import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/network_utils.dart'; // Import NetworkUtils
import '../utils/navigator_key.dart';
import '../screens/login_screen.dart';
import '../../data/services/fcm_service.dart';
import '../../data/services/encryption_service.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  User? _currentUser;
  String? _userRole;
  bool _isLoading = false;
  bool _isAuthCheckComplete = false;
  String? _localSessionId;
  RealtimeChannel? _sessionSubscription;
  bool _isExplicitLogin = false;

  static const String _webClientId =
      '295803900120-5lqevo86ug6v8ef8el4vosmstjjo4rn0.apps.googleusercontent.com';

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
      _currentUser = _supabase.auth.currentUser;
      if (_currentUser != null) {
        await _fetchUserRole();
        await _initSessionMonitoring(); // Now enabled
        _startPeriodicSessionCheck(); // Periodic fallback

        // Initialize FCM for Auto-Login
        try {
          final fcmService = FCMService();
          await fcmService.initialize();
        } catch (e) {
          debugPrint('Error initializing FCM on auto-login: $e');
        }
      }
      _isAuthCheckComplete = true;
      notifyListeners();

      _supabase.auth.onAuthStateChange.listen((data) async {
        try {
          final AuthChangeEvent event = data.event;
          final Session? session = data.session;

          _currentUser = session?.user;
          if (event == AuthChangeEvent.signedIn) {
            await _fetchUserRole();
            // Removed redundant _initSessionMonitoring() call here.
            // It is already handled by _init() logic or handleAuthSuccess for explicit login.
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
      final response = await _supabase
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
                'AuthProvider: Syncing local session from remote: $remoteSessionId');
            _localSessionId = remoteSessionId;
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(
                'session_id', EncryptionService.encryptData(remoteSessionId));
          } else if (remoteSessionId != _localSessionId) {
            // Both exist but mismatch -> Force Logout
            if (_isExplicitLogin) {
              debugPrint(
                  'Session Mismatch during Explicit Login - Ignoring as we will overwrite session.');
              return;
            }
            debugPrint(
                'Session Mismatch on Init! Remote: $remoteSessionId, Local: $_localSessionId');
            _handleForceLogout();
            return;
          }
        }
      }

      // Ensure clean unsubscribe
      if (_sessionSubscription != null) {
        await _sessionSubscription!.unsubscribe();
        try {
          _supabase.removeChannel(_sessionSubscription!);
        } catch (_) {}
        _sessionSubscription = null;
      }

      final channelName = 'public:users:${_currentUser!.id}';
      debugPrint("AuthProvider: Creating Realtime Channel $channelName");

      _sessionSubscription = _supabase
          .channel(channelName)
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
                  'AuthProvider: Realtime Payload Received: ${payload.toString()}');
              final newSessionId = payload.newRecord['session_id'] as String?;
              debugPrint(
                  'AuthProvider: Session Update Received. New: $newSessionId, Local: $_localSessionId');
              if (newSessionId != null &&
                  _localSessionId != null &&
                  newSessionId != _localSessionId) {
                debugPrint(
                  'Session Mismatch! Force Logout triggered.',
                );
                _handleForceLogout();
              }
            },
          )
          .subscribe((status, error) {
        debugPrint(
            'AuthProvider: Session Channel Status: $status, Error: $error');
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
      final response = await _supabase
          .from('users')
          .select('session_id')
          .eq('id', _currentUser!.id)
          .maybeSingle();

      if (response != null) {
        final remoteSessionId = response['session_id'] as String?;
        if (remoteSessionId != null) {
          if (_localSessionId == null) {
            // Trust remote if local is missing (edge case for periodic check start)
            _localSessionId = remoteSessionId;
            // Grace period: If local session is very new (< 10 seconds), ignore mismatch
            // This handles the race condition where DB read happens before DB write completes.
            final localTs = int.tryParse(_localSessionId ?? '0') ?? 0;
            final remoteTs = int.tryParse(remoteSessionId) ?? 0;
            final now = DateTime.now().millisecondsSinceEpoch;

            if ((now - localTs) < 10000) {
              debugPrint(
                  'Periodic Check: Ignoring mismatch due to new session grace period.');
              return;
            }

            // Further check: If Local is NEWER than Remote, we just haven't synced yet.
            // Don't logout, just wait.
            if (localTs > remoteTs) {
              debugPrint(
                  'Periodic Check: Local session is newer than remote. Waiting for sync.');
              return;
            }

            debugPrint(
                'Periodic Check: Session Mismatch! Remote: $remoteSessionId, Local: $_localSessionId');
            _handleForceLogout();
          }
        }
      }
    } catch (e) {
      debugPrint("Error in periodic session check: $e");
    }
  }

  Future<void> _handleForceLogout() async {
    await signOut(clearDbSession: false);

    // ignore: use_build_context_synchronously
    final context = navigatorKey.currentContext;
    if (context != null) {
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );

      // ignore: use_build_context_synchronously
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Session Expired'),
            content: const Text(
              'You have been logged in on another device. For security reasons, you have been logged out of this device.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _fetchUserRole() async {
    if (_currentUser == null) return;
    try {
      final response = await _supabase
          .from('users')
          .select('role')
          .eq('id', _currentUser!.id)
          .maybeSingle();

      if (response != null) {
        _userRole = response['role'] as String?;
      }
    } catch (e) {
      debugPrint('AuthProvider: Error fetching role: $e');
      if (NetworkUtils.isNetworkError(e)) {
        debugPrint(
            'AuthProvider: Critical Network Error detected. Forcing Sign Out to prevent loop.');
        // Force sign out locally to stop retry loops
        _currentUser = null;
        _userRole = null;
        notifyListeners();
        // Do not call signOut() as it might try to hit the server and fail again.
        // warning: We might want _supabase.auth.signOut() to clear local storage?
        // _supabase.auth.signOut(); // This is async and might throw.
        // Let's rely on internal clear or just invalidating state.

        // Actually, we should try to clear persistence.
        try {
          // ignore: await_only_futures
          _supabase.auth.signOut(scope: SignOutScope.local);
        } catch (_) {}
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
        scopes: const [
          'email',
          'profile',
          'openid',
        ],
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

      final response = await _supabase.auth
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
        final response = await _supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
        if (response.user != null) {
          await _handleAuthSuccess(response.user!);
        }
      } on AuthException catch (e) {
        // If login failed (e.g. invalid credentials), try signing up
        if (e.message.contains('Invalid login credentials') ||
            e.statusCode == '400') {
          debugPrint("Login failed, attempting Sign Up for: $email");
          final signUpResponse = await _supabase.auth.signUp(
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
                  'Account created. Please verify your email if required.');
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
    await _ensureProfileExists(user);
    await _fetchUserRole();

    // Update Session ID LOCALLY FIRST
    final newSessionId = DateTime.now().millisecondsSinceEpoch.toString();
    _localSessionId = newSessionId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'session_id', EncryptionService.encryptData(newSessionId));

    try {
      final updates = {'session_id': newSessionId};
      await _supabase.from('users').update(updates).eq('id', user.id);

      // Initialize FCM
      try {
        final fcmService = FCMService();
        await fcmService.initialize();
      } catch (e) {
        debugPrint('Error initializing FCM: $e');
      }
    } catch (e) {
      debugPrint('Error updating session ID: $e');
    }
  }

  Future<void> _ensureProfileExists(User user) async {
    try {
      final profile = await _supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (profile == null) {
        final data = {
          'id': user.id,
          'email': user.email,
          'username': user.email?.split('@')[0] ?? 'User',
          'language': 'en',
        };
        await _supabase.from('users').upsert(data, onConflict: 'id');
      }
    } catch (e) {
      debugPrint('AuthProvider: Error ensuring profile: $e');
    }
  }

  Future<void> signOut({bool clearDbSession = true}) async {
    _setLoading(true);
    try {
      if (clearDbSession && _currentUser != null) {
        try {
          // We might need to check if we can update (RLS)
          await _supabase
              .from('users')
              .update({'session_id': null}).eq('id', _currentUser!.id);
        } catch (e) {
          debugPrint("Error clearing session: $e");
        }
      }

      // Supabase Sign Out
      await _supabase.auth.signOut();

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

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
