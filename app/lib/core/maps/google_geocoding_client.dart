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
      final types = (first['types'] as List<dynamic>? ?? const <dynamic>[])
          .map((type) => '$type'.trim())
          .where((type) => type.isNotEmpty)
          .toList();
      final geom = first['geometry'] as Map<String, dynamic>?;
      final loc = geom?['location'] as Map<String, dynamic>?;
      if (loc == null) return null;
      final lat = (loc['lat'] as num).toDouble();
      final lng = (loc['lng'] as num).toDouble();
      return GeocodePlace(
        location: LatLng(lat, lng),
        formattedAddress: formatted,
        types: types,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<List<PlaceAutocompleteSuggestion>> autocompletePlaces(
    String input,
  ) async {
    final key = (await MapsApiKeyProvider.resolve()).trim();
    final q = input.trim();
    if (key.isEmpty || q.isEmpty) return const <PlaceAutocompleteSuggestion>[];

    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/autocomplete/json',
      {
        'input': q,
        'types': 'geocode',
        'key': key,
      },
    );
    try {
      final res = await http.get(uri).timeout(ApiConfig.connectTimeout);
      if (res.statusCode != 200) {
        return const <PlaceAutocompleteSuggestion>[];
      }
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final predictions = json['predictions'] as List<dynamic>?;
      if (predictions == null || predictions.isEmpty) {
        return const <PlaceAutocompleteSuggestion>[];
      }
      return predictions
          .whereType<Map<String, dynamic>>()
          .map(
            (item) => PlaceAutocompleteSuggestion(
              description: '${item['description'] ?? ''}'.trim(),
              placeId: '${item['place_id'] ?? ''}'.trim(),
            ),
          )
          .where((item) => item.description.isNotEmpty)
          .toList();
    } catch (_) {
      return const <PlaceAutocompleteSuggestion>[];
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
  const GeocodePlace({
    required this.location,
    required this.formattedAddress,
    this.types = const <String>[],
  });

  final LatLng location;
  final String formattedAddress;
  final List<String> types;

  bool get isPreciseLocation {
    const preciseTypes = <String>{
      'street_address',
      'premise',
      'subpremise',
      'establishment',
      'point_of_interest',
      'route',
      'intersection',
      'airport',
      'bus_station',
      'train_station',
      'transit_station',
      'plus_code',
    };
    return types.any(preciseTypes.contains);
  }
}

class PlaceAutocompleteSuggestion {
  const PlaceAutocompleteSuggestion({
    required this.description,
    required this.placeId,
  });

  final String description;
  final String placeId;
}
