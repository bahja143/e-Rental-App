import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/services.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/figma_tokens.dart';

import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/remote_image.dart';
import '../data/models/estate_item.dart';
import '../widgets/listing_detail_map_preview.dart';
import 'listing_full_map_screen.dart';
import '../data/repositories/estate_repository.dart';
import '../widgets/estate_card.dart';
import '../data/models/listing_review.dart';
import '../widgets/listing_review_tile.dart';

/// Listing / property detail — Figma **Hanti riyo (Copy)** node `28:4568`.
class EstateDetailScreen extends StatefulWidget {
  const EstateDetailScreen({
    super.key,
    this.estateId = '1',
    this.title = 'Modern Apartment',
    this.location = 'Mogadishu',
    this.price = 190,
    this.imageUrl = 'https://www.figma.com/api/mcp/asset/4313825d-f243-4dfc-9d1e-699a17342288',
    this.description,
  });

  final String estateId;
  final String title;
  final String location;
  final double price;
  final String imageUrl;
  final String? description;

  @override
  State<EstateDetailScreen> createState() => _EstateDetailScreenState();
}

class _EstateDetailScreenState extends State<EstateDetailScreen> {
  final _repo = EstateRepository();
  late final Future<_EstateDetailData> _detailFuture;
  final PageController _heroPageController = PageController();
  int _heroPageIndex = 0;
  bool _isSaved = false;
  bool _savingFavorite = false;

  /// User toggle for Rent vs Buy (`null` = use API default: prefer rent when both exist).
  bool? _listingTypeRentOverride;

  /// Picked in **Figma `28:4473`** location-distance sheet; drives the "… km from …" row.
  double _distanceKm = 2.5;
  String _distanceFromLabel = 'your location';

  @override
  void initState() {
    super.initState();
    _detailFuture = _loadDetail();
    _loadSavedState();
  }

  @override
  void dispose() {
    _heroPageController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedState() async {
    final ids = await _repo.getSavedEstateIds();
    if (!mounted) return;
    setState(() => _isSaved = ids.contains(widget.estateId));
  }

  Future<void> _toggleSaved() async {
    if (_savingFavorite) return;
    final wasSaved = _isSaved;
    setState(() {
      _savingFavorite = true;
      _isSaved = !wasSaved;
    });
    final ok = wasSaved
        ? await _repo.removeSavedEstate(widget.estateId)
        : await _repo.addSavedEstate(widget.estateId);
    if (!mounted) return;
    setState(() {
      _savingFavorite = false;
      if (!ok) _isSaved = wasSaved;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? (_isSaved ? 'Added to favorites.' : 'Removed from favorites.')
              : 'Could not update favorites.',
          style: GoogleFonts.lato(),
        ),
      ),
    );
  }

