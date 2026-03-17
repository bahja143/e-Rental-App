# Showing reCAPTCHA In-App (Instead of Browser)

When Firebase Phone Auth needs to verify you're human, it can show reCAPTCHA. By default this opens a **Chrome Custom Tab** (feels like leaving the app). Here’s how to keep it in-app or avoid it.

---

## Option 1: Avoid reCAPTCHA (Recommended)

If **Play Integrity** (Android) and **App Attest** (iOS) work correctly, Firebase does **silent verification** and **never shows reCAPTCHA**.

### Setup

1. **Firebase Console** → Project → App Check  
   - Add your Android app (package name + SHA-256)  
   - Add your iOS app (bundle ID)  
   - Use **Play Integrity** for Android, **App Attest** for iOS  

2. **Android SHA-256**  
   Run in a terminal:
   ```bash
   cd app && ./gradlew signingReport
   ```
   Add the debug and release SHA-256 fingerprints in Firebase → Project Settings → Your Android app.

3. **Google Cloud Console** → Enable **Play Integrity API** for your project.

4. Your `main.dart` already uses:
   - Android: `AndroidProvider.playIntegrity` (release) / `AndroidProvider.debug` (debug)
   - iOS: `AppleProvider.appAttest` (release) / `AppleProvider.debug` (debug)

When this is configured, phone auth typically skips reCAPTCHA and uses device checks instead.

---

## Option 2: In-App WebView reCAPTCHA

The standard Flutter Firebase Auth plugin **does not** support showing reCAPTCHA inside your app. The Android SDK always uses Chrome Custom Tab.

These are the practical workarounds:

### A) Use `flutter_firebase_recaptcha`

Targeted at **Flutter Web**, not native mobile. It renders reCAPTCHA in a WebView. On native Android/iOS it may still fall back to the system browser.

```yaml
dependencies:
  flutter_firebase_recaptcha: ^1.0.2
```

Requires Firebase **web** config, and is mainly intended for web builds.

### B) Use reCAPTCHA Enterprise

**reCAPTCHA Enterprise** has better mobile support and can run more natively:

1. Enable [reCAPTCHA Enterprise](https://cloud.google.com/recaptcha-enterprise/docs) in Google Cloud.
2. Add `recaptcha_enterprise_flutter`:
   ```yaml
   dependencies:
     recaptcha_enterprise_flutter: ^0.0.1  # check pub.dev for latest
   ```
3. Integrate it in your auth flow and send the token to your backend for verification. This would mean moving some verification logic off Firebase Auth and onto your backend.

---

## Option 3: Test Without reCAPTCHA (Development Only)

For local testing on emulators or unsupported devices:

**Android** – in your app’s native code, you can temporarily disable app verification (do **not** use in production):

```kotlin
// android/app/src/main/kotlin/.../MainActivity.kt (or similar)
FirebaseAuth.getInstance().firebaseAuthSettings.setAppVerificationDisabledForTesting(true)
```

This is only for development and is not allowed in production.

---

## Summary

| Goal | Approach |
|------|----------|
| Avoid reCAPTCHA completely | Configure Play Integrity + App Attest in Firebase App Check |
| Show reCAPTCHA in-app (web) | `flutter_firebase_recaptcha` (Flutter Web) |
| Better in-app UX on mobile | reCAPTCHA Enterprise + custom backend integration |
| Dev/testing only | `setAppVerificationDisabledForTesting(true)` |

Recommended path: finish **Option 1** so phone auth uses Play Integrity / App Attest and reCAPTCHA is rarely (or never) needed. Check Firebase Console → App Check to confirm your apps are registered and passing attestation.
