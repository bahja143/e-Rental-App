/// Holds Google sign-in data (idToken, profile) during registration flow.
/// Set when user taps Google on register; used when finishing at preferable.
/// Cleared after successful registration.
class GoogleSignInPending {
  GoogleSignInPending._();

  static String? _idToken;
  static String? _name;
  static String? _email;
  static String? _photoUrl;
  static String? _phone;

  static String? get idToken => _idToken;
  static String? get name => _name;
  static String? get email => _email;
  static String? get photoUrl => _photoUrl;
  static String? get phone => _phone;
  static bool get hasData => _idToken != null && _idToken!.isNotEmpty;

  static void set({
    required String idToken,
    required String name,
    required String email,
    String? photoUrl,
    String? phone,
  }) {
    _idToken = idToken;
    _name = name;
    _email = email;
    _photoUrl = photoUrl;
    _phone = phone;
  }

  static void clear() {
    _idToken = null;
    _name = null;
    _email = null;
    _photoUrl = null;
    _phone = null;
  }
}
