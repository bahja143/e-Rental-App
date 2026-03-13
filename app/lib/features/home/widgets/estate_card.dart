import 'package:flutter/material.dart';
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
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1F4C6B).withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(18)),
              child: SizedBox(
                width: 126,
                height: 120,
                child: _buildImage(),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 10, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    if (rating != null)
                      Row(
                        children: [
                          const Icon(Icons.star, size: 9, color: AppColors.primary),
                          const SizedBox(width: 2),
                          Text(
                            rating!.toStringAsFixed(1),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.greyMedium,
                                ),
                          ),
                        ],
                      ),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 12, color: AppColors.greyBarelyMedium),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    RichText(
                      text: TextSpan(
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                        children: [
                          TextSpan(text: '\$ ${price.toInt()} '),
                          TextSpan(
                            text: AppStrings.perMonth,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontSize: 6,
                                  color: AppColors.greyMedium,
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
                          child: Container(
                            width: 25,
                            height: 25,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isSaved ? Icons.favorite : Icons.favorite_border,
                              size: 14,
                              color: const Color(0xFFE9678B),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF234F68).withValues(alpha: 0.69),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: RichText(
                            text: TextSpan(
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white),
                              children: [
                                TextSpan(
                                  text: '\$ ${price.toInt()} ',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                                const TextSpan(text: '/month', style: TextStyle(fontSize: 6)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 9, color: AppColors.primary),
                      const SizedBox(width: 2),
                      Text(
                        (rating ?? 4.8).toStringAsFixed(1),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 8,
                              color: AppColors.greyMedium,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.location_on_outlined, size: 9, color: AppColors.greyMedium),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          location,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontSize: 8,
                                color: AppColors.greyMedium,
                              ),
                        ),
                      ),
                    ],
                  ),
                ],
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
