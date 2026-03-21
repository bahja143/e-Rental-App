# Google Maps Setup

The search screen uses Google Maps with custom location pins (Figma 21-3695 design).

## 1. Get an API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create or select a project
3. Enable these APIs:
   - **Maps SDK for Android**
   - **Maps SDK for iOS**
   - **Geocoding API** (for address search & reverse geocode on **Listing → View on map** when choosing a location)
   - **Directions API** (for **drive time & road distance** on the bottom “Location detail” card on **View on map**)

The app reads that **same key** from native config for Geocoding HTTP calls (no need for `--dart-define` unless you want to override): Android uses `google-maps-api-key.txt` / `local.properties` → manifest; iOS uses `GoogleMapsKey.xcconfig` → `Info.plist`.
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
