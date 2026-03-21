import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/theme/app_colors.dart';

/// Creates a custom map pin BitmapDescriptor matching Figma **21-3729** (Pin / Real Estate),
/// also used on listing detail map (**28:4593**).
/// Teardrop shape, dark blue #234F68, circular image area, yellow base glow.
///
/// When [imageUrl] is missing or fails to load:
/// - [useProfileStyleFallback]: same **grey circle + initial or person** as the home header
///   ([`profileAvatarLetterFromName`] + [`RemoteImage`] placeholder).
/// - otherwise [avatarLetter] uses the legacy teardrop silhouette (property pins omit both).
Future<BitmapDescriptor> createMapPinDescriptor({
  String? imageUrl,
  String? avatarLetter,
  bool useProfileStyleFallback = false,
}) async {
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

  final initial = _normalizedAvatarLetter(avatarLetter);

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
      if (useProfileStyleFallback) {
        _drawProfileFallbackLikeHome(canvas, circleCenter, circleRadius, initial);
      } else if (initial != null) {
        _drawLetterAvatar(canvas, circleCenter, circleRadius, initial);
      } else {
        _drawPlaceholder(canvas, circleCenter, circleRadius);
      }
    }
  } else if (useProfileStyleFallback) {
    _drawProfileFallbackLikeHome(canvas, circleCenter, circleRadius, initial);
  } else if (initial != null) {
    _drawLetterAvatar(canvas, circleCenter, circleRadius, initial);
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

/// Matches home header profile chip: [`AppColors.greySoft2`] disc,
/// initial in [`AppColors.textPrimary`], else person glyph in [`AppColors.greyBarelyMedium`].
void _drawProfileFallbackLikeHome(
  Canvas canvas,
  Offset center,
  double radius,
  String? normalizedLetter,
) {
  canvas.drawCircle(
    center,
    radius,
    Paint()
      ..color = AppColors.greySoft2
      ..style = PaintingStyle.fill,
  );
  if (normalizedLetter != null && normalizedLetter.isNotEmpty) {
    try {
      final fontSize = radius * 0.9;
      final builder = ui.ParagraphBuilder(
        ui.ParagraphStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          textAlign: TextAlign.center,
          maxLines: 1,
          height: 1.0,
        ),
      )
        ..pushStyle(ui.TextStyle(color: AppColors.textPrimary))
        ..addText(normalizedLetter);
      final p = builder.build();
      p.layout(ui.ParagraphConstraints(width: radius * 2));
      canvas.drawParagraph(
        p,
        Offset(center.dx - radius, center.dy - p.height / 2),
      );
    } catch (_) {}
  } else {
    _drawPersonGlyphMuted(canvas, center, radius);
  }
}

void _drawPersonGlyphMuted(Canvas canvas, Offset center, double radius) {
  final ink = Paint()
    ..color = AppColors.greyBarelyMedium
    ..style = PaintingStyle.fill;
  final headR = radius * 0.26;
  canvas.drawCircle(Offset(center.dx, center.dy - radius * 0.2), headR, ink);
  final body = RRect.fromRectAndRadius(
    Rect.fromCenter(
      center: Offset(center.dx, center.dy + radius * 0.36),
      width: radius * 1.45,
      height: radius * 0.62,
    ),
    Radius.circular(radius * 0.31),
  );
  canvas.drawRRect(body, ink);
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

/// Single character for map avatar, or null to use generic placeholder (property pins).
String? _normalizedAvatarLetter(String? raw) {
  if (raw == null) return null;
  final t = raw.trim();
  if (t.isEmpty) return null;
  final i = t.runes.iterator;
  if (!i.moveNext()) return null;
  return String.fromCharCode(i.current).toUpperCase();
}

/// User avatar when there is no photo: **vector silhouette** (TextPainter often paints
/// nothing in an off-screen [PictureRecorder] on some devices).
void _drawLetterAvatar(Canvas canvas, Offset center, double radius, String letter) {
  _drawSilhouetteUserAvatar(canvas, center, radius);
  if (letter.isEmpty) return;
  // Initial on chest (dart:ui paragraph — more reliable than TextPainter here).
  try {
    final fontSize = radius * 0.88;
    final builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        textAlign: TextAlign.center,
        maxLines: 1,
        height: 1.0,
      ),
    )
      ..pushStyle(ui.TextStyle(color: const Color(0xFF234F68)))
      ..addText(letter);
    final p = builder.build();
    p.layout(ui.ParagraphConstraints(width: radius * 2));
    canvas.drawParagraph(
      p,
      Offset(center.dx - radius, center.dy - p.height / 2),
    );
  } catch (_) {}
}

void _drawSilhouetteUserAvatar(Canvas canvas, Offset center, double radius) {
  const teal = Color(0xFF234F68);
  canvas.drawCircle(
    center,
    radius,
    Paint()
      ..color = teal.withValues(alpha: 0.22)
      ..style = PaintingStyle.fill,
  );
  final silhouette = Paint()..color = Colors.white.withValues(alpha: 0.92);
  final headR = radius * 0.26;
  canvas.drawCircle(Offset(center.dx, center.dy - radius * 0.2), headR, silhouette);
  final body = RRect.fromRectAndRadius(
    Rect.fromCenter(
      center: Offset(center.dx, center.dy + radius * 0.36),
      width: radius * 1.45,
      height: radius * 0.62,
    ),
    Radius.circular(radius * 0.31),
  );
  canvas.drawRRect(body, silhouette);
}