  Future<void> _shareListing(_EstateDetailData data) async {
    final message = StringBuffer()
      ..writeln(data.title)
      ..writeln(data.location)
      ..writeln('\$${_displayPrice(data).toStringAsFixed(0)}');
    await Clipboard.setData(ClipboardData(text: message.toString().trim()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Listing details copied to clipboard.',
          style: GoogleFonts.lato(),
        ),
      ),
    );
  }

  bool _effectiveShowRent(_EstateDetailData data) {
    if (_listingTypeRentOverride != null) {
      final wantRent = _listingTypeRentOverride!;
      if (wantRent && data.hasRentOption) return true;
      if (!wantRent && data.hasSellOption) return false;
    }
    if (data.hasRentOption) return true;
    if (data.hasSellOption) return false;
    return data.isRent;
  }

  double _displayPrice(_EstateDetailData data) {
    if (_effectiveShowRent(data) && data.rentPrice > 0) return data.rentPrice;
    if (!_effectiveShowRent(data) && data.sellPrice > 0) return data.sellPrice;
    return data.price;
  }

  Future<_EstateDetailData> _loadDetail() async {
    final repo = EstateRepository();
    final listing = await repo.getEstateById(widget.estateId);
    final nearby = await repo.getNearbyFromEstate(widget.estateId);
    final reviews = await repo.getListingReviews(widget.estateId);

    return _EstateDetailData.fromApi(
      listing: listing,
      nearby: nearby,
      reviews: reviews,
      widgetFallback: widget,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_EstateDetailData>(
      future: _detailFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Could not load listing',
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.greyMedium,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _detailFuture = _loadDetail();
                        });
                      },
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final data = snapshot.data!;
        return Scaffold(
          backgroundColor: Colors.white,
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHero(context, data)),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildTitlePriceBlock(data),
                    const SizedBox(height: 12),
                    _buildLocationRow(data),
                    const SizedBox(height: 20),
                    _buildRentBuyAvailableRow(data),
                    const SizedBox(height: 12),
                    _buildSectionDivider(),
                    const SizedBox(height: 16),
                    _buildAgentCard(context, data),
                    const SizedBox(height: 20),
                    _buildRoomFeaturePills(data),
                    const SizedBox(height: 28),
                    _buildLatoSectionTitle('Location & Public Facilities'),
                    const SizedBox(height: 12),
                    _buildLocationAddressBlock(data),
                    const SizedBox(height: 12),
                    _buildDistanceRow(context, data),
                    const SizedBox(height: 12),
                    _buildPublicFacilityPills(),
                    const SizedBox(height: 12),
                    _buildMapCard(context, data),
                    const SizedBox(height: 28),
                    _buildLatoSectionTitle('Facilities'),
                    const SizedBox(height: 12),
                    _buildFacilities(context, data.facilities),
                    const SizedBox(height: 28),
                    _buildDescriptionSection(data),
                    const SizedBox(height: 28),
                    _buildCostOfLivingSection(),
                    const SizedBox(height: 28),
                    // Figma `28:4577` — **Reviews**: title → summary card → preview rows → **View all** last.
                    _buildSectionTitle('Reviews'),
                    const SizedBox(height: 12),
                    _buildReviewsSummaryCard(data),
                    const SizedBox(height: 12),
                    if (data.reviews.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          'No reviews yet.',
                          style: GoogleFonts.lato(
                            fontSize: 14,
                            color: AppColors.greyBarelyMedium,
                          ),
                        ),
                      )
                    else
                      Column(
                        children: data.reviews
                            .take(2)
                            .map(
                              (r) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: ListingReviewListTile(review: r),
                              ),
                            )
                            .toList(),
                      ),
                    const SizedBox(height: 12),
                    _buildViewAllReviewsButton(context, data),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Nearby From this Location'),
                    const SizedBox(height: 12),
                    _buildNearbyHorizontal(context, data),
                    const SizedBox(height: 88),
                  ]),
                ),
              ),
            ],
          ),
          bottomNavigationBar: Material(
            color: AppColors.surface,
            elevation: 0,
            child: SafeArea(
              top: false,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 20,
                      offset: const Offset(0, -6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => context.push(AppRoutes.chatDetail('0', name: data.agentName)),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          minimumSize: const Size(0, 56),
                          foregroundColor: AppColors.textSecondary,
                          side: const BorderSide(color: AppColors.textSecondary, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(FigmaHantiRiyoTokens.exploreSearchRadiusLg),
                          ),
                        ),
                        child: Text(
                          'Chat',
                          style: GoogleFonts.lato(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(FigmaHantiRiyoTokens.exploreSearchRadiusLg),
                          boxShadow: const [FigmaHantiRiyoTokens.listingDetailPrimaryCtaShadow],
                        ),
                        child: AppButton(
                          label: 'Book Now',
                          onPressed: () => context.push(AppRoutes.transactionSummaryForEstate(widget.estateId)),
                          height: 56,
                          width: double.infinity,
                          borderRadius: FigmaHantiRiyoTokens.exploreSearchRadiusLg,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Figma `28:4568` / `28:4649` — side margins, white **10px** frame, `28:4651` **3** gallery thumbs.
  (List<String> heroUrls, int originalImageCount) _heroUrlsAndCount(_EstateDetailData data) {
    final raw = data.imageUrls.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (raw.isEmpty && data.imageUrl.trim().isNotEmpty) {
      raw.add(data.imageUrl.trim());
    }
    final n = raw.length;
    if (n == 0) {
      return (['', '', ''], 0);
    }
    final out = List<String>.from(raw);
    while (out.length < 3) {
      out.add(out.first);
    }
    return (out, n);
  }

  /// Figma `28:4568` — `Detail / Full`: hero margins, `28:4649` white frame, PageView + 3-thumb gallery.
  Widget _buildHero(BuildContext context, _EstateDetailData data) {
    final topInset = MediaQuery.paddingOf(context).top;
    final (heroUrls, originalCount) = _heroUrlsAndCount(data);
    final h = FigmaHantiRiyoTokens.listingDetailHeroHeight;
    final rOuter = FigmaHantiRiyoTokens.listingDetailHeroRadius;
    final bw = FigmaHantiRiyoTokens.listingDetailHeroFrameBorder;
    final rInner = (rOuter - bw).clamp(8.0, rOuter);

    Widget heroStack() {
      return SizedBox(
        height: h,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _heroPageController,
              itemCount: heroUrls.length,
              onPageChanged: (i) => setState(() => _heroPageIndex = i),
              itemBuilder: (_, i) => RemoteImage(
                url: heroUrls[i],
                fit: BoxFit.cover,
                errorWidget: Container(
                  color: AppColors.greySoft1,
                  child: const Icon(Icons.home_work_outlined, size: 64, color: AppColors.greyBarelyMedium),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: ColoredBox(color: FigmaHantiRiyoTokens.exploreSearchThumbOverlay),
              ),
            ),
            if (originalCount > 0)
              Positioned(
                right: 20,
                top: h * 0.36,
                child: _buildHeroGalleryColumn(
                  heroUrls,
                  originalImageCount: originalCount,
                  selectedPageIndex: _heroPageIndex,
                ),
              ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 28,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _listingHeroBlurPill(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16.5),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '⭐',
                          style: GoogleFonts.raleway(
                            fontSize: 15,
                            color: FigmaHantiRiyoTokens.exploreSearchTextTitle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          data.rating.toStringAsFixed(1),
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.42,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: _listingHeroBlurPill(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 17.5),
                      child: Text(
                        data.propertyTypeLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.raleway(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(0, topInset + 8, 0, 0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(rOuter),
            ),
            child: Padding(
              padding: EdgeInsets.all(bw),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(rInner),
                child: heroStack(),
              ),
            ),
          ),
          Positioned(
            left: 15,
            right: 15,
            top: 24,
            child: Row(
              children: [
                _listingToolbarBack(context),
                const Spacer(),
                _listingToolbarShare(data),
                const SizedBox(width: 15),
                _listingToolbarFavorite(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _listingHeroBlurPill({required EdgeInsets padding, required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(FigmaHantiRiyoTokens.exploreSearchRadiusLg),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: FigmaHantiRiyoTokens.listingDetailHeroPillBlurSigma,
          sigmaY: FigmaHantiRiyoTokens.listingDetailHeroPillBlurSigma,
        ),
        child: DecoratedBox(
          decoration: const BoxDecoration(color: FigmaHantiRiyoTokens.listingDetailHeroPillFill),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }

  /// Hero toolbar: **back** = frosted blur ([`listingDetailBackBlurFill`]); **share** = solid `#f5f4f8`.

  Widget _listingToolbarGlassButton({
    required VoidCallback onTap,
    required Widget child,
  }) {
    final s = FigmaHantiRiyoTokens.listingDetailToolbarSize;
    final r = FigmaHantiRiyoTokens.listingDetailToolbarRadius;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(r),
        child: Container(
          width: s,
          height: s,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: FigmaHantiRiyoTokens.listingDetailShareFill,
            borderRadius: BorderRadius.circular(r),
          ),
          child: child,
        ),
      ),
    );
  }

  /// Figma `28:4660` — **Button / Back - Transparent**: blur + `rgba(255,255,255,0.8)` (not solid `#f5f4f8`).
  Widget _listingToolbarBack(BuildContext context) {
    final s = FigmaHantiRiyoTokens.listingDetailToolbarSize;
    final r = FigmaHantiRiyoTokens.listingDetailToolbarRadius;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.pop(),
        borderRadius: BorderRadius.circular(r),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(r),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: FigmaHantiRiyoTokens.listingDetailBackBlurSigma,
              sigmaY: FigmaHantiRiyoTokens.listingDetailBackBlurSigma,
            ),
            child: Container(
              width: s,
              height: s,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: FigmaHantiRiyoTokens.listingDetailBackBlurFill,
                borderRadius: BorderRadius.circular(r),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.textPrimary),
            ),
          ),
        ),
      ),
    );
  }

  Widget _listingToolbarShare(_EstateDetailData data) {
    return _listingToolbarGlassButton(
      onTap: () => _shareListing(data),
      child: const Icon(Icons.ios_share, size: 20, color: AppColors.textPrimary),
    );
  }

  /// Figma `28:4658` — primary circle + optional green glow when favorited.
  Widget _listingToolbarFavorite() {
    final s = FigmaHantiRiyoTokens.listingDetailToolbarSize;
    final r = FigmaHantiRiyoTokens.listingDetailToolbarRadius;
    final heartSize = FigmaHantiRiyoTokens.listingDetailFavoriteIconSize;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _toggleSaved,
        borderRadius: BorderRadius.circular(r),
        child: Container(
          width: s,
          height: s,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(r),
            boxShadow: _isSaved
                ? [
                    BoxShadow(
                      color: const Color(0x998BC83F),
                      blurRadius: 40,
                      offset: const Offset(0, 11),
                      spreadRadius: -8,
                    ),
                  ]
                : null,
          ),
          child: _savingFavorite
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(
                  _isSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  size: heartSize,
                  color: Colors.white,
                ),
        ),
      ),
    );
  }

  /// Figma `28:4651` — always **3** thumbs; tap switches [`PageView`]; `+N` when more than 3 photos.
  Widget _buildHeroGalleryColumn(
    List<String> urls, {
    required int originalImageCount,
    required int selectedPageIndex,
  }) {
    final thumb = FigmaHantiRiyoTokens.listingDetailGalleryThumb;
    final rad = FigmaHantiRiyoTokens.listingDetailGalleryRadius;
    final bw = FigmaHantiRiyoTokens.listingDetailGalleryBorder;

    void go(int page) {
      if (page >= 0 && page < urls.length) {
        setState(() => _heroPageIndex = page);
        _heroPageController.animateToPage(
          page,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    }

    Widget thumbCell({
      required int pageIndex,
      required String imageUrl,
      Color borderColor = Colors.white,
      bool showPlusOverlay = false,
      int plusCount = 0,
    }) {
      final selected = selectedPageIndex == pageIndex ||
          (pageIndex == 2 && selectedPageIndex >= 3 && originalImageCount > 3);
      // Border is part of [BoxDecoration]; the child still gets the full box, so images
      // can bleed past rounded corners unless we clip to the **inner** radius (Figma `28:4651`).
      final borderW = selected ? bw + 0.5 : bw;
      final innerR = (rad - borderW).clamp(0.0, rad);
      return GestureDetector(
        onTap: () => go(pageIndex),
        child: Container(
          width: thumb,
          height: thumb,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(rad),
            border: Border.all(
              color: selected ? AppColors.primary : borderColor,
              width: borderW,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(innerR),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.hardEdge,
              children: [
                RemoteImage(
                  url: imageUrl,
                  fit: BoxFit.cover,
                  width: thumb,
                  height: thumb,
                  errorWidget: Container(color: AppColors.primaryBackground),
                ),
                if (showPlusOverlay) ...[
                  const ColoredBox(color: FigmaHantiRiyoTokens.listingDetailGalleryMoreOverlay),
                  Center(
                    child: Text(
                      '+$plusCount',
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: AppColors.greySoft2,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    final thirdShowsPlus = originalImageCount > 3;
    final plusN = originalImageCount - 3;
    final thirdPageIndex = thirdShowsPlus ? 3 : 2;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        thumbCell(pageIndex: 0, imageUrl: urls[0]),
        const SizedBox(height: 5),
        thumbCell(pageIndex: 1, imageUrl: urls[1]),
        const SizedBox(height: 5),
        thumbCell(
          pageIndex: thirdPageIndex,
          imageUrl: urls[2],
          borderColor: thirdShowsPlus ? AppColors.greySoft1 : Colors.white,
          showPlusOverlay: thirdShowsPlus,
          plusCount: plusN,
        ),
      ],
    );
  }

  Widget _buildTitlePriceBlock(_EstateDetailData data) {
    final titleC = FigmaHantiRiyoTokens.exploreSearchTextTitle;
    final showRent = _effectiveShowRent(data);
    final amount = _displayPrice(data);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            data.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.lato(
              fontSize: 25,
              fontWeight: FontWeight.w700,
              height: 40 / 25,
              color: titleC,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$ ${amount.toInt()}',
              style: GoogleFonts.montserrat(
                fontSize: 25,
                fontWeight: FontWeight.w600,
                height: 40 / 25,
                color: titleC,
              ),
            ),
            if (showRent && data.hasRentOption)
              Text(
                'per month',
                style: GoogleFonts.raleway(
                  fontSize: 12,
                  color: FigmaHantiRiyoTokens.exploreSearchTextList,
                  letterSpacing: 0.36,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationRow(_EstateDetailData data) {
    return Row(
      children: [
        Icon(Icons.location_on_outlined, size: 12, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            data.location,
            style: GoogleFonts.raleway(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: FigmaHantiRiyoTokens.exploreSearchTextList,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRentBuyAvailableRow(_EstateDetailData data) {
    /// Figma `28:4632` / `28:5539` — Rent selected: gold + **Raleway Bold** white; Buy idle: `#f5f4f8` + **Raleway Medium** `#252b5c`.
    final titleC = FigmaHantiRiyoTokens.exploreSearchTextTitle;
    final rentSelected = _effectiveShowRent(data);
    final buySelected = !rentSelected && data.hasSellOption;

    Widget typePill(
      String label, {
      required bool selected,
      required bool enabled,
      VoidCallback? onTap,
      bool boldWhenSelected = true,
    }) {
      final child = Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 17.5),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.greySoft1,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.raleway(
            fontSize: 10,
            fontWeight: selected && boldWhenSelected ? FontWeight.w700 : FontWeight.w500,
            letterSpacing: 0.3,
            height: 1,
            color: selected
                ? Colors.white
                : (enabled ? titleC : AppColors.greyBarelyMedium),
          ),
        ),
      );

      if (!enabled) {
        return child;
      }

      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: child,
        ),
      );
    }

    return Row(
      children: [
        typePill(
          'Rent',
          selected: rentSelected,
          enabled: data.hasRentOption,
          onTap: data.hasRentOption ? () => setState(() => _listingTypeRentOverride = true) : null,
        ),
        const SizedBox(width: 10),
        typePill(
          'Buy',
          selected: buySelected,
          enabled: data.hasSellOption,
          boldWhenSelected: true,
          onTap: data.hasSellOption ? () => setState(() => _listingTypeRentOverride = false) : null,
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0x4D8BC83F),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(color: Color(0xFF8BC83F), shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                'Available',
                style: GoogleFonts.raleway(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                  letterSpacing: 0.3,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionDivider() {
    return Container(height: 1, color: AppColors.greySoft2);
  }

  Widget _buildLatoSectionTitle(String text) {
    return Text(
      text,
      style: GoogleFonts.lato(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 28 / 18,
        color: FigmaHantiRiyoTokens.exploreSearchTextTitle,
        letterSpacing: 0.54,
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Text(
      text,
      style: GoogleFonts.raleway(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: FigmaHantiRiyoTokens.exploreSearchTextTitle,
        letterSpacing: 0.54,
      ),
    );
  }

  Widget _roomFeaturePill(IconData icon, String label, {bool accent = false}) {
    final c = accent ? const Color(0xFF3A3F67) : FigmaHantiRiyoTokens.exploreSearchTextList;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
      decoration: BoxDecoration(
        color: AppColors.greySoft1,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: accent ? c : AppColors.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.raleway(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: c,
              letterSpacing: 0.36,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomFeaturePills(_EstateDetailData data) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _roomFeaturePill(Icons.bed_outlined, '${data.bedrooms} Bedroom'),
          const SizedBox(width: 10),
          _roomFeaturePill(Icons.bathtub_outlined, '${data.bathrooms} Bathroom'),
          const SizedBox(width: 10),
          _roomFeaturePill(Icons.square_foot_outlined, 'Floor plan', accent: true),
        ],
      ),
    );
  }

  Widget _buildLocationAddressBlock(_EstateDetailData data) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.greySoft1,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Icon(Icons.location_on_outlined, size: 22, color: AppColors.textSecondary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            data.location,
            style: GoogleFonts.raleway(
              fontSize: 12,
              height: 20 / 12,
              color: FigmaHantiRiyoTokens.exploreSearchTextList,
              letterSpacing: 0.36,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDistanceKm(double km) {
    final s = km.toStringAsFixed(1);
    return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  }

  void _showLocationDistanceModal(BuildContext context, _EstateDetailData data) {
    final rootContext = context;
    final secondSuffix = data.nearby.isNotEmpty
        ? data.nearby.first.location
        : 'Petompon, Kota Semarang, Jawa Tengah 50232';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0xAB1F4C6B),
      builder: (sheetContext) {
        return _LocationDistanceSheet(
          primaryLocationLine: data.location,
          secondaryLocationLine: secondSuffix,
          onPick: (km, fromSuffix) {
            Navigator.of(sheetContext).pop();
            if (!rootContext.mounted) return;
            setState(() {
              _distanceKm = km;
              _distanceFromLabel = fromSuffix;
            });
          },
          onEditTap: () {
            Navigator.of(sheetContext).pop();
            if (!rootContext.mounted) return;
            ScaffoldMessenger.of(rootContext).showSnackBar(
              const SnackBar(content: Text('Edit location')),
            );
          },
        );
      },
    );
  }

  Widget _buildDistanceRow(BuildContext context, _EstateDetailData data) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(25),
        onTap: () => _showLocationDistanceModal(context, data),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: AppColors.greySoft2, width: 1.2),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Icon(Icons.map_outlined, size: 20, color: AppColors.textSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: GoogleFonts.raleway(
                      fontSize: 12,
                      height: 20 / 12,
                      color: FigmaHantiRiyoTokens.exploreSearchTextList,
                      letterSpacing: 0.36,
                    ),
                    children: [
                      TextSpan(
                        text: '${_formatDistanceKm(_distanceKm)} ',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w700,
                          color: FigmaHantiRiyoTokens.exploreSearchTextTitle,
                          letterSpacing: 0.36,
                        ),
                      ),
                      TextSpan(
                        text: 'km',
                        style: GoogleFonts.raleway(
                          fontWeight: FontWeight.w700,
                          color: FigmaHantiRiyoTokens.exploreSearchTextTitle,
                          letterSpacing: 0.36,
                        ),
                      ),
                      TextSpan(
                        text: ' from $_distanceFromLabel',
                        style: GoogleFonts.raleway(
                          fontSize: 12,
                          height: 20 / 12,
                          color: FigmaHantiRiyoTokens.exploreSearchTextList,
                          letterSpacing: 0.36,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded, size: 22, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _publicFacilityTag(String t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 17.5),
      decoration: BoxDecoration(
        color: AppColors.greySoft1,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        t,
        style: GoogleFonts.raleway(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: FigmaHantiRiyoTokens.exploreSearchTextList,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildPublicFacilityPills() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _publicFacilityTag('2 Hospital'),
          const SizedBox(width: 10),
          _publicFacilityTag('4 Gas stations'),
          const SizedBox(width: 10),
          _publicFacilityTag('2 Schools'),
        ],
      ),
    );
  }

  /// Positions for nearby listings when API has no lat/lng (same spread as former placeholder pins).
  List<ListingMapNearbyPin> _nearbyPinsForFullMap(_EstateDetailData data) {
    const deltas = <(double, double)>[
      (0.0055, 0.0065),
      (-0.004, 0.003),
      (0.003, -0.006),
      (-0.0065, -0.002),
    ];
    final cLat = data.mapLat;
    final cLng = data.mapLng;
    var fallbackIndex = 0;
    final out = <ListingMapNearbyPin>[];
    for (final e in data.nearby) {
      if (e.id == widget.estateId) continue;
      final double lat;
      final double lng;
      if (e.hasCoordinates) {
        lat = e.lat!;
        lng = e.lng!;
      } else {
        final d = deltas[fallbackIndex % deltas.length];
        fallbackIndex++;
        lat = cLat + d.$1;
        lng = cLng + d.$2;
      }
      out.add(ListingMapNearbyPin(
        id: e.id,
        imageUrl: e.imageUrl,
        latitude: lat,
        longitude: lng,
      ));
    }
    return out;
  }

  /// **Figma `28:4593`** — real map, custom pin ([`createMapPinDescriptor`]), frosted footer.
  Widget _buildMapCard(BuildContext context, _EstateDetailData data) {
    final target = LatLng(data.mapLat, data.mapLng);
    final locLine = data.location.trim().isNotEmpty
        ? data.location.trim()
        : (data.title.trim().isNotEmpty ? data.title.trim() : 'Property location');
    return ListingDetailMapPreview(
      target: target,
      imageUrl: data.imageUrl,
      height: 235,
      onViewAllTap: () => context.push(
            AppRoutes.listingMap,
            extra: ListingMapRouteArgs(
              estateId: widget.estateId,
              title: data.title,
              locationLabel: locLine,
              imageUrl: data.imageUrl,
              latitude: data.mapLat,
              longitude: data.mapLng,
              regionLabel: ListingMapRouteArgs.deriveRegionChip(locLine),
              nearbyPins: _nearbyPinsForFullMap(data),
            ),
          ),
    );
  }

  Widget _buildDescriptionSection(_EstateDetailData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: GoogleFonts.lato(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: FigmaHantiRiyoTokens.exploreSearchTextTitle,
            letterSpacing: 0.54,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Property Condition:  New',
          style: GoogleFonts.raleway(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: FigmaHantiRiyoTokens.exploreSearchTextTitle,
            letterSpacing: 0.42,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Ownership Type: freehold / leasehold',
          style: GoogleFonts.raleway(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: FigmaHantiRiyoTokens.exploreSearchTextTitle,
            letterSpacing: 0.42,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          data.description,
          style: GoogleFonts.raleway(
            fontSize: 14,
            height: 24 / 14,
            color: FigmaHantiRiyoTokens.exploreSearchTextList,
            letterSpacing: 0.42,
          ),
        ),
      ],
    );
  }

  Widget _buildCostOfLivingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Cost of Living',
              style: GoogleFonts.lato(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: FigmaHantiRiyoTokens.exploreSearchTextTitle,
                letterSpacing: 0.54,
              ),
            ),
            const Spacer(),
           
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.greySoft1,
            borderRadius: BorderRadius.circular(FigmaHantiRiyoTokens.exploreSearchRadiusLg),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '\$ 830',
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: FigmaHantiRiyoTokens.exploreSearchTextTitle,
                      ),
                    ),
                    TextSpan(
                      text: '/month*',
                      style: GoogleFonts.raleway(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: FigmaHantiRiyoTokens.exploreSearchTextTitle,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '*From average citizen spend around this location',
                style: GoogleFonts.raleway(
                  fontSize: 10,
                  color: FigmaHantiRiyoTokens.exploreSearchTextList,
                  letterSpacing: 0.27,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewsSummaryCard(_EstateDetailData data) {
    final n = data.reviewCount;
    final fullStars = data.rating.floor().clamp(0, 5);
    final avatarUrls = data.reviews
        .map((r) => r.avatarUrl?.trim())
        .whereType<String>()
        .where((u) => u.isNotEmpty)
        .take(3)
        .toList();
    return Container(
      height: 85,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: FigmaHantiRiyoTokens.listingDetailReviewCardFill,
        borderRadius: BorderRadius.circular(FigmaHantiRiyoTokens.exploreSearchRadiusLg),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: FigmaHantiRiyoTokens.listingDetailReviewStarBox,
              borderRadius: BorderRadius.circular(17),
            ),
            child: Text('⭐', style: GoogleFonts.raleway(fontSize: 23)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ...List.generate(
                      5,
                      (i) => Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: i < fullStars ? AppColors.primary : Colors.white24,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      data.rating.toStringAsFixed(1),
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.greySoft1,
                      ),
                    ),
                  ],
                ),
                if (n > 0) ...[
                  const SizedBox(height: 4),
                  Text.rich(
                    TextSpan(
                      style: GoogleFonts.raleway(
                        fontSize: 10,
                        color: AppColors.greySoft1,
                        letterSpacing: 0.27,
                      ),
                      children: [
                        const TextSpan(text: 'From '),
                        TextSpan(text: '$n', style: GoogleFonts.montserrat()),
                        const TextSpan(text: ' reviewers'),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(
            width: 72,
            height: 30,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (var i = 0; i < 3; i++)
                  Positioned(
                    left: i * 18.0,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        color: AppColors.greySoft2,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: i < avatarUrls.length
                          ? RemoteImage(
                              url: avatarUrls[i],
                              fit: BoxFit.cover,
                              width: 30,
                              height: 30,
                              errorWidget: Icon(
                                Icons.person_rounded,
                                size: 16,
                                color: AppColors.greyBarelyMedium,
                              ),
                            )
                          : Icon(Icons.person_rounded, size: 16, color: AppColors.greyBarelyMedium),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewAllReviewsButton(BuildContext context, _EstateDetailData data) {
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: Material(
        color: AppColors.greySoft1,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: () => context.push(AppRoutes.estateReviews(widget.estateId, title: data.title)),
          borderRadius: BorderRadius.circular(15),
          child: Center(
            child: Text(
              'View all reviews',
              style: GoogleFonts.raleway(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: FigmaHantiRiyoTokens.exploreSearchTextClear,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNearbyHorizontal(BuildContext context, _EstateDetailData data) {
    if (data.nearby.isEmpty) {
      return Text(
        'No nearby listings.',
        style: GoogleFonts.lato(fontSize: 14, color: AppColors.greyBarelyMedium),
      );
    }
    return SizedBox(
      height: FigmaHantiRiyoTokens.listingDetailNearbyCarouselHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: data.nearby.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final e = data.nearby[i];
          return SizedBox(
            width: FigmaHantiRiyoTokens.listingDetailNearbyCardWidth,
            child: EstateCard.vertical(
              title: e.title,
              location: e.location,
              price: e.price,
              rating: e.rating,
              imageUrl: e.imageUrl,
              category: e.displayCategory,
              onTap: () => context.push(AppRoutes.estateDetail(e.id)),
            ),
          );
        },
      ),
    );
  }

  IconData _facilityIconForName(String name) {
    final n = name.toLowerCase();
    if (n.contains('pool')) return Icons.pool_outlined;
    if (n.contains('park')) return Icons.local_parking_outlined;
    if (n.contains('balcon')) return Icons.window_outlined;
    if (n.contains('cctv') || n.contains('camera')) return Icons.videocam_outlined;
    if (n.contains('elevator') || n.contains('lift')) return Icons.unfold_more_double;
    if (n.contains('gym')) return Icons.fitness_center_outlined;
    if (n.contains('pet')) return Icons.pets_outlined;
    if (n.contains('garden')) return Icons.park_outlined;
    return Icons.check_circle_outline_rounded;
  }

  /// Figma `28:4630` — `Item / Owner` (`#f5f4f8`, 85px row).
  Widget _buildAgentCard(BuildContext context, _EstateDetailData data) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(AppRoutes.chatDetail('0', name: data.agentName)),
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.greySoft1,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            height: 85,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            alignment: Alignment.centerLeft,
            child: Row(
            children: [
              SizedBox(
                width: 38,
                height: 38,
                child: ClipOval(
                  child: RemoteImage(
                    url: data.agentAvatarUrl,
                    fit: BoxFit.cover,
                    errorWidget: Container(color: AppColors.greySoft2),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.agentName,
                      style: GoogleFonts.raleway(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.42,
                        color: FigmaHantiRiyoTokens.exploreSearchTextTitle,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Real Estate Agent',
                      style: GoogleFonts.raleway(
                        fontSize: 10,
                        letterSpacing: 0.27,
                        color: FigmaHantiRiyoTokens.exploreSearchTextList,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chat_bubble_outline_rounded, size: 20, color: AppColors.textSecondary),
            ],
          ),
          ),
        ),
      ),
    );
  }

  Widget _buildFacilities(BuildContext context, List<String> items) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items
          .map(
            (e) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.greySoft1,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_facilityIconForName(e), size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    e,
                    style: GoogleFonts.raleway(
                      fontSize: 12,
                      height: 1.7,
                      color: FigmaHantiRiyoTokens.exploreSearchTextList,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

/// Figma **`28:4473`** — `Detail / Location Distance` bottom sheet (`Modal` `28:4524`).
class _LocationDistanceSheet extends StatelessWidget {
  const _LocationDistanceSheet({
    required this.primaryLocationLine,
    required this.secondaryLocationLine,
    required this.onPick,
    required this.onEditTap,
  });

  final String primaryLocationLine;
  final String secondaryLocationLine;
  final void Function(double km, String fromSuffix) onPick;
  final VoidCallback onEditTap;

  static const Color _pinOrange = Color(0xFFFA712D);

  @override
  Widget build(BuildContext context) {
    final titleC = FigmaHantiRiyoTokens.exploreSearchTextTitle;
    final listC = FigmaHantiRiyoTokens.exploreSearchTextList;
    final radiusTop = FigmaHantiRiyoTokens.listingDetailHeroRadius;

    Widget distanceCard(double km, String fromSuffix) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          onTap: () => onPick(km, fromSuffix),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: AppColors.greySoft2, width: 1.2),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 35,
                  height: 35,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.greySoft2,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: AppColors.greySoft2, width: 1.2),
                  ),
                  child: Icon(Icons.location_on_outlined, size: 20, color: AppColors.textSecondary),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      style: GoogleFonts.raleway(
                        fontSize: 12,
                        height: 20 / 12,
                        color: listC,
                        letterSpacing: 0.36,
                      ),
                      children: [
                        TextSpan(
                          text: _fmtKm(km),
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            height: 20 / 12,
                            color: titleC,
                            letterSpacing: 0.36,
                          ),
                        ),
                        TextSpan(
                          text: ' km',
                          style: GoogleFonts.raleway(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            height: 20 / 12,
                            color: titleC,
                            letterSpacing: 0.36,
                          ),
                        ),
                        TextSpan(text: ' from $fromSuffix'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final h = MediaQuery.sizeOf(context).height;
    return SizedBox(
      height: h,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pop(),
              child: const SizedBox.expand(),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(radiusTop)),
                ),
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Center(
                            child: Container(
                              width: 60,
                              height: 4,
                              decoration: BoxDecoration(
                                color: const Color(0xFFD1D5DB),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 36),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  'Location Distance',
                                  style: GoogleFonts.lato(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: titleC,
                                    letterSpacing: 0.54,
                                  ),
                                ),
                              ),
                            
                            ],
                          ),
                          const SizedBox(height: 15),
                          distanceCard(2.5, primaryLocationLine),
                          const SizedBox(height: 15),
                          distanceCard(18.2, secondaryLocationLine),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _fmtKm(double km) {
    final s = km.toStringAsFixed(1);
    return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  }
}

class _EstateDetailData {
  const _EstateDetailData({
    required this.title,
    required this.location,
    required this.price,
    required this.rentPrice,
    required this.sellPrice,
    required this.imageUrl,
    required this.imageUrls,
    required this.propertyTypeLabel,
    required this.isRent,
    required this.isForSale,
    required this.bedrooms,
    required this.bathrooms,
    required this.reviewCount,
    required this.description,
    required this.facilities,
    required this.agentName,
    required this.agentAvatarUrl,
    required this.rating,
    required this.reviews,
    required this.nearby,
    this.latitude,
    this.longitude,
  });

  /// Mogadishu — used when API omits coordinates so the map still renders.
  static const double _fallbackMapLat = 2.0469;
  static const double _fallbackMapLng = 45.3182;

  bool get hasRentOption => rentPrice > 0;
  bool get hasSellOption => sellPrice > 0;

  double get mapLat => latitude ?? _fallbackMapLat;
  double get mapLng => longitude ?? _fallbackMapLng;

  factory _EstateDetailData.fromApi({
    required Map<String, dynamic>? listing,
    required List<EstateItem> nearby,
    required List<Map<String, dynamic>> reviews,
    required EstateDetailScreen widgetFallback,
  }) {
    final data = listing ?? <String, dynamic>{};
    final images = data['images'];
    final imageUrls = <String>[];
    if (images is List) {
      for (final u in images) {
        final s = '$u'.trim();
        if (s.isNotEmpty) imageUrls.add(s);
      }
    }
    String imageUrl = widgetFallback.imageUrl;
    if (imageUrls.isEmpty) {
      imageUrls.add(widgetFallback.imageUrl);
    } else {
      imageUrl = imageUrls.first;
    }

    final rentRaw = _toDouble(data['rent_price']);
    final sellRaw = _toDouble(data['sell_price']);
    var rentPrice = rentRaw;
    var sellPrice = sellRaw;
    if (rentPrice <= 0 && sellPrice <= 0) {
      final fromApi = _toDouble(data['price']);
      if (fromApi > 0) {
        rentPrice = fromApi;
        sellPrice = fromApi * 200;
      } else if (widgetFallback.price > 0) {
        rentPrice = widgetFallback.price;
        sellPrice = widgetFallback.price * 200;
      }
    }
    final isRent = rentPrice > 0;
    final isForSale = sellPrice > 0;

    var bedrooms = _toInt(data['bedrooms'] ?? data['bedroom_count']);
    var bathrooms = _toInt(data['bathrooms'] ?? data['bathroom_count']);
    final listingFeatures = data['listingFeatures'];
    if (listingFeatures is List) {
      for (final item in listingFeatures.whereType<Map<String, dynamic>>()) {
        final feature = item['propertyFeature'];
        if (feature is! Map<String, dynamic>) continue;
        final name = '${feature['name_en'] ?? feature['name_so'] ?? ''}'.toLowerCase();
        final value = _toInt(item['value']);
        if (name.contains('bedroom') && bedrooms <= 0) bedrooms = value;
        if (name.contains('bathroom') && bathrooms <= 0) bathrooms = value;
      }
    }

    var propertyTypeLabel = '';
    final types = data['listingTypes'] ?? data['listing_types'];
    if (types is List && types.isNotEmpty) {
      final first = types.first;
      if (first is Map) {
        final t = '${first['name_en'] ?? first['name_so'] ?? ''}'.trim();
        if (t.isNotEmpty) propertyTypeLabel = t;
      }
    }

    final facilities = <String>[];
    final listingFacilities = data['listingFacilities'];
    if (listingFacilities is List) {
      for (final item in listingFacilities.whereType<Map<String, dynamic>>()) {
        final facility = item['facility'];
        if (facility is Map<String, dynamic>) {
          final name = '${facility['name_en'] ?? facility['name_so'] ?? ''}'.trim();
          if (name.isNotEmpty) facilities.add(name);
        }
      }
    }

    final reviewItems = reviews.map(ListingReview.fromJson).toList();
    final avgRating = reviewItems.isEmpty
        ? 0.0
        : reviewItems.map((e) => e.rating.toDouble()).reduce((a, b) => a + b) / reviewItems.length;

    final user = data['user'];
    final userMap = user is Map<String, dynamic> ? user : const <String, dynamic>{};

    final latitude = _readCoord(data['latitude'] ?? data['lat']);
    final longitude = _readCoord(data['longitude'] ?? data['lng']);

    return _EstateDetailData(
      title: '${data['title'] ?? widgetFallback.title}',
      location: '${data['address'] ?? widgetFallback.location}',
      price: rentPrice > 0
          ? rentPrice
          : (sellPrice > 0 ? sellPrice : widgetFallback.price),
      rentPrice: rentPrice,
      sellPrice: sellPrice,
      imageUrl: imageUrl,
      imageUrls: imageUrls,
      propertyTypeLabel: propertyTypeLabel,
      isRent: isRent,
      isForSale: isForSale,
      bedrooms: bedrooms,
      bathrooms: bathrooms,
      reviewCount: reviewItems.length,
      description: '${data['description'] ?? widgetFallback.description ?? ''}'.trim().isEmpty
          ? 'No description provided.'
          : '${data['description'] ?? widgetFallback.description}',
      facilities: facilities,
      agentName: '${userMap['name'] ?? ''}',
      agentAvatarUrl: '${userMap['profile_picture_url'] ?? ''}',
      rating: avgRating,
      reviews: reviewItems,
      nearby: nearby,
      latitude: latitude,
      longitude: longitude,
    );
  }

  final String title;
  final String location;
  final double price;
  final double rentPrice;
  final double sellPrice;
  final String imageUrl;
  final List<String> imageUrls;
  final String propertyTypeLabel;
  final bool isRent;
  final bool isForSale;
  final int bedrooms;
  final int bathrooms;
  final int reviewCount;
  final String description;
  final List<String> facilities;
  final String agentName;
  final String agentAvatarUrl;
  final double rating;
  final List<ListingReview> reviews;
  final List<EstateItem> nearby;
  final double? latitude;
  final double? longitude;

  static double? _readCoord(dynamic value) {
    if (value == null) return null;
    if (value is num) {
      final d = value.toDouble();
      return d.isFinite ? d : null;
    }
    final p = double.tryParse('$value');
    return p != null && p.isFinite ? p : null;
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }
}
