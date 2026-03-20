import 'package:shared_preferences/shared_preferences.dart';

/// Persists auth token, userId, and last route so state survives app restarts.
class SessionStorage {
  SessionStorage._();

  static const _keyToken = 'auth_token';
  static const _keyRefreshToken = 'auth_refresh_token';
  static const _keyUserId = 'auth_user_id';
  static const _keyLastRoute = 'last_route';

  static Future<void> save({String? token, String? refreshToken, String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (token != null && token.isNotEmpty) {
        await prefs.setString(_keyToken, token);
      } else {
        await prefs.remove(_keyToken);
      }
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await prefs.setString(_keyRefreshToken, refreshToken);
      } else {
        await prefs.remove(_keyRefreshToken);
      }
      if (userId != null && userId.isNotEmpty) {
        await prefs.setString(_keyUserId, userId);
      } else {
        await prefs.remove(_keyUserId);
      }
    } catch (_) {}
  }

  static Future<Map<String, String?>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'token': prefs.getString(_keyToken),
        'refreshToken': prefs.getString(_keyRefreshToken),
        'userId': prefs.getString(_keyUserId),
      };
    } catch (_) {
      return {'token': null, 'refreshToken': null, 'userId': null};
    }
  }

  static Future<String?> loadLastRoute() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyLastRoute);
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveLastRoute(String route) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLastRoute, route);
    } catch (_) {}
  }

  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyToken);
      await prefs.remove(_keyRefreshToken);
      await prefs.remove(_keyUserId);
      await prefs.remove(_keyLastRoute);
    } catch (_) {}
  }
}
