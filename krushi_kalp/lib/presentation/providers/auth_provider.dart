import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/services/auth_service.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/env/env.dart';
import '../../utils/network_utils.dart';
import '../utils/navigator_key.dart';
import '../../utils/crashlytics_service.dart';
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

  static String get _webClientId => Env.googleWebClientId;

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
        await _initSessionMonitoring();
        _startPeriodicSessionCheck();
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
            await _initSessionMonitoring();
          } else if (event == AuthChangeEvent.signedOut) {
            _userRole = null;
            _currentUser = null;
            _localSessionId = null;
            await _sessionSubscription?.unsubscribe();
            _sessionSubscription = null;
          }
          notifyListeners();
        } catch (e, stack) {
          CrashlyticsService.instance.recordError(e, stack, reason: 'AuthProvider: AuthStateChange listener failed');
        }
      });
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'AuthProvider: _init failed');
      _isAuthCheckComplete = true;
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
        final prefs = await SharedPreferences.getInstance();
        final rawSession = prefs.getString('session_id');
        _localSessionId = rawSession != null
            ? EncryptionService.decryptData(rawSession)
            : null;

        if (remoteSessionId != null) {
          if (_localSessionId == null) {
            _localSessionId = remoteSessionId;
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(
              'session_id',
              EncryptionService.encryptData(remoteSessionId),
            );
          } else if (remoteSessionId != _localSessionId) {
            if (_isExplicitLogin) return;
            _handleForceLogout();
            return;
          }
        }
      }

      if (_sessionSubscription != null) {
        AuthService.instance.removeChannel(_sessionSubscription!);
        _sessionSubscription = null;
      }

      _sessionSubscription =
          AuthService.instance.getSessionChannel(_currentUser!.id);

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
              final newSessionId = payload.newRecord['session_id'] as String?;
              if (newSessionId != null &&
                  _localSessionId != null &&
                  newSessionId != _localSessionId) {
                _handleForceLogout();
              }
            },
          )
          .subscribe();
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'AuthProvider: _initSessionMonitoring failed');
    }
  }

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
      final remoteSessionId =
          await AuthService.instance.getSessionId(_currentUser!.id);
      if (remoteSessionId != null && remoteSessionId != _localSessionId) {
        final now = DateTime.now().millisecondsSinceEpoch;
        final localTs = int.tryParse(_localSessionId ?? '0') ?? 0;

        if ((now - localTs) < 15000) return;
        _handleForceLogout();
      }
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'AuthProvider: _verifySession failed');
    }
  }

  Future<void> _handleForceLogout() async {
    if (_currentUser == null) return;

    // IMPORTANT: signOut() already triggers cancellation tokens
    await signOut(clearDbSession: false);

    final context = navigatorKey.currentContext;
    if (context != null) {
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );

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
      if (NetworkUtils.isNetworkError(e)) return;
      // Removed rethrow to prevent crashes during init if RLS/profiles are missing
    }
  }

  Future<void> signInWithGoogle() async {
    _setLoading(true);
    _isExplicitLogin = true;
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: kIsWeb ? _webClientId : null,
        serverClientId: kIsWeb ? null : _webClientId,
        scopes: const ['email', 'profile', 'openid'],
      );

      if (await googleSignIn.isSignedIn()) {
        try {
          await googleSignIn.disconnect();
        } catch (e, stack) {
          CrashlyticsService.instance.recordError(e, stack, reason: 'Failed to disconnect Google Sign In');
        }
      }
      await googleSignIn.signOut();

      final GoogleSignInAccount? googleUser =
          await googleSignIn.signIn().timeout(const Duration(seconds: 30));

      if (googleUser == null) {
        _setLoading(false);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication.timeout(const Duration(seconds: 30));
      final String? idToken = googleAuth.idToken;

      if (idToken == null) throw 'No ID Token found.';

      final response = await AuthService.instance
          .signInWithIdToken(
            provider: OAuthProvider.google,
            idToken: idToken,
            accessToken: googleAuth.accessToken,
          )
          .timeout(const Duration(seconds: 30));

      if (response.user != null) {
        await _handleAuthSuccess(response.user!);
      }
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
        final response =
            await AuthService.instance.signInWithEmailPassword(email, password);
        if (response.user != null) {
          await _handleAuthSuccess(response.user!);
        }
      } on AuthException catch (e) {
        if (e.message.contains('Invalid login credentials') ||
            e.statusCode == '400') {
          final signUpResponse = await AuthService.instance
              .signUp(email: email, password: password);
          if (signUpResponse.user != null) {
            if (signUpResponse.session != null) {
              await _handleAuthSuccess(signUpResponse.user!);
            } else {
              throw const AuthException(
                  'Account created. Please verify your email.');
            }
          }
        } else {
          rethrow;
        }
      }
    } finally {
      _isExplicitLogin = false;
      _setLoading(false);
    }
  }

  Future<void> _handleAuthSuccess(User user) async {
    await AuthService.instance.ensureProfileExists(user);
    await _fetchUserRole();

    final newSessionId = DateTime.now().millisecondsSinceEpoch.toString();
    _localSessionId = newSessionId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'session_id', EncryptionService.encryptData(newSessionId));

    try {
      await AuthService.instance.updateSessionId(user.id, newSessionId);
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'AuthProvider: updateSessionId failed');
    }

    try {
      await FCMService().initialize();
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'AuthProvider: FCM initialization failed during login');
    }

    try {
      await DownloadService().migrateOldDownloads(user.id);
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'AuthProvider: Download migration failed during login');
    }
  }

  /// Logs the user out. Cancels any active downloads for this user BEFORE clearing state.
  Future<void> signOut({bool clearDbSession = true}) async {
    _setLoading(true);
    try {
      // Step 1: Cancel active background downloads using remaining available state
      if (_currentUser != null) {
        DownloadService().cancelAllDownloadsForUser(_currentUser!.id);
      }

      if (clearDbSession && _currentUser != null) {
        try {
          await AuthService.instance.clearSession(_currentUser!.id);
        } catch (e, stack) {
          CrashlyticsService.instance.recordError(e, stack, reason: 'AuthProvider: clearSession failed during signOut');
        }
      }

      // Step 2: Clear platform-level auth
      await AuthService.instance.signOut();
      try {
        await FCMService().handleLogout();
      } catch (e, stack) {
        CrashlyticsService.instance.recordError(e, stack, reason: 'AuthProvider: FCM logout failed');
      }

      try {
        final GoogleSignIn googleSignIn = GoogleSignIn(
          clientId: kIsWeb ? _webClientId : null,
          serverClientId: kIsWeb ? null : _webClientId,
        );
        await googleSignIn.signOut();
      } catch (e, stack) {
        CrashlyticsService.instance.recordError(e, stack, reason: 'AuthProvider: Google signOut failed');
      }

      // Step 3: Wipe local state
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
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }
}
