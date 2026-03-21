import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../network/api_config.dart';

/// Resolves the Google Maps key for **REST** calls (Geocoding) from:
/// 1. `--dart-define=GOOGLE_MAPS_API_KEY=...` ([ApiConfig.googleMapsApiKey])
/// 2. Native config (Android manifest / iOS Info.plist) — same key as the Maps SDK
///
/// Without (2), Geocoding fails even when the map works, because Dart `fromEnvironment`
/// is empty unless you pass dart-define at build time.
class MapsApiKeyProvider {
  MapsApiKeyProvider._();

  static const _channel = MethodChannel('com.example.hanti_riyo/maps');

  static String? _cached;

  /// Clears cache (e.g. after hot restart testing).
  static void clearCache() => _cached = null;

  static Future<String> resolve() async {
    final existing = _cached?.trim();
    if (existing != null && existing.isNotEmpty) return existing;

    final fromDefine = ApiConfig.googleMapsApiKey.trim();
    if (fromDefine.isNotEmpty) {
      _cached = fromDefine;
      return fromDefine;
    }

    if (kIsWeb) return '';

    try {
      final native = await _channel.invokeMethod<String>('getGoogleMapsApiKey');
      final k = native?.trim() ?? '';
      if (k.isNotEmpty) _cached = k;
      return k;
    } on MissingPluginException {
      return '';
    } catch (_) {
      return '';
    }
  }
}
