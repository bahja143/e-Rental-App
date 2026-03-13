import 'package:shared_preferences/shared_preferences.dart';

/// Persists auth token and userId so session survives app restarts.
class SessionStorage {
  SessionStorage._();

  static const _keyToken = 'auth_token';
  static const _keyUserId = 'auth_user_id';

  static Future<void> save({String? token, String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (token != null && token.isNotEmpty) {
        await prefs.setString(_keyToken, token);
      } else {
        await prefs.remove(_keyToken);
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
        'userId': prefs.getString(_keyUserId),
      };
    } catch (_) {
      return {'token': null, 'userId': null};
    }
  }

  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyToken);
      await prefs.remove(_keyUserId);
    } catch (_) {}
  }
}
