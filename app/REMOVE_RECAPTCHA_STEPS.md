# Remove "I'm Not a Robot" When Sending OTP

reCAPTCHA appears when Firebase can't use **Play Integrity** (Android) or **App Attest** (iOS). Fix it by configuring App Check.

---

## Step 1: Get SHA-256 (Android)

```bash
cd app
./gradlew signingReport
```

In the output, copy the **SHA-256** under `Variant: debug` (and `release` for production).

---

## Step 2: Add SHA to Firebase

1. Open [Firebase Console](https://console.firebase.google.com) → your project
2. **Project settings** (gear) → **Your apps**
3. Select your **Android app**
4. Click **Add fingerprint** → paste SHA-256 → Save

---

## Step 3: Enable Play Integrity API

1. Open [Google Cloud Console](https://console.cloud.google.com)
2. Select the **same project** as Firebase
3. **APIs & Services** → **Enable APIs and Services**
4. Search **Play Integrity API** → Enable

---

## Step 4: Configure App Check

1. Firebase Console → **App Check**
2. Click **Apps** tab
3. For **Android**: Register with **Play Integrity**
4. For **iOS**: Register with **App Attest**
5. Add **debug providers** for local testing (Firebase provides a debug token)

---

## Step 5: Verify

- Run on a **real device** (emulators often skip Play Integrity)
- Use a **release build** or a debug build with the correct SHA

If Play Integrity is working, phone auth will run without opening reCAPTCHA in the browser.

---

## Debug-Only: Disable reCAPTCHA (Testing)

**⚠️ Dev only – remove before release.**

In `MainActivity.kt`, add:

```kotlin
import android.os.Bundle
import com.google.firebase.auth.FirebaseAuth

override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    if (BuildConfig.DEBUG) {
        FirebaseAuth.getInstance().firebaseAuthSettings.setAppVerificationDisabledForTesting(true)
    }
}
```
