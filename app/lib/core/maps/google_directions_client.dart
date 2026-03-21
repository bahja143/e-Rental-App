import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../network/api_config.dart';
import 'maps_api_key_provider.dart';

/// Driving route summary from [Directions API](https://developers.google.com/maps/documentation/directions/overview).
/// Enable **Directions API** for the same key as Maps.
class DirectionsLegSummary {
  const DirectionsLegSummary({
    required this.distanceText,
    required this.durationText,
    required this.durationSeconds,
  });

  final String distanceText;
  /// Human-readable, e.g. "15 mins"
  final String durationText;
  final int durationSeconds;
}

class GoogleDirectionsClient {
  GoogleDirectionsClient._();

  /// Driving directions from [origin] to [destination]. Returns null if unavailable.
  static Future<DirectionsLegSummary?> drivingLeg(
    LatLng origin,
    LatLng destination,
  ) async {
    final key = (await MapsApiKeyProvider.resolve()).trim();
    if (key.isEmpty) return null;

    final uri = Uri.https('maps.googleapis.com', '/maps/api/directions/json', {
      'origin': '${origin.latitude},${origin.longitude}',
      'destination': '${destination.latitude},${destination.longitude}',
      'mode': 'driving',
      'key': key,
    });

    try {
      final res = await http.get(uri).timeout(ApiConfig.connectTimeout);
      if (res.statusCode != 200) return null;
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      if (json['status'] != 'OK') return null;
      final routes = json['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) return null;
      final first = routes.first as Map<String, dynamic>;
      final legs = first['legs'] as List<dynamic>?;
      if (legs == null || legs.isEmpty) return null;
      final leg = legs.first as Map<String, dynamic>;

      final dist = leg['distance'] as Map<String, dynamic>?;
      final dur = leg['duration'] as Map<String, dynamic>?;
      final durTraffic = leg['duration_in_traffic'] as Map<String, dynamic>?;

      final distanceText = '${dist?['text'] ?? ''}'.trim();
      final trafficMap = durTraffic ?? dur;
      final durationText = '${trafficMap?['text'] ?? ''}'.trim();
      final durationSeconds = (trafficMap?['value'] as num?)?.round() ?? 0;

      if (distanceText.isEmpty || durationText.isEmpty) return null;

      return DirectionsLegSummary(
        distanceText: distanceText,
        durationText: durationText,
        durationSeconds: durationSeconds,
      );
    } catch (_) {
      return null;
    }
  }
}
