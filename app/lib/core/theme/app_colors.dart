import 'package:flutter/material.dart';

/// Hanti riyo design system colors - extracted from Figma
class AppColors {
  AppColors._();

  // Primary - Gold (from Figma --gold)
  static const Color primary = Color(0xFFE7B904);
  static const Color primaryDark = Color(0xFFD4A803);

  // Background
  static const Color background = Color(0xFFFCFCFC);
  static const Color surface = Color(0xFFFFFFFF);

  // Text - Dark blue/teal palette
  static const Color textPrimary = Color(0xFF252B5C);
  static const Color textSecondary = Color(0xFF1F4C6B);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textAccent = Color(0xFF13285E);

  // Grey palette
  static const Color greyMedium = Color(0xFF53587A);
  static const Color greyBarelyMedium = Color(0xFFA1A5C1);
  static const Color greySoft1 = Color(0xFFF5F4F8);
  static const Color greySoft2 = Color(0xFFECEDF3);

  // Form
  static const Color inputBackground = Color(0xFFF5F4F8);
  static const Color inputPlaceholder = Color(0xFFA1A5C1);

  // Overlay
  static const Color overlayDark = Color(0xDE000000);
}
