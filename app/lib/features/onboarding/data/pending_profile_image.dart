import 'dart:io';

/// Holds the profile image file path during registration flow.
/// Set when user picks image on register screen; used when creating account on preferable.
/// Cleared after successful registration or on app restart.
class PendingProfileImage {
  PendingProfileImage._();

  static String? _path;

  static String? get path => _path;

  static void set(File file) {
    _path = file.path;
  }

  static void clear() {
    _path = null;
  }
}
