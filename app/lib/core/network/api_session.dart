import 'package:flutter/foundation.dart';

class ApiSession {
  ApiSession._();

  static String? bearerToken;
  static String? currentUserId;
  static final ValueNotifier<int> authState = ValueNotifier<int>(0);

  static void setToken(String? token) {
    bearerToken = (token == null || token.isEmpty) ? null : token;
    authState.value++;
  }

  static void setSession({
    required String? token,
    String? userId,
  }) {
    bearerToken = (token == null || token.isEmpty) ? null : token;
    currentUserId = (userId == null || userId.isEmpty) ? null : userId;
    authState.value++;
  }

  static void clear() {
    bearerToken = null;
    currentUserId = null;
    authState.value++;
  }

  static bool get isAuthenticated => bearerToken != null && bearerToken!.isNotEmpty;
}
