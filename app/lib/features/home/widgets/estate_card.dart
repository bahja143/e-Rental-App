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
  }) : isHorizontal = true;

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
  }) : isHorizontal = false;

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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 268,
        height: 156,
        decoration: BoxDecoration(
          color: AppColors.greySoft1,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(25)),
              child: SizedBox(
                width: 134,
                height: 156,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned.fill(child: _buildImage()),
                    if (category != null && category!.isNotEmpty)
                      Positioned(
                        left: 20,
                        bottom: 6,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
                              decoration: BoxDecoration(
                                color: AppColors.categoryActive,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                category!,
                                style: GoogleFonts.raleway(
                                  fontSize: 10,
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
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 10, 21),
                child: Column(
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
                        if (rating != null)
                          Row(
                            children: [
                              const Icon(Icons.star, size: 9, color: AppColors.primary),
                              const SizedBox(width: 2),
                              Text(
                                rating!.toStringAsFixed(1),
                                style: GoogleFonts.montserrat(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.greyMedium,
                                ),
                              ),
                            ],
                          ),
                        if (rating != null) const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 9, color: AppColors.greyMedium),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                location,
                                style: GoogleFonts.raleway(
                                  fontSize: 10,
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
      ),
    );
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
