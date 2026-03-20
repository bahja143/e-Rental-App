import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Creates a custom map pin BitmapDescriptor matching Figma **21-3729** (Pin / Real Estate),
/// also used on listing detail map (**28:4593**).
/// Teardrop shape, dark blue #234F68, circular image area, yellow base glow.
Future<BitmapDescriptor> createMapPinDescriptor({String? imageUrl}) async {
  const double width = 86; // slightly smaller pin
  const double height = 129;
  const Color pinColor = Color(0xFF234F68); // primaryBackground
  const Color glowColor = Color(0xFFE7B904); // primary gold
  const Color borderColor = Color(0xFFFFFFFF);

  Uint8List? imageBytes;
  if (imageUrl != null && imageUrl.isNotEmpty) {
    try {
      final uri = Uri.parse(imageUrl);
      final bundle = NetworkAssetBundle(uri);
      final data = await bundle.load(uri.toString());
      imageBytes = data.buffer.asUint8List();
    } catch (_) {}
  }

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final size = Size(width, height);

  // Teardrop path: circular head (top ~60%) tapering to point (bottom)
  // Figma: inset-[0_0_15.66%_0] for main body, point at bottom
  final path = Path()
    ..moveTo(size.width / 2, 0)
    ..quadraticBezierTo(size.width, 0, size.width, size.height * 0.32)
    ..quadraticBezierTo(size.width, size.height * 0.55, size.width / 2, size.height * 0.88)
    ..quadraticBezierTo(0, size.height * 0.55, 0, size.height * 0.32)
    ..quadraticBezierTo(0, 0, size.width / 2, 0)
    ..close();

  // Yellow base glow at tip (Figma 21-3729: soft circular highlight)
  final glowCenter = Offset(size.width / 2, size.height - 6);
  canvas.drawCircle(
    glowCenter,
    14,
    Paint()
      ..color = glowColor.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
  );
  canvas.drawCircle(
    glowCenter,
    9,
    Paint()
      ..color = glowColor.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
  );

  // Shadow
  canvas.save();
  canvas.translate(2, 2);
  canvas.drawPath(
    path,
    Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill,
  );
  canvas.restore();

  // Pin body
  canvas.drawPath(
    path,
    Paint()
      ..color = pinColor
      ..style = PaintingStyle.fill,
  );

  // White border
  canvas.drawPath(
    path,
    Paint()
      ..color = borderColor.withValues(alpha: 0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5,
  );

  // Circular image area in pin head
  final circleCenter = Offset(size.width / 2, size.height * 0.22);
  final circleRadius = 40.0;

  if (imageBytes != null) {
    try {
      final codec = await ui.instantiateImageCodec(
        imageBytes,
        targetWidth: (circleRadius * 4).toInt(),
        targetHeight: (circleRadius * 4).toInt(),
      );
      final frame = await codec.getNextFrame();
      final decodedImage = frame.image;

      final imageSize = Size(
        decodedImage.width.toDouble(),
        decodedImage.height.toDouble(),
      );
      final circleRect = Rect.fromCircle(center: circleCenter, radius: circleRadius);
      final fitted = applyBoxFit(BoxFit.cover, imageSize, circleRect.size);
      final srcRect = Alignment.center.inscribe(
        fitted.source,
        Offset.zero & imageSize,
      );
      final dstRect = circleRect;

      canvas.saveLayer(circleRect, Paint());
      canvas.clipPath(Path()..addOval(Rect.fromCircle(center: circleCenter, radius: circleRadius)));
      canvas.drawImageRect(
        decodedImage,
        srcRect,
        dstRect,
        Paint()..filterQuality = FilterQuality.high,
      );
      canvas.restore();
    } catch (_) {
      _drawPlaceholder(canvas, circleCenter, circleRadius);
    }
  } else {
    _drawPlaceholder(canvas, circleCenter, circleRadius);
  }

  // Inner border around image circle
  canvas.drawCircle(
    circleCenter,
    circleRadius,
    Paint()
      ..color = borderColor.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2,
  );

  final picture = recorder.endRecording();
  final rasterImage = await picture.toImage(width.toInt(), height.toInt());
  final byteData = await rasterImage.toByteData(format: ui.ImageByteFormat.png);
  final bytes = byteData!.buffer.asUint8List();

  return BitmapDescriptor.fromBytes(bytes);
}

void _drawPlaceholder(Canvas canvas, Offset center, double radius) {
  canvas.drawCircle(
    center,
    radius,
    Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill,
  );
  canvas.drawCircle(
    center,
    radius - 2,
    Paint()
      ..color = const Color(0xFF234F68).withValues(alpha: 0.15)
      ..style = PaintingStyle.fill,
  );
}
