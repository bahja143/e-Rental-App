import 'package:flutter/painting.dart';

import 'app_theme.dart';

/// Ensures scaled text never renders below [minLogicalPixels] (logical px).
/// Use [AppTheme.minFontSize] from [MaterialApp] builder so all [Text] respects the floor.
class MinLogicalFontSizeScaler extends TextScaler {
  MinLogicalFontSizeScaler(
    this._parent, {
    double? minLogicalPixels,
  }) : minLogicalPixels = minLogicalPixels ?? AppTheme.minFontSize;

  final TextScaler _parent;
  final double minLogicalPixels;

  @override
  double get textScaleFactor => _parent.textScaleFactor;

  @override
  double scale(double fontSize) {
    final scaled = _parent.scale(fontSize);
    return scaled < minLogicalPixels ? minLogicalPixels : scaled;
  }

  @override
  TextScaler clamp({
    double minScaleFactor = 0,
    double maxScaleFactor = double.infinity,
  }) {
    return MinLogicalFontSizeScaler(
      _parent.clamp(
        minScaleFactor: minScaleFactor,
        maxScaleFactor: maxScaleFactor,
      ),
      minLogicalPixels: minLogicalPixels,
    );
  }
}
