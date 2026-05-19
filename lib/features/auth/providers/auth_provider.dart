import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_service.dart';

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final String? token;
  final String? name;
  final String? error;

  AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.token,
    this.name,
    this.error,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    String? token,
    String? name,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      token: token ?? this.token,
      name: name ?? this.name,
      error: error ?? this.error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _service;

  AuthNotifier(this._service) : super(AuthState()) {
    _tryRestore();
  }

  Future<void> _tryRestore() async {
    state = state.copyWith(isLoading: true);
    final token = await _service.readAccessToken();
    if (token != null) {
      final profile = await _service.profile(token);
      if (profile != null) {
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          token: token,
          name: profile['name'] as String?,
        );
        return;
      }
    }
    state = state.copyWith(isLoading: false, isAuthenticated: false);
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    final resp = await _service.login(email: email, password: password);
    if (resp != null && resp['authenticated'] == true) {
      final token = resp['access_token'] as String?;
      final refresh = resp['refresh_token'] as String?;
      if (token != null) {
        await _service.persistTokens(access: token, refresh: refresh);
        final profile = await _service.profile(token);
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          token: token,
          name: profile?['name'] as String?,
        );
        return true;
      }
    }
    state = state.copyWith(isLoading: false, error: 'Credenciales inválidas');
    return false;
  }

  Future<bool> signup(
      {required String username,
      required String name,
      required String email,
      required String password}) async {
    state = state.copyWith(isLoading: true, error: null);
    final ok = await _service.signup(
        username: username, name: name, email: email, password: password);
    state = state.copyWith(isLoading: false);
    return ok;
  }

  Future<void> logout() async {
    await _service.clearTokens();
    state = AuthState(isAuthenticated: false);
  }
}

final authServiceProvider = Provider((ref) => AuthService());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final svc = ref.read(authServiceProvider);
  return AuthNotifier(svc);
});
