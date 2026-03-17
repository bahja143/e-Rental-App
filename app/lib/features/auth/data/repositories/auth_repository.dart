import 'dart:convert';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/register_request.dart';
import '../../../onboarding/data/google_sign_in_pending.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_session.dart';

class AuthRepository {
  AuthRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<bool> registerWithRequest(RegisterRequest request) async {
    try {
      await _apiClient.postJson('/users', body: request.toJson());

      if (request.password.isEmpty) return true;

      final response = await _apiClient.postJson('/auth/login', body: {
        'email': request.email,
        'password': request.password,
      });
      _storeSessionFromAuthResponse(response);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Register with generated password and auto-login. For phone-auth onboarding flow.
  Future<bool> registerWithGeneratedPassword(RegisterRequest request) async {
    final result = await registerWithGeneratedPasswordEx(request);
    return result.ok;
  }

  /// Same as registerWithGeneratedPassword but returns error message on failure.
  Future<({bool ok, String? errorMessage})> registerWithGeneratedPasswordEx(
    RegisterRequest request, {
    String? profilePictureUrl,
  }) async {
    final password = _generatePassword();
    final fullRequest = RegisterRequest(
      name: request.name,
      email: request.email,
      password: password,
      phone: request.phone,
      profilePictureUrl: profilePictureUrl ?? request.profilePictureUrl,
      preferredPropertyTypes: request.preferredPropertyTypes,
      lookingForOptions: request.lookingForOptions,
      city: request.city,
      lat: request.lat,
      lng: request.lng,
      lookingFor: request.lookingFor,
      lookingForSet: request.lookingForSet,
      categorySet: request.categorySet,
    );
    try {
      await _apiClient.postJson('/users', body: fullRequest.toJson());
      final response = await _apiClient.postJson('/auth/login', body: {
        'email': fullRequest.email,
        'password': fullRequest.password,
      });
      _storeSessionFromAuthResponse(response);
      return (ok: true, errorMessage: null);
    } on ApiException catch (e) {
      if (e.statusCode == 409) {
        try {
          if (e.body != null && e.body!.isNotEmpty) {
            final body = jsonDecode(e.body!) as Map<String, dynamic>?;
            final msg = body?['error']?.toString();
            if (msg != null && msg.isNotEmpty) {
              return (ok: false, errorMessage: msg);
            }
          }
        } catch (_) {}
        return (ok: false, errorMessage: 'This email or mobile is already linked to an account.');
      }
      return (ok: false, errorMessage: 'Could not create account. Please try again.');
    } catch (_) {
      return (ok: false, errorMessage: 'Could not create account. Please try again.');
    }
  }

  static String _generatePassword() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final r = Random.secure();
    return List.generate(12, (_) => chars[r.nextInt(chars.length)]).join();
  }

  void _storeSessionFromAuthResponse(Map<String, dynamic> response) {
    final tokenMap = response['tokens'];
    String token = '';
    if (tokenMap is Map<String, dynamic>) {
      token = '${tokenMap['accessToken'] ?? ''}';
    }
    if (token.isEmpty) return;
    final user = response['user'];
    String? userId;
    if (user is Map<String, dynamic>) {
      final parsed = '${user['id'] ?? ''}';
      userId = parsed.isEmpty ? null : parsed;
    }
    ApiSession.setSession(token: token, userId: userId);
  }

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

  /// Legacy register - use registerWithRequest for full payload
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    String? city,
    String lookingFor = 'just_look_around',
  }) async {
    final request = RegisterRequest(
      name: name,
      email: email,
      password: password,
      phone: phone,
      city: city,
      lookingFor: lookingFor,
    );
    return registerWithRequest(request);
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

  /// Google sign-in for registration: no backend call. Gets profile locally, stores idToken
  /// for submission at the end. Returns (name, email, photoUrl, phone?, errorMessage?).
  Future<({
    String? name,
    String? email,
    String? photoUrl,
    String? phone,
    String? errorMessage,
  })> getGoogleDataForRegistration() async {
    final googleSignIn = GoogleSignIn();
    try {
      final account = await googleSignIn.signIn();
      if (account == null) {
        return (name: null, email: null, photoUrl: null, phone: null, errorMessage: 'Sign in was cancelled.');
      }
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        await googleSignIn.signOut();
        return (name: null, email: null, photoUrl: null, phone: null, errorMessage: 'Could not get Google credentials.');
      }
      final credential = GoogleAuthProvider.credential(
        idToken: idToken,
        accessToken: auth.accessToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      final email = account.email;
      if (email.isEmpty) {
        await googleSignIn.signOut();
        await FirebaseAuth.instance.signOut();
        return (name: null, email: null, photoUrl: null, phone: null, errorMessage: 'Email not provided by Google.');
      }
      final name = account.displayName ?? email.split('@').first;
      final photoUrl = account.photoUrl;
      final firebaseToken = await FirebaseAuth.instance.currentUser?.getIdToken(true);
      await googleSignIn.signOut();
      await FirebaseAuth.instance.signOut();
      if (firebaseToken == null || firebaseToken.isEmpty) {
        return (name: null, email: null, photoUrl: null, phone: null, errorMessage: 'Could not get Firebase token.');
      }
      GoogleSignInPending.set(
        idToken: firebaseToken,
        name: name,
        email: email,
        photoUrl: photoUrl,
      );
      return (name: name, email: email, photoUrl: photoUrl, phone: null, errorMessage: null);
    } catch (_) {
      await googleSignIn.signOut();
      await FirebaseAuth.instance.signOut();
      return (name: null, email: null, photoUrl: null, phone: null, errorMessage: 'Could not sign in with Google. Please try again.');
    }
  }

  /// Complete registration with Google token. Backend verifies token, creates or logs in user.
  Future<({bool ok, String? errorMessage})> registerWithGoogleComplete({
    required String name,
    required String email,
    required String phone,
    required String idToken,
    String? profilePictureUrl,
    List<String>? preferredPropertyTypes,
    List<String>? lookingForOptions,
    double? lat,
    double? lng,
  }) async {
    try {
      final response = await _apiClient.postJson('/auth/register-with-google', body: {
        'idToken': idToken,
        'name': name,
        'email': email,
        'phone': phone,
        if (profilePictureUrl != null && profilePictureUrl.trim().isNotEmpty) 'profile_picture_url': profilePictureUrl.trim(),
        if (preferredPropertyTypes != null && preferredPropertyTypes.isNotEmpty) 'preferred_property_types': preferredPropertyTypes,
        if (lookingForOptions != null && lookingForOptions.isNotEmpty) 'looking_for_options': lookingForOptions,
        if (lat != null && lng != null) 'lat': lat,
        if (lat != null && lng != null) 'lng': lng,
      });
      _storeSessionFromAuthResponse(response);
      return (ok: true, errorMessage: null);
    } on ApiException catch (e) {
      if (e.statusCode == 409) {
        try {
          if (e.body != null && e.body!.isNotEmpty) {
            final body = jsonDecode(e.body!) as Map<String, dynamic>?;
            final msg = body?['error']?.toString();
            if (msg != null && msg.isNotEmpty) {
              return (ok: false, errorMessage: msg);
            }
          }
        } catch (_) {}
        return (ok: false, errorMessage: 'This email or mobile is already linked to an account.');
      }
      return (ok: false, errorMessage: 'Could not create account. Please try again.');
    } catch (_) {
      return (ok: false, errorMessage: 'Could not create account. Please try again.');
    }
  }

  /// Returns (ok, errorMessage). On success ok is true. On failure ok is false and errorMessage explains why.
  Future<({bool ok, String? errorMessage})> socialLoginWithMessage(String provider) async {
    if (provider != 'google') {
      return (ok: false, errorMessage: 'Google Sign-In is not available.');
    }
    final googleSignIn = GoogleSignIn();
    try {
      final account = await googleSignIn.signIn();
      if (account == null) return (ok: false, errorMessage: 'Sign in was cancelled.');

      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        await googleSignIn.signOut();
        return (ok: false, errorMessage: 'Could not get Google credentials.');
      }

      final credential = GoogleAuthProvider.credential(
        idToken: idToken,
        accessToken: auth.accessToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);

      final response = await _apiClient.postJson('/auth/social-login', body: {
        'provider': provider,
        'idToken': idToken,
      });
      _storeSessionFromAuthResponse(response);
      return (ok: true, errorMessage: null);
    } on ApiException catch (e) {
      await googleSignIn.signOut();
      await FirebaseAuth.instance.signOut();
      if (e.statusCode == 503) {
        return (ok: false, errorMessage: 'Google Sign-In is temporarily unavailable. Please try again later.');
      }
      return (ok: false, errorMessage: 'Could not sign in with Google. Please try again.');
    } catch (_) {
      await googleSignIn.signOut();
      await FirebaseAuth.instance.signOut();
      return (ok: false, errorMessage: 'Could not sign in with Google. Please try again.');
    }
  }

  Future<bool> socialLogin(String provider) async {
    final result = await socialLoginWithMessage(provider);
    return result.ok;
  }

  /// Google sign-in for login only. Fails with message if no account exists.
  Future<({bool ok, String? errorMessage})> socialLoginForExistingOnly({
    required String provider,
  }) async {
    if (provider != 'google') {
      return (ok: false, errorMessage: 'Google Sign-In is not available.');
    }
    final googleSignIn = GoogleSignIn();
    try {
      final account = await googleSignIn.signIn();
      if (account == null) {
        return (ok: false, errorMessage: 'Sign in was cancelled.');
      }
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        await googleSignIn.signOut();
        return (ok: false, errorMessage: 'Could not get Google credentials.');
      }
      final credential = GoogleAuthProvider.credential(
        idToken: idToken,
        accessToken: auth.accessToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      final firebaseToken =
          await FirebaseAuth.instance.currentUser?.getIdToken(true);
      if (firebaseToken == null || firebaseToken.isEmpty) {
        await googleSignIn.signOut();
        await FirebaseAuth.instance.signOut();
        return (ok: false, errorMessage: 'Could not get token.');
      }
      final response = await _apiClient.postJson('/auth/social-login', body: {
        'provider': provider,
        'idToken': firebaseToken,
        'createIfNotExists': false,
      });
      await googleSignIn.signOut();
      await FirebaseAuth.instance.signOut();
      _storeSessionFromAuthResponse(response);
      return (ok: true, errorMessage: null);
    } on ApiException catch (e) {
      await googleSignIn.signOut();
      await FirebaseAuth.instance.signOut();
      if (e.statusCode == 404) {
        return (ok: false,
            errorMessage:
                'No account found. Create one with Register or use phone if you signed up that way.');
      }
      if (e.statusCode == 503) {
        return (ok: false,
            errorMessage:
                'Google Sign-In is temporarily unavailable. Please try again later.');
      }
      return (ok: false,
          errorMessage: 'Could not sign in with Google. Please try again.');
    } catch (_) {
      return (ok: false,
          errorMessage: 'Could not sign in with Google. Please try again.');
    }
  }

  /// Login with Firebase phone idToken. Backend finds user by phone.
  Future<({bool ok, String? errorMessage})> loginWithPhone(String idToken) async {
    try {
      final response =
          await _apiClient.postJson('/auth/login-with-phone', body: {
        'idToken': idToken,
      });
      _storeSessionFromAuthResponse(response);
      return (ok: true, errorMessage: null);
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        return (ok: false,
            errorMessage: 'No account found. Please register first.');
      }
      return (ok: false,
          errorMessage: e.body ?? 'Could not sign in. Please try again.');
    } catch (_) {
      return (ok: false, errorMessage: 'Could not sign in. Please try again.');
    }
  }

  /// Check if email or phone already exists. Returns (emailExists, phoneExists).
  Future<({bool emailExists, bool phoneExists})> checkEmailPhoneAvailability({
    required String email,
    required String phone,
  }) async {
    try {
      final res = await _apiClient.postJson('/auth/check-availability', body: {
        'email': email.trim().toLowerCase(),
        'phone': phone.trim().replaceAll(RegExp(r'\s'), ''),
      });
      return (
        emailExists: res['emailExists'] == true,
        phoneExists: res['phoneExists'] == true,
      );
    } catch (_) {
      return (emailExists: false, phoneExists: false);
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

}
