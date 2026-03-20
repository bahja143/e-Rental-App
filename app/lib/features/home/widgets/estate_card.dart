import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../shared/widgets/remote_image.dart';

class EstateCard extends StatelessWidget {
  const EstateCard.horizontal({
    super.key,
    required this.title,
    required this.location,
    required this.price,
    required this.imageUrl,
    this.rating,
    this.onTap,
    this.isSaved = false,
    this.onToggleSaved,
    this.highlighted = false,
    this.category,
    this.fullWidth = false,
    this.compact = false,
    this.withBlur = false,
  }) : isHorizontal = true;

  /// When true, card expands to fill available width (Figma 19-1794 list layout).
  final bool fullWidth;

  /// When true, uses 120px height (Figma 21-3695 Explore cards).
  final bool compact;

  /// When true, uses backdrop blur + semi-transparent white (Figma 21-3695).
  final bool withBlur;

  const EstateCard.vertical({
    super.key,
    required this.title,
    required this.location,
    required this.price,
    required this.imageUrl,
    this.rating,
    this.onTap,
    this.isSaved = false,
    this.onToggleSaved,
    this.highlighted = false,
    this.category,
  })  : isHorizontal = false,
        fullWidth = false,
        compact = false,
        withBlur = false;

  final String title;
  final String location;
  final double price;
  final String imageUrl;
  final double? rating;
  final VoidCallback? onTap;
  final bool isSaved;
  final VoidCallback? onToggleSaved;
  final bool isHorizontal;
  final bool highlighted;
  final String? category;

  @override
  Widget build(BuildContext context) {
    if (isHorizontal) {
      return _buildHorizontal(context);
    }
    return _buildVertical(context);
  }

  Widget _buildHorizontal(BuildContext context) {
    final h = compact ? 120.0 : 156.0;
    final imgW = fullWidth ? 168.0 : (compact ? 126.0 : 134.0);
    final imgH = fullWidth ? 140.0 : (compact ? 104.0 : h); // Figma 21-3695: image 126x104 in 120px card
    final contentPadding = compact ? const EdgeInsets.fromLTRB(14, 12, 10, 12) : const EdgeInsets.fromLTRB(16, 16, 10, 21);
    final decoration = BoxDecoration(
      color: withBlur ? Colors.white.withValues(alpha: 0.8) : AppColors.greySoft1,
      borderRadius: BorderRadius.circular(25),
      boxShadow: withBlur
          ? [BoxShadow(color: AppColors.textSecondary.withValues(alpha: 0.5), blurRadius: 80, offset: const Offset(0, 17))]
          : null,
    );
    Widget card = Container(
        width: fullWidth ? double.infinity : 268,
        height: h,
        decoration: decoration,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: (fullWidth || compact) ? const EdgeInsets.fromLTRB(8, 8, 0, 8) : EdgeInsets.zero,
              child: ClipRRect(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(25)),
                child: SizedBox(
                width: imgW,
                height: imgH,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned.fill(child: _buildImage()),
                    if (category != null && category!.isNotEmpty)
                      Positioned(
                        left: fullWidth ? 8 : 20,
                        bottom: fullWidth ? 8 : 6,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: fullWidth ? 7 : 7,
                                vertical: fullWidth ? 7 : 7,
                              ),
                              decoration: BoxDecoration(
                                color: fullWidth
                                    ? AppColors.primaryBackground.withValues(alpha: 0.67)
                                    : AppColors.categoryActive,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                category!,
                                style: GoogleFonts.raleway(
                                  fontSize: fullWidth ? 8 : 10,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                  letterSpacing: 0.24,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (onToggleSaved != null)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: GestureDetector(
                          onTap: onToggleSaved,
                          child: Container(
                            width: 25,
                            height: 25,
                            decoration: BoxDecoration(
                              color: compact ? Colors.white : AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isSaved ? Icons.favorite : Icons.favorite_border,
                              size: 14,
                              color: compact ? AppColors.primary : Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
            Expanded(
              child: Padding(
                padding: contentPadding,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.raleway(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              letterSpacing: 0.36,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, size: 9, color: AppColors.primary),
                              const SizedBox(width: 2),
                              Text(
                                (rating ?? 0).toStringAsFixed(1),
                                style: GoogleFonts.montserrat(
                                  fontSize: compact ? 8 : 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.greyMedium,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.location_on_outlined, size: 9, color: AppColors.greyMedium),
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text(
                                  location,
                                  style: GoogleFonts.raleway(
                                    fontSize: compact ? 8 : 10,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.greyMedium,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (!compact)
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '\$ ${price.toInt()} ',
                                style: GoogleFonts.montserrat(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                  letterSpacing: 0.48,
                                ),
                              ),
                              TextSpan(
                                text: AppStrings.perMonth,
                                style: GoogleFonts.montserrat(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
                                  letterSpacing: 0.24,
                                  height: 1.625,
                                ),
                              ),
                            ],
                          ),
                        ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    if (withBlur) {
      card = ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: card,
        ),
      );
    }
    return GestureDetector(onTap: onTap, child: card);
  }

  Widget _buildVertical(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.greySoft1,
          borderRadius: BorderRadius.circular(25),
          border: highlighted ? Border.all(color: AppColors.primary, width: 1.2) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: SizedBox(
                  height: 160,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      Positioned.fill(child: _buildImage()),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: onToggleSaved,
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            width: 25,
                            height: 25,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isSaved ? Icons.favorite : Icons.favorite_border,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.categoryActive.withValues(alpha: 0.69),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '\$ ${price.toInt()} ',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                        letterSpacing: 0.36,
                                      ),
                                    ),
                                    TextSpan(
                                      text: AppStrings.perMonth,
                                      style: GoogleFonts.montserrat(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.greySoft1,
                                        letterSpacing: 0.18,
                                        height: 1.67,
                                      ),
                                    ),
                                  ],
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.raleway(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.36,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.star, size: 9, color: AppColors.primary),
                            const SizedBox(width: 2),
                            Text(
                              (rating ?? 4.8).toStringAsFixed(1),
                              style: GoogleFonts.montserrat(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.greyMedium,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.location_on_outlined, size: 9, color: AppColors.greyMedium),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.raleway(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.greyMedium,
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
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    return RemoteImage(
      url: imageUrl,
      fit: BoxFit.cover,
      placeholder: Container(
        color: AppColors.greySoft1,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      errorWidget: Container(
        color: AppColors.greySoft1,
        child: const Icon(Icons.home_work, color: AppColors.greyBarelyMedium),
      ),
    );
  }
}
