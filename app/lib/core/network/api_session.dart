import 'package:flutter/foundation.dart';

import 'session_storage.dart';

class ApiSession {
  ApiSession._();

  static String? bearerToken;
  static String? refreshToken;
  static String? currentUserId;
  static final ValueNotifier<int> authState = ValueNotifier<int>(0);

  static void setToken(String? token) {
    bearerToken = (token == null || token.isEmpty) ? null : token;
    SessionStorage.save(token: bearerToken);
    authState.value++;
  }

  static void setSession({
    required String? token,
    String? refreshToken,
    String? userId,
  }) {
    bearerToken = (token == null || token.isEmpty) ? null : token;
    ApiSession.refreshToken = (refreshToken == null || refreshToken.isEmpty) ? null : refreshToken;
    currentUserId = (userId == null || userId.isEmpty) ? null : userId;
    SessionStorage.save(token: bearerToken, refreshToken: ApiSession.refreshToken, userId: currentUserId);
    authState.value++;
  }

  static void clear() {
    bearerToken = null;
    refreshToken = null;
    currentUserId = null;
    SessionStorage.clear(); // fire-and-forget
    authState.value++;
  }

  /// Restore session from storage. Call before runApp in main().
  static Future<void> restore() async {
    final stored = await SessionStorage.load();
    bearerToken = stored['token'];
    refreshToken = stored['refreshToken'];
    currentUserId = stored['userId'];
    if (bearerToken != null && bearerToken!.isNotEmpty) {
      authState.value++;
    }
  }

  static bool get isAuthenticated => bearerToken != null && bearerToken!.isNotEmpty;
}
