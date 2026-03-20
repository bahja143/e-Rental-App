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

  /// Active filter chip — node `24:3487` “Button / Filter - Rounded” (`#EDE8C2`)
  static const Color exploreSearchFilterChipFill = Color(0xFFEDE8C2);

  // --- Listing / estate detail — node `28:4568` “Detail / Full” (Hanti riyo – Copy) ---

  /// Main photo block height inside rounded hero
  static const double listingDetailHeroHeight = 400;

  /// Hero / property image corner radius (slightly softer than Figma 50 for on-device feel)
  static const double listingDetailHeroRadius = 40;

  /// Header actions: `Button / Back`, `Button / Share`, favorite — `size-[50px]`, `rounded-[25px]`
  static const double listingDetailToolbarSize = 50;
  static const double listingDetailToolbarRadius = 25;

  /// `Button / Back - Transparent` — `backdrop-blur-[6px] bg-[rgba(255,255,255,0.8)]`
  static const double listingDetailBackBlurSigma = 6;
  static final Color listingDetailBackBlurFill = Colors.white.withValues(alpha: 0.8);

  /// Node **`28:4657`** / **`28:4659`** — `Button / Share`: **Grey - Soft 1** `#f5f4f8` (no blur).
  /// Also used for favorite **inactive**; back uses frosted blur instead.
  static const Color listingDetailShareFill = Color(0xFFF5F4F8);

  /// Bottom hero pills — `backdrop-blur-[14px] bg-[rgba(35,79,104,0.69)]`
  static const double listingDetailHeroPillBlurSigma = 14;
  static const Color listingDetailHeroPillFill = Color(0xB0234F68);

  /// `Card / Review Total` — `bg-[rgba(31,76,107,0.69)]`
  static const Color listingDetailReviewCardFill = Color(0xB01F4C6B);

  /// Star box inside review card — `bg-[rgba(0,0,0,0.15)]`
  static const Color listingDetailReviewStarBox = Color(0x26000000);

  /// `Available` pill — light mint (readable black label)
  static const Color listingDetailAvailableFill = Color(0xFFE8F5E9);

  /// Map footer — `backdrop-blur-[10px] bg-[rgba(255,255,255,0.5)]`
  static const double listingDetailMapFooterBlurSigma = 10;
  static final Color listingDetailMapFooterFill = Colors.white.withValues(alpha: 0.5);

  /// Gallery thumbs — `size-[60px]`, `rounded-[18px]`, `border-3 border-white`
  static const double listingDetailGalleryThumb = 60;
  static const double listingDetailGalleryRadius = 18;
  static const double listingDetailGalleryBorder = 3;

  /// Node `28:4571` — “Nearby from this location” horizontal strip (vertical card).
  static const double listingDetailNearbyCarouselHeight = 260;
  static const double listingDetailNearbyCardWidth = 156;

  /// `Photos / Gallery - Small - Counter` overlay
  static const Color listingDetailGalleryMoreOverlay = Color(0x6E170C2E);

  /// `28:4658` — `Button / Favorite - Active - Big`
  /// `shadow-[0px_11px_40px_0px_rgba(139,200,63,0.6)]`
  static const BoxShadow listingDetailFavoriteActiveShadow = BoxShadow(
    color: Color(0x998BC83F),
    blurRadius: 40,
    spreadRadius: 0,
    offset: Offset(0, 11),
  );

  /// Heart icon inset ~`inset-[28%]` on 50×50 control → visual size ~22px
  static const double listingDetailFavoriteIconSize = 22;

  /// Primary CTA — same gold shadow language as explore modals
  static const BoxShadow listingDetailPrimaryCtaShadow = exploreSearchModalGoldShadow;
}
