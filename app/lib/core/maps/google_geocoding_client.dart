import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../network/api_config.dart';
import 'maps_api_key_provider.dart';

/// Google Geocoding API (enable **Geocoding API** for the same key as Maps).
class GoogleGeocodingClient {
  GoogleGeocodingClient._();

  static Future<GeocodePlace?> geocodeAddress(String address) async {
    final key = (await MapsApiKeyProvider.resolve()).trim();
    final q = address.trim();
    if (key.isEmpty || q.isEmpty) return null;

    final uri = Uri.https('maps.googleapis.com', '/maps/api/geocode/json', {
      'address': q,
      'key': key,
    });
    try {
      final res = await http.get(uri).timeout(ApiConfig.connectTimeout);
      if (res.statusCode != 200) return null;
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      if (json['status'] != 'OK') return null;
      final results = json['results'] as List<dynamic>?;
      if (results == null || results.isEmpty) return null;
      final first = results.first as Map<String, dynamic>;
      final formatted = '${first['formatted_address'] ?? ''}'.trim();
      final geom = first['geometry'] as Map<String, dynamic>?;
      final loc = geom?['location'] as Map<String, dynamic>?;
      if (loc == null) return null;
      final lat = (loc['lat'] as num).toDouble();
      final lng = (loc['lng'] as num).toDouble();
      return GeocodePlace(location: LatLng(lat, lng), formattedAddress: formatted);
    } catch (_) {
      return null;
    }
  }

  static Future<String?> reverseGeocode(LatLng position) async {
    final key = (await MapsApiKeyProvider.resolve()).trim();
    if (key.isEmpty) return null;

    final uri = Uri.https('maps.googleapis.com', '/maps/api/geocode/json', {
      'latlng': '${position.latitude},${position.longitude}',
      'key': key,
    });
    try {
      final res = await http.get(uri).timeout(ApiConfig.connectTimeout);
      if (res.statusCode != 200) return null;
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      if (json['status'] != 'OK') return null;
      final results = json['results'] as List<dynamic>?;
      if (results == null || results.isEmpty) return null;
      final first = results.first as Map<String, dynamic>;
      return '${first['formatted_address'] ?? ''}'.trim();
    } catch (_) {
      return null;
    }
  }
}

class GeocodePlace {
  const GeocodePlace({required this.location, required this.formattedAddress});

  final LatLng location;
  final String formattedAddress;
}
