import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:go_router/go_router.dart';
import '../../core/env/env.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/download_service.dart';
import '../../data/services/encryption_service.dart';
import '../../data/services/fcm_service.dart';
import '../../utils/crashlytics_service.dart';
import '../../utils/network_utils.dart';
import '../utils/navigator_key.dart';
import 'auth_state.dart';

part 'auth_notifier.g.dart';

@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  Timer? _sessionTimer;
  RealtimeChannel? _sessionSubscription;
  bool _isExplicitLogin = false;

  static String get _webClientId => Env.googleWebClientId;

  @override
  AuthState build() {
    ref.onDispose(() {
      _sessionTimer?.cancel();
      _sessionSubscription?.unsubscribe();
    });

    // Initialize asynchronously safely after build completion
    Future(() => _init());

    return const AuthState();
  }

  Future<void> _init() async {
    try {
      final user = AuthService.instance.currentUser;
      if (user != null) {
        state = state.copyWith(user: user);
        await _fetchUserProfile();
        await _initSessionMonitoring();
        Future(() => _startPeriodicSessionCheck());
      }
      state = state.copyWith(isAuthCheckComplete: true);

      AuthService.instance.onAuthStateChange.listen((data) async {
        try {
          final AuthChangeEvent event = data.event;
          final Session? session = data.session;

          if (event == AuthChangeEvent.signedIn) {
            state = state.copyWith(user: session?.user);
            await _fetchUserProfile();
            await _initSessionMonitoring();
          } else if (event == AuthChangeEvent.signedOut) {
            _sessionSubscription?.unsubscribe();
            _sessionSubscription = null;
            state = const AuthState(isAuthCheckComplete: true);
          } else {
            state = state.copyWith(user: session?.user);
          }
        } catch (e, stack) {
          CrashlyticsService.instance.recordError(e, stack, reason: 'AuthNotifier: AuthStateChange listener failed');
        }
      });
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'AuthNotifier: _init failed');
      state = state.copyWith(isAuthCheckComplete: true);
    }
  }

  Future<void> _initSessionMonitoring() async {
    final user = state.user;
    if (user == null) return;

    try {
      final response = await AuthService.instance.supabaseClient
          .from('users')
          .select('session_id')
          .eq('id', user.id)
          .maybeSingle();

      if (response != null) {
        final remoteSessionId = response['session_id'] as String?;
        final prefs = await SharedPreferences.getInstance();
        final rawSession = prefs.getString('session_id');
        final localSessionId = rawSession != null
            ? EncryptionService.decryptData(rawSession)
            : null;

        if (remoteSessionId != null) {
          if (localSessionId == null) {
            final encryptedSessionId = EncryptionService.encryptData(remoteSessionId);
            await prefs.setString('session_id', encryptedSessionId);
            state = state.copyWith(localSessionId: remoteSessionId);
          } else if (remoteSessionId != localSessionId) {
            if (_isExplicitLogin) return;
            _handleForceLogout();
            return;
          } else {
            state = state.copyWith(localSessionId: localSessionId);
          }
        }
      }

      if (_sessionSubscription != null) {
        AuthService.instance.removeChannel(_sessionSubscription!);
        _sessionSubscription = null;
      }

      _sessionSubscription =
          AuthService.instance.getSessionChannel(user.id);

      _sessionSubscription!
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'users',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'id',
              value: user.id,
            ),
            callback: (payload) {
              final newSessionId = payload.newRecord['session_id'] as String?;
              if (newSessionId != null &&
                  state.localSessionId != null &&
                  newSessionId != state.localSessionId) {
                _handleForceLogout();
              }
            },
          )
          .subscribe();
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'AuthNotifier: _initSessionMonitoring failed');
    }
  }

  void _startPeriodicSessionCheck() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      await _verifySession();
    });
  }

  Future<void> _verifySession() async {
    final user = state.user;
    if (user == null || state.localSessionId == null) return;
    try {
      final remoteSessionId =
          await AuthService.instance.getSessionId(user.id);
      if (remoteSessionId != null && remoteSessionId != state.localSessionId) {
        final now = DateTime.now().millisecondsSinceEpoch;
        final localTs = int.tryParse(state.localSessionId ?? '0') ?? 0;

        if ((now - localTs) < 15000) return;
        _handleForceLogout();
      }
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'AuthNotifier: _verifySession failed');
    }
  }

  Future<void> _handleForceLogout() async {
    if (state.user == null) return;

    await signOut(clearDbSession: false);

    final context = navigatorKey.currentContext;
    if (context != null) {
      context.go('/login');

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

  Future<void> refreshProfile() async {
    await _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    final user = state.user;
    if (user == null) return;
    try {
      final profile = await AuthService.instance.getUserProfile(user.id);
      
      // FALLBACK: Use Google name if DB username is empty
      final dbUsername = profile?['username'] as String?;
      final googleName = user.userMetadata?['full_name'] as String? ?? 
                         user.userMetadata?['name'] as String?;
      final finalName = (dbUsername != null && dbUsername.trim().isNotEmpty)
          ? dbUsername
          : (googleName ?? 'Aspirant');

      if (profile != null) {
        state = state.copyWith(
          role: profile['role'] as String? ?? 'Student',
          username: finalName,
        );
      }
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'AuthNotifier: _fetchUserProfile failed');
      if (NetworkUtils.isNetworkError(e)) return;
    }
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true);
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
        state = state.copyWith(isLoading: false);
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
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> signInWithEmailPassword(String email, String password) async {
    state = state.copyWith(isLoading: true);
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
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> _handleAuthSuccess(User user) async {
    await AuthService.instance.ensureProfileExists(user);
    final profile = await AuthService.instance.getUserProfile(user.id);

    final newSessionId = DateTime.now().millisecondsSinceEpoch.toString();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'session_id', EncryptionService.encryptData(newSessionId));

    final dbUsername = profile?['username'] as String?;
    final googleName = user.userMetadata?['full_name'] as String? ?? 
                       user.userMetadata?['name'] as String?;
    final finalName = (dbUsername != null && dbUsername.trim().isNotEmpty)
        ? dbUsername
        : (googleName ?? 'Aspirant');

    state = state.copyWith(
      user: user,
      role: profile?['role'] as String? ?? 'Student',
      username: finalName,
      localSessionId: newSessionId,
    );

    try {
      await AuthService.instance.updateSessionId(user.id, newSessionId);
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'AuthNotifier: updateSessionId failed');
    }

    try {
      await FCMService().initialize();
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'AuthNotifier: FCM initialization failed during login');
    }

    try {
      await DownloadService().migrateOldDownloads(user.id);
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'AuthNotifier: Download migration failed during login');
    }
  }

  Future<void> signOut({bool clearDbSession = true}) async {
    state = state.copyWith(isLoading: true);
    final currentUser = state.user;
    try {
      if (currentUser != null) {
        DownloadService().cancelAllDownloadsForUser(currentUser.id);
      }

      if (clearDbSession && currentUser != null) {
        try {
          await AuthService.instance.clearSession(currentUser.id);
        } catch (e, stack) {
          CrashlyticsService.instance.recordError(e, stack, reason: 'AuthNotifier: clearSession failed during signOut');
        }
      }

      await AuthService.instance.signOut();
      try {
        await FCMService().handleLogout();
      } catch (e, stack) {
        CrashlyticsService.instance.recordError(e, stack, reason: 'AuthNotifier: FCM logout failed');
      }

      try {
        final GoogleSignIn googleSignIn = GoogleSignIn(
          clientId: kIsWeb ? _webClientId : null,
          serverClientId: kIsWeb ? null : _webClientId,
        );
        await googleSignIn.signOut();
      } catch (e, stack) {
        CrashlyticsService.instance.recordError(e, stack, reason: 'AuthNotifier: Google signOut failed');
      }

      state = const AuthState(isAuthCheckComplete: true);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('session_id');
      await _sessionSubscription?.unsubscribe();
      _sessionSubscription = null;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}
