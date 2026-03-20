import 'package:flutter/painting.dart';

/// Ensures scaled text never renders below [minLogicalPixels] (Figma / design minimum 10px).
class MinLogicalFontSizeScaler extends TextScaler {
  MinLogicalFontSizeScaler(this._parent, {this.minLogicalPixels = 10});

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
