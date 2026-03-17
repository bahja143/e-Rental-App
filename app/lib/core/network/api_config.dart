class ApiConfig {
  ApiConfig._();

  /// API base URL. For local dev with a physical device, use your PC's LAN IP
  /// (e.g. http://192.168.100.10:3000). For emulator use http://10.0.2.2:3000.
  /// Override at build: flutter run --dart-define=API_BASE_URL=http://YOUR_IP:PORT
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.30.218.115:3000/api',
  );

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration readTimeout = Duration(seconds: 20);
}
