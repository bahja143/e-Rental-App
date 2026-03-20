# Google Maps Setup

The search screen uses Google Maps with custom location pins (Figma 21-3695 design).

## 1. Get an API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create or select a project
3. Enable these APIs:
   - **Maps SDK for Android**
   - **Maps SDK for iOS**
4. Go to **Credentials** → **Create credentials** → **API key**
5. Copy your API key

## 2. Paste Your Key

### Android

Edit **`android/app/google-maps-api-key.txt`** and replace `PASTE_YOUR_GOOGLE_MAPS_API_KEY_HERE` with your key.

### iOS

Edit **`ios/Flutter/GoogleMapsKey.xcconfig`** and replace `PASTE_YOUR_GOOGLE_MAPS_API_KEY_HERE` with your key.

> If `GoogleMapsKey.xcconfig` doesn't exist, copy from `GoogleMapsKey.xcconfig.example`.

## 3. Run the App

```bash
cd app
flutter pub get
flutter run
```

The map will show property pins at their coordinates. Pins use the Figma 21-3695 design (teardrop shape, dark teal #234F68).

## Explore / Empty (Figma 21-3735)

To preview the **no listings** layout (no pins, centered “Nearby You” + error pill):

```bash
flutter run --dart-define=SEARCH_SIMULATE_NO_LISTINGS=true
```

When the API returns no nearby estates, the same UI is shown without this flag.
