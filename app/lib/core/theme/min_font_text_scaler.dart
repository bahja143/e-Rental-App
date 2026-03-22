import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'app_theme.dart';

/// Ensures scaled text never renders below [minLogicalPixels] (logical px).
///
/// Wired in [MaterialApp] / root [MediaQuery] so [Text], [TextField], labels, etc.
/// use [TextScaler.scale] and respect this floor system-wide.
@immutable
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MinLogicalFontSizeScaler &&
        other._parent == _parent &&
        other.minLogicalPixels == minLogicalPixels;
  }

  @override
  int get hashCode => Object.hash(_parent, minLogicalPixels);

  @override
  String toString() =>
      'MinLogicalFontSizeScaler(min: ${minLogicalPixels}px, parent: $_parent)';
}
