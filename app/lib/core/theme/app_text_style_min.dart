import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Use for [TextStyle]s that bypass [TextScaler] (rare) or to keep source sizes ≥ [AppTheme.minFontSize].
extension AppTextStyleMinLogicalFontSize on TextStyle {
  /// If [fontSize] is set and below [min], bumps it to [min] (logical px).
  TextStyle clampMinLogicalFontSize([double min = AppTheme.minFontSize]) {
    final f = fontSize;
    if (f == null || f >= min) return this;
    return copyWith(fontSize: min);
  }
}
