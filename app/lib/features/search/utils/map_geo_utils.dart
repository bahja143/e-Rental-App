import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Great-circle distance in meters ([Haversine]).
double haversineMeters(LatLng a, LatLng b) {
  const earthRadiusM = 6371000.0;
  final dLat = _degToRad(b.latitude - a.latitude);
  final dLng = _degToRad(b.longitude - a.longitude);
  final lat1 = _degToRad(a.latitude);
  final lat2 = _degToRad(b.latitude);
  final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1) * math.cos(lat2) * math.sin(dLng / 2) * math.sin(dLng / 2);
  final c = 2 * math.asin(math.sqrt(math.min(1.0, h)));
  return earthRadiusM * c;
}

/// Initial bearing from [from] to [to] in degrees, 0 = North, clockwise.
double bearingDegrees(LatLng from, LatLng to) {
  final lat1 = _degToRad(from.latitude);
  final lat2 = _degToRad(to.latitude);
  final dLng = _degToRad(to.longitude - from.longitude);
  final y = math.sin(dLng) * math.cos(lat2);
  final x = math.cos(lat1) * math.sin(lat2) - math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
  final brng = math.atan2(y, x);
  return (_radToDeg(brng) + 360) % 360;
}

/// 8-point compass label (bearing is direction **toward** [to] from [from]).
String compassDirection8(LatLng from, LatLng to) {
  final deg = bearingDegrees(from, to);
  const names = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
  final idx = ((deg + 22.5) / 45).floor() % 8;
  return names[idx];
}

/// Cardinal toward [to] from [from] — short labels for compact UI.
String compassDirection4(LatLng from, LatLng to) {
  final deg = bearingDegrees(from, to);
  if (deg >= 315 || deg < 45) return 'North';
  if (deg < 135) return 'East';
  if (deg < 225) return 'South';
  return 'West';
}

/// Compact duration: `12 min`, `1.5 hr`, `2 hr` (under 1 hour always minutes).
String formatDurationCompact(int totalSeconds) {
  if (totalSeconds <= 0) return '—';
  if (totalSeconds < 3600) {
    final minutes = math.max(1, (totalSeconds / 60).ceil());
    return '$minutes min';
  }
  final hours = totalSeconds / 3600.0;
  final rounded = hours.round();
  if ((hours - rounded).abs() < 0.06) return '$rounded hr';
  return '${hours.toStringAsFixed(1)} hr';
}

double _degToRad(double d) => d * math.pi / 180;
double _radToDeg(double r) => r * 180 / math.pi;

String formatDistanceKm(double meters) {
  final km = meters / 1000.0;
  if (km < 0.1) {
    return '${meters.round()} m';
  }
  final s = km.toStringAsFixed(1);
  final t = s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  return '$t km';
}
