import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core_providers.dart';
import '../models/user.dart';

enum SessionStatus { unknown, loggedIn, loggedOut }

class AuthState {
  final SessionStatus status;
  final AppUser? user;
  const AuthState({required this.status, this.user});

  AuthState copyWith({SessionStatus? status, AppUser? user}) =>
      AuthState(status: status ?? this.status, user: user ?? this.user);
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    final storage = ref.read(localStorageProvider);
    if (storage.accessToken != null) {
      // Optimistically mark logged-in; fetchCurrentUser() confirms/refreshes.
      Future.microtask(fetchCurrentUser);
      return const AuthState(status: SessionStatus.loggedIn);
    }
    return const AuthState(status: SessionStatus.loggedOut);
  }

  Future<void> fetchCurrentUser() async {
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get('/api/v1/auth/me');
      state = AuthState(status: SessionStatus.loggedIn, user: AppUser.fromJson(res.data));
    } catch (_) {
      await logout();
    }
  }

  /// Step 1: register the account. Returns nothing usable yet — an OTP is
  /// emailed automatically and must be verified via [verifySignupOtp]
  /// before the account can log in.
  Future<void> register({
    required String fullName,
    required String phone,
    required String email,
    required String password,
  }) async {
    final api = ref.read(apiClientProvider);
    await api.post('/api/v1/auth/register', data: {
      'full_name': fullName,
      'phone': phone,
      'email': email,
      'password': password,
      'role': 'patient',
    });
  }

  Future<void> resendOtp({required String email, required String purpose}) async {
    final api = ref.read(apiClientProvider);
    await api.post('/api/v1/auth/otp/request', data: {'email': email, 'purpose': purpose});
  }

  Future<void> verifySignupOtp({required String email, required String otp}) async {
    final api = ref.read(apiClientProvider);
    final res = await api.post('/api/v1/auth/otp/verify-signup', data: {'email': email, 'otp': otp});
    await _saveTokensAndLoadUser(res.data);
  }

  Future<void> loginWithPassword({required String phone, required String password}) async {
    final api = ref.read(apiClientProvider);
    final res = await api.post('/api/v1/auth/login', data: {'phone': phone, 'password': password});
    await _saveTokensAndLoadUser(res.data);
  }

  /// Step 1 of email-OTP login: verify phone+password, an OTP is emailed.
  Future<void> requestLoginOtp({required String phone, required String password}) async {
    final api = ref.read(apiClientProvider);
    await api.post('/api/v1/auth/login-otp/request', data: {'phone': phone, 'password': password});
  }

  Future<void> verifyLoginOtp({required String email, required String otp}) async {
    final api = ref.read(apiClientProvider);
    final res = await api.post('/api/v1/auth/login-otp/verify', data: {'email': email, 'otp': otp});
    await _saveTokensAndLoadUser(res.data);
  }

  Future<void> forgotPassword({required String email}) async {
    final api = ref.read(apiClientProvider);
    await api.post('/api/v1/auth/forgot-password', data: {'email': email});
  }

  Future<void> resetPassword({required String email, required String otp, required String newPassword}) async {
    final api = ref.read(apiClientProvider);
    await api.post('/api/v1/auth/reset-password', data: {'email': email, 'otp': otp, 'new_password': newPassword});
  }

  Future<void> _saveTokensAndLoadUser(Map<String, dynamic> tokenJson) async {
    final storage = ref.read(localStorageProvider);
    await storage.saveTokens(access: tokenJson['access_token'], refresh: tokenJson['refresh_token']);
    await fetchCurrentUser();
    await _registerPendingPushTokenIfAny();
  }

  String? _pendingPushToken;

  /// Called by main.dart whenever FCM hands us a token. If the user isn't
  /// logged in yet, we just remember it and send it right after login.
  Future<void> registerPushToken(String token) async {
    _pendingPushToken = token;
    await _registerPendingPushTokenIfAny();
  }

  Future<void> _registerPendingPushTokenIfAny() async {
    final token = _pendingPushToken;
    if (token == null || state.status != SessionStatus.loggedIn) return;
    try {
      final api = ref.read(apiClientProvider);
      await api.patch('/api/v1/auth/me/push-token', data: {'device_push_token': token});
    } catch (_) {
      // best-effort — a missed push-token registration isn't fatal
    }
  }

  Future<void> refreshCurrentUser() => fetchCurrentUser();

  Future<void> logout() async {
    final storage = ref.read(localStorageProvider);
    await storage.clearTokens();
    state = const AuthState(status: SessionStatus.loggedOut);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
