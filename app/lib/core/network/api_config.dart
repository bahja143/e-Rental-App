class ApiConfig {
  ApiConfig._();

  /// API base URL. For local dev with a physical device, use your PC's LAN IP
  /// (e.g. http://192.168.100.10:3000). For emulator use http://10.0.2.2:3000.
  /// Override at build: flutter run --dart-define=API_BASE_URL=http://YOUR_IP:PORT
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:3000/api',
  );

  /// Optional override for Google Maps / Geocoding REST calls.
  /// If empty, [MapsApiKeyProvider] reads the same key as the native Maps SDK
  /// (Android manifest / iOS Info.plist). You can still set:
  /// `flutter run --dart-define=GOOGLE_MAPS_API_KEY=YOUR_KEY`
  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration readTimeout = Duration(seconds: 20);
}
