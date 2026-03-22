import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/figma_tokens.dart';
import '../../../shared/widgets/remote_image.dart';
import '../data/models/estate_item.dart';
import '../data/models/listing_review.dart';
import '../data/repositories/estate_repository.dart';
import '../widgets/listing_review_tile.dart';

/// All reviews for a listing — **Figma `28:4414`** (`Detail / Reviews`).
class ListingReviewsScreen extends StatefulWidget {
  const ListingReviewsScreen({
    super.key,
    required this.estateId,
    this.listingTitle,
  });

  final String estateId;
  final String? listingTitle;

  @override
  State<ListingReviewsScreen> createState() => _ListingReviewsScreenState();
}

class _ListingReviewsScreenState extends State<ListingReviewsScreen> {
  final _repo = EstateRepository();
  late final Future<_ReviewsPageData> _pageFuture;
  /// `null` = **All** (Figma `Button / Category - Rounded - Active` “All”).
  int? _starFilter;

  @override
  void initState() {
    super.initState();
    _pageFuture = _load();
  }

  Future<_ReviewsPageData> _load() async {
    final raw = await _repo.getListingReviews(widget.estateId);
    final reviews = raw.map(ListingReview.fromJson).toList();
    final listing = await _repo.getEstateItemById(widget.estateId);
    return _ReviewsPageData(reviews: reviews, listing: listing);
  }

