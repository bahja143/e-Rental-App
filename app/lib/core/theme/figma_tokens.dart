import 'package:flutter/material.dart';

/// Design values traced from Figma MCP `get_design_context` for **Hanti riyo (Copy)**.
/// File key: `1pH0qfybRFvvBbWUCcN5Lm`.
///
/// Re-fetch after design changes: select the frame in Figma Desktop, then use Cursor
/// Figma MCP `get_design_context` — see `FIGMA_MCP.md`.
abstract final class FigmaHantiRiyoTokens {
  // --- Explore / Search screen (frame `21:3653`) ---

  /// Node `21:3681` — `backdrop-blur-[4px] bg-[rgba(35,79,104,0.67)]`
  static const double exploreSearchFaderBlurSigma = 4;
  static const Color exploreSearchFaderTint = Color(0xAB234F68);

  /// Nodes `21:3684`, `21:3685` — `backdrop-blur-[9px] bg-[rgba(255,255,255,0.8)]`
  static const double exploreSearchGlassBlurSigma = 9;
  static final Color exploreSearchGlassFill = Colors.white.withValues(alpha: 0.8);

  /// Modal cards — `rounded-[25px]`
  static const double exploreSearchRadiusLg = 25;

  /// `shadow-[0px_17px_80px_0px_rgba(231,185,4,0.3)]` on search + recent (gold / primary)
  static const BoxShadow exploreSearchModalGoldShadow = BoxShadow(
    color: Color(0x4DE7B904),
    blurRadius: 40,
    offset: Offset(0, 17),
    spreadRadius: -12,
  );

  /// Recent card fixed height — node `21:3685`
  static const double exploreSearchRecentCardHeight = 201;

  /// Typography — nodes `21:3686`, list items
  static const Color exploreSearchTextTitle = Color(0xFF252B5C);
  static const Color exploreSearchTextClear = Color(0xFF1F4C6B);
  static const Color exploreSearchTextList = Color(0xFF53587A);
  static const Color exploreSearchPlaceholder = Color(0xFFA1A5C1);

  /// Clock pill — `rgba(147,151,189,0.18)`
  static const Color exploreSearchClockPill = Color(0x2E9397BD);

  /// Estate thumb border — `#bfc1d9` @ 2px — node `21:3694`
  static const Color exploreSearchThumbBorder = Color(0xFFBFC1D9);
  static const double exploreSearchThumbBorderWidth = 2;
  static const double exploreSearchThumbRadius = 10;

  /// Purple wash on thumb — `rgba(136,74,246,0.08)`
  static const Color exploreSearchThumbOverlay = Color(0x14884AF6);
}
