import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_session.dart';

class AuthRepository {
  AuthRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      await _apiClient.postJson('/auth/login', body: {
        'email': email,
        'password': password,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
  }) async {
    try {
      await _apiClient.postJson('/users', body: {
        'name': _nameFromEmail(email),
        'email': email,
        'password': password,
        'looking_for': 'rent',
        'role': 'user',
        'user_type': 'buyer',
      });

      // Trigger OTP flow with existing login endpoint.
      await _apiClient.postJson('/auth/login', body: {
        'email': email,
        'password': password,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await _apiClient.postJson('/auth/verify-otp', body: {
        'email': email,
        'otp': otp,
      });
      final tokenMap = response['tokens'];
      String token = '';
      if (tokenMap is Map<String, dynamic>) {
        token = '${tokenMap['accessToken'] ?? ''}';
      }
      if (token.isEmpty) return false;
      final user = response['user'];
      String? userId;
      if (user is Map<String, dynamic>) {
        final parsed = '${user['id'] ?? ''}';
        userId = parsed.isEmpty ? null : parsed;
      }
      ApiSession.setSession(token: token, userId: userId);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> socialLogin(String provider) async {
    try {
      final response = await _apiClient.postJson('/auth/social-login', body: {'provider': provider});
      ApiSession.setToken('${response['token'] ?? ''}');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> requestPasswordReset(String email) async {
    try {
      await _apiClient.postJson('/auth/forgot-password', body: {'email': email});
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> resendOtp(String email) async {
    try {
      await _apiClient.postJson('/auth/resend-otp', body: {'email': email});
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _apiClient.postJson('/auth/logout', body: {});
    } catch (_) {
      // Ignore logout network errors and clear local session.
    } finally {
      ApiSession.clear();
    }
  }

  String _nameFromEmail(String email) {
    final local = email.split('@').first.trim();
    if (local.isEmpty) return 'User';
    final normalized = local.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), ' ').trim();
    if (normalized.isEmpty) return 'User';
    final first = normalized[0].toUpperCase();
    final rest = normalized.length > 1 ? normalized.substring(1) : '';
    return '$first$rest';
  }
}