  List<ListingReview> _filtered(List<ListingReview> all) {
    final f = _starFilter;
    if (f == null) return all;
    return all.where((r) => r.rating == f).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FutureBuilder<_ReviewsPageData>(
          future: _pageFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            }
            final data = snapshot.data ?? const _ReviewsPageData(reviews: [], listing: null);
            final filtered = _filtered(data.reviews);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ReviewsHeader(onBack: () => context.pop()),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                    children: [
                      _ListingReviewsSummaryCard(
                        listing: data.listing,
                        titleFallback: widget.listingTitle,
                        ratingFromReviews: data.averageRatingFromReviews,
                      ),
                      const SizedBox(height: 20),
                      _RatingFilterChips(
                        selectedStars: _starFilter,
                        onSelectAll: () => setState(() => _starFilter = null),
                        onSelectStars: (n) => setState(() => _starFilter = n),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'User reviews',
                        style: GoogleFonts.raleway(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: FigmaHantiRiyoTokens.exploreSearchTextTitle,
                          letterSpacing: 0.54,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (data.reviews.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: Text(
                              'No reviews yet.',
                              style: GoogleFonts.lato(fontSize: 14, color: AppColors.greyBarelyMedium),
                            ),
                          ),
                        )
                      else if (filtered.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              'No reviews with this rating.',
                              style: GoogleFonts.lato(fontSize: 14, color: AppColors.greyBarelyMedium),
                            ),
                          ),
                        )
                      else
                        ...filtered.map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: ListingReviewListTile(review: e),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ReviewsPageData {
  const _ReviewsPageData({required this.reviews, this.listing});

  final List<ListingReview> reviews;
  final EstateItem? listing;

  /// When listing has no API rating, use average from loaded reviews (Figma `28:4428` always shows stars).
  double get averageRatingFromReviews {
    if (reviews.isEmpty) return 4.9;
    final sum = reviews.fold<double>(0, (a, r) => a + r.rating.clamp(0, 5));
    return sum / reviews.length;
  }
}

/// Figma `Header` — centered **Reviews**, `Button / Back - Solid` 50×50.
class _ReviewsHeader extends StatelessWidget {
  const _ReviewsHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final s = FigmaHantiRiyoTokens.listingDetailToolbarSize;
    final r = FigmaHantiRiyoTokens.listingDetailToolbarRadius;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      child: SizedBox(
        height: s + 8,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              'Reviews',
              style: GoogleFonts.raleway(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: FigmaHantiRiyoTokens.exploreSearchTextTitle,
                letterSpacing: 0.54,
                height: 1,
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onBack,
                  borderRadius: BorderRadius.circular(r),
                  child: Container(
                    width: s,
                    height: s,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: FigmaHantiRiyoTokens.listingDetailShareFill,
                      borderRadius: BorderRadius.circular(r),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Figma `28:4428` — **Estates Card / Wide - Full** (blurred soft card + thumb + meta).
class _ListingReviewsSummaryCard extends StatelessWidget {
  const _ListingReviewsSummaryCard({
    required this.listing,
    this.titleFallback,
    required this.ratingFromReviews,
  });

  final EstateItem? listing;
  final String? titleFallback;
  final double ratingFromReviews;

  @override
  Widget build(BuildContext context) {
    final title = (listing?.title ?? titleFallback ?? 'Listing').trim();
    if (title.isEmpty) return const SizedBox.shrink();

    final category = listing?.displayCategory ?? 'Apartment';
    final loc = (listing?.location ?? '').trim();
    final rating = listing?.rating ?? ratingFromReviews;
    final imageUrl = listing?.imageUrl ?? '';
    final hasImage = imageUrl.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          height: 120,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.greySoft1.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 168,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    height: 104,
                    width: 160,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: hasImage
                                ? Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      RemoteImage(
                                        url: imageUrl,
                                        fit: BoxFit.cover,
                                        errorWidget: ColoredBox(color: AppColors.greySoft2),
                                      ),
                                      ColoredBox(
                                        color: FigmaHantiRiyoTokens.exploreSearchThumbOverlay,
                                      ),
                                    ],
                                  )
                                : ColoredBox(color: AppColors.greySoft2),
                          ),
                        ),
                        Positioned(
                          left: 8,
                          top: 8,
                          child: Container(
                            width: 25,
                            height: 25,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.favorite_border_rounded,
                              size: 14,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 8,
                          bottom: 8,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
                                decoration: BoxDecoration(
                                  color: FigmaHantiRiyoTokens.listingDetailHeroPillFill,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  category,
                                  style: GoogleFonts.raleway(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.greySoft1,
                                    letterSpacing: 0.24,
                                    height: 1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12, right: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Builder(
                        builder: (context) {
                          final showSecondLine =
                              !title.toLowerCase().contains(category.toLowerCase());
                          return Text(
                            showSecondLine ? '$title\n$category' : title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.raleway(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              height: 18 / 12,
                              color: FigmaHantiRiyoTokens.exploreSearchTextTitle,
                              letterSpacing: 0.36,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.star_rounded, size: 9, color: AppColors.primary),
                          const SizedBox(width: 2),
                          Text(
                            rating.toStringAsFixed(1),
                            style: GoogleFonts.montserrat(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: FigmaHantiRiyoTokens.exploreSearchTextList,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                      if (loc.isNotEmpty) const SizedBox(height: 8),
                      if (loc.isNotEmpty)
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 11,
                              color: FigmaHantiRiyoTokens.exploreSearchTextList,
                            ),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                loc,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.raleway(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w400,
                                  color: FigmaHantiRiyoTokens.exploreSearchTextList,
                                  height: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
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
}

/// Figma `28:4422` **Rating Category** — ⭐ All + ⭐ 1…5.
class _RatingFilterChips extends StatelessWidget {
  const _RatingFilterChips({
    required this.selectedStars,
    required this.onSelectAll,
    required this.onSelectStars,
  });

  final int? selectedStars;
  final VoidCallback onSelectAll;
  final void Function(int stars) onSelectStars;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            active: selectedStars == null,
            starEmoji: true,
            label: 'All',
            labelMontserratWeight: FontWeight.w700,
            onTap: onSelectAll,
          ),
          for (var n = 1; n <= 5; n++) ...[
            const SizedBox(width: 10),
            _FilterChip(
              active: selectedStars == n,
              starEmoji: true,
              label: '$n',
              labelMontserratWeight: FontWeight.w500,
              onTap: () => onSelectStars(n),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.active,
    required this.starEmoji,
    required this.label,
    required this.labelMontserratWeight,
    required this.onTap,
  });

  final bool active;
  final bool starEmoji;
  final String label;
  final FontWeight labelMontserratWeight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = active ? AppColors.textSecondary : AppColors.greySoft1;
    final labelColor = active ? AppColors.greySoft1 : FigmaHantiRiyoTokens.exploreSearchTextTitle;
    final starColor = FigmaHantiRiyoTokens.exploreSearchTextTitle;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 17.5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (starEmoji)
                  Text(
                    '⭐',
                    style: GoogleFonts.raleway(
                      fontSize: 15,
                      height: 15 / 15,
                      color: starColor,
                      letterSpacing: 0.45,
                    ),
                  ),
                if (starEmoji) const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    fontWeight: labelMontserratWeight,
                    color: labelColor,
                    letterSpacing: 0.3,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
