import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/figma_tokens.dart';
import '../../../shared/widgets/remote_image.dart';
import '../../profile/utils/profile_avatar_letter.dart';
import '../data/models/listing_review.dart';

/// Single review — **Figma `28:4414`** `Card / Review` / `Card / Review - Estate`.
class ListingReviewListTile extends StatelessWidget {
  const ListingReviewListTile({super.key, required this.review});

  final ListingReview review;

  static const double _avatarSize = 50;
  static const double _avatarRadius = 25;

  @override
  Widget build(BuildContext context) {
    final name = review.name;
    final letter = profileAvatarLetterFromName(name);
    final hasAvatar = review.avatarUrl != null && review.avatarUrl!.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.greySoft1,
        borderRadius: BorderRadius.circular(FigmaHantiRiyoTokens.exploreSearchRadiusLg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: _avatarSize,
            height: _avatarSize,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_avatarRadius),
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(_avatarRadius - 1.5),
                child: hasAvatar
                    ? RemoteImage(
                        url: review.avatarUrl!.trim(),
                        fit: BoxFit.cover,
                        width: _avatarSize,
                        height: _avatarSize,
                        errorWidget: _letterAvatar(letter),
                      )
                    : _letterAvatar(letter),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 9),
                SizedBox(
                  height: 14,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.raleway(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: FigmaHantiRiyoTokens.exploreSearchTextTitle,
                            letterSpacing: 0.36,
                            height: 1,
                          ),
                        ),
                      ),
                      _ReviewStarRow(rating: review.rating, size: 10),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  review.text,
                  style: GoogleFonts.raleway(
                    fontSize: 10,
                    height: 20 / 10,
                    fontWeight: FontWeight.w400,
                    color: FigmaHantiRiyoTokens.exploreSearchTextList,
                    letterSpacing: 0.3,
                  ),
                ),
                if (review.imageUrls.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  _ReviewPhotoGallery(urls: review.imageUrls),
                ],
                if (review.dateLabel.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    review.dateLabel,
                    style: GoogleFonts.montserrat(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      height: 17 / 10,
                      color: AppColors.greyBarelyMedium,
                      letterSpacing: -0.16,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _letterAvatar(String letter) {
    return ColoredBox(
      color: AppColors.greySoft2,
      child: Center(
        child: letter.isEmpty
            ? Icon(Icons.person_rounded, size: 26, color: AppColors.greyBarelyMedium)
            : Text(
                letter,
                style: GoogleFonts.raleway(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
      ),
    );
  }
}

/// Figma `Item / Star - Rating` — compact row (~57×10).
class _ReviewStarRow extends StatelessWidget {
  const _ReviewStarRow({required this.rating, required this.size});

  final int rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    final clamped = rating.clamp(0, 5);
    return SizedBox(
      width: 58,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: List.generate(5, (i) {
          return Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : 1),
            child: Icon(
              Icons.star_rounded,
              size: size,
              color: i < clamped ? AppColors.primary : AppColors.greyBarelyMedium.withValues(alpha: 0.45),
            ),
          );
        }),
      ),
    );
  }
}

class _ReviewPhotoGallery extends StatelessWidget {
  const _ReviewPhotoGallery({required this.urls});

  final List<String> urls;

  @override
  Widget build(BuildContext context) {
    final show = urls.take(3).toList();
    // Use `FigmaHantiRiyoTokens.*` directly — `final t = FigmaHantiRiyoTokens` is invalid (Type, not tokens).
    return Wrap(
      spacing: 5,
      runSpacing: 5,
      children: [
        for (final url in show)
          SizedBox(
            width: FigmaHantiRiyoTokens.listingDetailGalleryThumb,
            height: FigmaHantiRiyoTokens.listingDetailGalleryThumb,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(FigmaHantiRiyoTokens.listingDetailGalleryRadius),
                border: Border.all(
                  color: Colors.white,
                  width: FigmaHantiRiyoTokens.listingDetailGalleryBorder,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  FigmaHantiRiyoTokens.listingDetailGalleryRadius - 1,
                ),
                child: RemoteImage(
                  url: url,
                  fit: BoxFit.cover,
                  width: FigmaHantiRiyoTokens.listingDetailGalleryThumb,
                  height: FigmaHantiRiyoTokens.listingDetailGalleryThumb,
                  errorWidget: ColoredBox(color: AppColors.greySoft2),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
