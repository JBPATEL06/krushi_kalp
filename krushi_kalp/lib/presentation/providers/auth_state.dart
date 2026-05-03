import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'auth_state.freezed.dart';

@freezed
abstract class AuthState with _$AuthState {
  const factory AuthState({
    User? user,
    String? role,
    String? username,
    @Default(false) bool isLoading,
    @Default(false) bool isAuthCheckComplete,
    @Default(false) bool isPasswordRecovery,
    String? localSessionId,
    String? errorMessage,
  }) = _AuthState;

  const AuthState._();

  bool get isLoggedIn => user != null;
  bool get isAdmin => role == 'Admin';
  String get userRole => role ?? 'User';
}
