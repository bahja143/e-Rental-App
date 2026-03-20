import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/figma_tokens.dart';

import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/remote_image.dart';
import '../data/models/estate_item.dart';
import '../widgets/listing_detail_map_preview.dart';
import '../data/repositories/estate_repository.dart';
import '../widgets/estate_card.dart';

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
  bool _isSaved = false;
  bool _savingFavorite = false;

  /// User toggle for Rent vs Buy (`null` = use API default: prefer rent when both exist).
  bool? _listingTypeRentOverride;

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
    setState(() => _savingFavorite = true);
    final ok = _isSaved
        ? await _repo.removeSavedEstate(widget.estateId)
        : await _repo.addSavedEstate(widget.estateId);
    if (!mounted) return;
    setState(() {
      _savingFavorite = false;
      if (ok) _isSaved = !_isSaved;
    });
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

        final data = snapshot.data ?? _EstateDetailData.fallback(widget);
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
                    _buildDistanceRow(),
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
                    _buildLatoSectionTitle('Reviews'),
                    const SizedBox(height: 12),
                    _buildReviewsSummaryCard(data),
                    const SizedBox(height: 12),
                    _buildViewAllReviewsButton(),
                    const SizedBox(height: 16),
                    if (data.reviews.isEmpty)
                      Text(
                        'No reviews yet.',
                        style: GoogleFonts.lato(
                          fontSize: 14,
                          color: AppColors.greyBarelyMedium,
                        ),
                      )
                    else
                      Column(
                        children: data.reviews
                            .take(3)
                            .map(
                              (r) => _ReviewTile(
                                name: r.name,
                                rating: r.rating,
                                text: r.text,
                                date: r.dateLabel,
                              ),
                            )
                            .toList(),
                      ),
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

  /// Figma `28:4568` — `Detail / Full`: `rounded-[50px]` hero, 50×25 toolbar, vertical gallery, blur pills.
  Widget _buildHero(BuildContext context, _EstateDetailData data) {
    final topInset = MediaQuery.paddingOf(context).top;
    final urls = data.imageUrls;
    final h = FigmaHantiRiyoTokens.listingDetailHeroHeight;

    // Toolbar sits outside `ClipRRect` so `28:4658` favorite glow isn’t clipped.
    return Padding(
      padding: EdgeInsets.only(top: topInset + 8),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(FigmaHantiRiyoTokens.listingDetailHeroRadius),
            child: SizedBox(
              height: h,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    controller: _heroPageController,
                    itemCount: urls.length,
                    itemBuilder: (_, i) => RemoteImage(
                      url: urls[i],
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
                  if (urls.length > 1)
                    Positioned(
                      right: 20,
                      top: h * 0.36,
                      child: _buildHeroGalleryColumn(urls),
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
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            top: 24,
            child: Row(
              children: [
                _listingToolbarBack(context),
                const Spacer(),
                _listingToolbarShare(),
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

  /// Figma **`28:4657`** `Header` — toolbar row:
  /// - **Back** (`28:4660`): blur + `rgba(255,255,255,0.8)` — [_listingToolbarGlassButton].
  /// - **Share** (`28:4659` / `Button / Share`): solid **`#f5f4f8`**, no blur, navy icon.
  /// - **Favorite** (`28:4658`): active = primary gold + green glow + white heart; inactive = like Share.

  /// Back only — `backdrop-blur-[6px] bg-[rgba(255,255,255,0.8)]` `rounded-[25px]`.
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
              color: FigmaHantiRiyoTokens.listingDetailBackBlurFill,
              alignment: Alignment.center,
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  Widget _listingToolbarBack(BuildContext context) {
    return _listingToolbarGlassButton(
      onTap: () => context.pop(),
      child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.textPrimary),
    );
  }

  /// Share — same glass system as back (`28:4659` glyph unchanged).
  Widget _listingToolbarShare() {
    return _listingToolbarGlassButton(
      onTap: () {},
      child: const Icon(Icons.ios_share, size: 20, color: AppColors.textPrimary),
    );
  }

  /// Favorite — same glass as back; filled vs outline shows saved state.
  Widget _listingToolbarFavorite() {
    final heartSize = FigmaHantiRiyoTokens.listingDetailFavoriteIconSize;
    return _listingToolbarGlassButton(
      onTap: _toggleSaved,
      child: Icon(
        _isSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        size: heartSize,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildHeroGalleryColumn(List<String> urls) {
    final t = FigmaHantiRiyoTokens.listingDetailGalleryThumb;
    final rad = FigmaHantiRiyoTokens.listingDetailGalleryRadius;
    final bw = FigmaHantiRiyoTokens.listingDetailGalleryBorder;

    void go(int i) {
      if (i >= 0 && i < urls.length) {
        _heroPageController.animateToPage(
          i,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    }

    Widget borderedImage(String u, {Color borderColor = Colors.white, VoidCallback? onTap}) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: t,
          height: t,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(rad),
            border: Border.all(color: borderColor, width: bw),
          ),
          clipBehavior: Clip.antiAlias,
          child: RemoteImage(
            url: u,
            fit: BoxFit.cover,
            errorWidget: Container(color: AppColors.primaryBackground),
          ),
        ),
      );
    }

    final children = <Widget>[];
    if (urls.length > 1) {
      children.add(borderedImage(urls[1], onTap: () => go(1)));
    }
    if (urls.length > 2) {
      children.add(const SizedBox(height: 5));
      children.add(borderedImage(urls[2], onTap: () => go(2)));
    }
    if (urls.length > 3) {
      final showOverlay = urls.length > 4;
      final plus = urls.length - 3;
      children.add(const SizedBox(height: 5));
      children.add(
        GestureDetector(
          onTap: () => go(3),
          child: SizedBox(
            width: t,
            height: t,
            child: Stack(
              fit: StackFit.expand,
              children: [
                borderedImage(urls[3], borderColor: AppColors.greySoft1),
                if (showOverlay)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(rad),
                    child: const ColoredBox(color: FigmaHantiRiyoTokens.listingDetailGalleryMoreOverlay),
                  ),
                if (showOverlay)
                  Center(
                    child: Text(
                      '+$plus',
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: AppColors.greySoft2,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(mainAxisSize: MainAxisSize.min, children: children);
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
        Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
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
    /// Figma `28:4568` / `28:4632` — selected = gold + **white** label; unselected = `#f5f4f8` + **#252b5c** (no faded double-grey).
    final titleC = FigmaHantiRiyoTokens.exploreSearchTextTitle;
    final rentSelected = _effectiveShowRent(data);
    final buySelected = !rentSelected && data.hasSellOption;

    Widget typePill(String label, {required bool selected, required bool enabled, VoidCallback? onTap}) {
      final child = Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 17.5),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.greySoft1,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.lato(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
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
          onTap: data.hasSellOption ? () => setState(() => _listingTypeRentOverride = false) : null,
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: FigmaHantiRiyoTokens.listingDetailAvailableFill,
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
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  letterSpacing: 0.3,
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 50,
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.greySoft1,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Icon(Icons.location_on_outlined, size: 22, color: AppColors.textSecondary),
        ),
        const SizedBox(width: 12),
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

  Widget _buildDistanceRow() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppColors.greySoft2, width: 1.2),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Icon(Icons.place_outlined, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: GoogleFonts.raleway(fontSize: 12, color: FigmaHantiRiyoTokens.exploreSearchTextList),
                children: [
                  TextSpan(
                    text: '2.5 ',
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w700,
                      color: FigmaHantiRiyoTokens.exploreSearchTextTitle,
                    ),
                  ),
                  TextSpan(
                    text: 'km',
                    style: GoogleFonts.raleway(
                      fontWeight: FontWeight.w700,
                      color: FigmaHantiRiyoTokens.exploreSearchTextTitle,
                    ),
                  ),
                  const TextSpan(text: ' from your location'),
                ],
              ),
            ),
          ),
          const Icon(Icons.keyboard_arrow_down_rounded, size: 22, color: AppColors.textSecondary),
        ],
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

  /// **Figma `28:4593`** — real map, custom pin ([`createMapPinDescriptor`]), frosted footer.
  Widget _buildMapCard(BuildContext context, _EstateDetailData data) {
    final target = LatLng(data.mapLat, data.mapLng);
    return ListingDetailMapPreview(
      target: target,
      imageUrl: data.imageUrl,
      height: 235,
      onViewAllTap: () => context.push(AppRoutes.search),
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
            Text(
              'view details',
              style: GoogleFonts.raleway(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: FigmaHantiRiyoTokens.exploreSearchTextClear,
                letterSpacing: 0.3,
              ),
            ),
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
                  fontSize: 9,
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
                        color: FigmaHantiRiyoTokens.exploreSearchTextTitle,
                      ),
                    ),
                  ],
                ),
                if (n > 0) ...[
                  const SizedBox(height: 4),
                  Text.rich(
                    TextSpan(
                      style: GoogleFonts.raleway(
                        fontSize: 9,
                        color: FigmaHantiRiyoTokens.exploreSearchTextList,
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
                      child: Icon(Icons.person_rounded, size: 16, color: AppColors.greyBarelyMedium),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewAllReviewsButton() {
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: Material(
        color: AppColors.greySoft1,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: () {},
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
                        fontSize: 9,
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

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.name, required this.rating, required this.text, required this.date});

  final String name;
  final int rating;
  final String text;
  final String date;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary.withValues(alpha: 0.22),
                child: Text(
                  initial,
                  style: GoogleFonts.raleway(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.raleway(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: FigmaHantiRiyoTokens.exploreSearchTextTitle,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(
                        5,
                        (i) => Padding(
                          padding: const EdgeInsets.only(right: 2),
                          child: Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: i < rating ? AppColors.primary : AppColors.greyBarelyMedium,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                date,
                style: GoogleFonts.lato(fontSize: 12, color: AppColors.greyBarelyMedium),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            text,
            style: GoogleFonts.lato(
              fontSize: 14,
              height: 1.5,
              color: FigmaHantiRiyoTokens.exploreSearchTextList,
            ),
          ),
        ],
      ),
    );
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

  factory _EstateDetailData.fallback(EstateDetailScreen widget) {
    return _EstateDetailData(
      title: widget.title,
      location: widget.location,
      price: widget.price,
      rentPrice: widget.price,
      sellPrice: 250000,
      imageUrl: widget.imageUrl,
      imageUrls: [widget.imageUrl],
      propertyTypeLabel: 'Apartment',
      isRent: true,
      isForSale: true,
      bedrooms: 2,
      bathrooms: 1,
      reviewCount: 112,
      description: widget.description ??
          'Property Overview\nOwnership Type: freehold / leasehold\nLorem ipsum dolor sit amet, consectetur adipiscing elit.',
      facilities: const ['Parking lot', 'Pet Friendly', 'Garden', 'Gym', 'Park', 'Home theatre'],
      agentName: 'Anderson',
      agentAvatarUrl: '',
      rating: 4.9,
      reviews: const [],
      nearby: const [],
      latitude: null,
      longitude: null,
    );
  }

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
    if (bedrooms <= 0) bedrooms = 2;
    var bathrooms = _toInt(data['bathrooms'] ?? data['bathroom_count']);
    if (bathrooms <= 0) bathrooms = 1;

    var propertyTypeLabel = 'Apartment';
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

    final reviewItems = reviews.map(_ReviewItem.fromJson).toList();
    final avgRating = reviewItems.isEmpty
        ? 4.8
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
      facilities: facilities.isEmpty ? const ['Parking lot', 'Pet Friendly'] : facilities,
      agentName: '${userMap['name'] ?? 'Agent'}',
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
  final List<_ReviewItem> reviews;
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

class _ReviewItem {
  const _ReviewItem({
    required this.name,
    required this.rating,
    required this.text,
    required this.dateLabel,
  });

  factory _ReviewItem.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    final userMap = user is Map<String, dynamic> ? user : const <String, dynamic>{};
    final createdAt = DateTime.tryParse('${json['createdAt'] ?? ''}');
    return _ReviewItem(
      name: '${userMap['name'] ?? 'User'}',
      rating: _toInt(json['rating']),
      text: '${json['comment'] ?? ''}',
      dateLabel: _dateLabel(createdAt),
    );
  }

  final String name;
  final int rating;
  final String text;
  final String dateLabel;

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  static String _dateLabel(DateTime? date) {
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inDays >= 1) return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
    if (diff.inHours >= 1) return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    if (diff.inMinutes >= 1) return '${diff.inMinutes} min ago';
    return 'Just now';
  }
}
