import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../shared/widgets/remote_image.dart';

/// Welcome screen - Gallery grid with Hanti riyo branding
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const _galleryImages = [
    'https://www.figma.com/api/mcp/asset/bd70a21c-4edb-4be6-b9d2-5b8786ade89f',
    'https://www.figma.com/api/mcp/asset/f6336f56-9c07-4ab4-bc1e-b9f5161cc274',
    'https://www.figma.com/api/mcp/asset/f3ff4ce6-9313-46d5-8262-988ec9f81995',
    'https://www.figma.com/api/mcp/asset/91ec2421-d5ab-452c-a2ef-6c111dde0060',
    'https://www.figma.com/api/mcp/asset/a6931cf4-c208-4b9e-88d9-22c336703645',
    'https://www.figma.com/api/mcp/asset/e0ff126b-be63-4a95-8e72-0a2da95d2c38',
    'https://www.figma.com/api/mcp/asset/db348b35-ef2c-417a-90e6-98162ef4c22a',
    'https://www.figma.com/api/mcp/asset/5482ee66-ac02-46fa-8f1c-0066b7150b68',
    'https://www.figma.com/api/mcp/asset/c4d7a3f2-b7f3-4869-97e2-a6cb2ad5782c',
  ];
  static const _centerLogo = 'https://www.figma.com/api/mcp/asset/091f3a32-c97f-4577-b815-0c232056e811';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: GestureDetector(
        onTap: () => context.go(AppRoutes.choice),
        child: Stack(
          children: [
            _buildGallery(context),
            _buildOverlay(),
            const Positioned(
              left: -17,
              top: 148,
              width: 409,
              height: 358,
              child: IgnorePointer(
                child: RemoteImage(
                  url: _centerLogo,
                  fit: BoxFit.contain,
                  errorWidget: SizedBox.shrink(),
                ),
              ),
            ),
            _buildContent(context),
          ],
        ),
      ),
    );
  }

  Widget _buildGallery(BuildContext context) {
    return Positioned(
      top: 60,
      left: 15,
      right: 15,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(3, (col) {
          return Expanded(
            child: Column(
              children: List.generate(3, (row) {
                final idx = col * 3 + row;
                if (idx >= _galleryImages.length) return const SizedBox.shrink();
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: row < 2 ? 9 : 0,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: AspectRatio(
                      aspectRatio: 109 / (row == 0 ? 130 : row == 1 ? 140 : 175),
                      child: RemoteImage(
                        url: _galleryImages[idx],
                        fit: BoxFit.cover,
                        placeholder: Container(
                          color: AppColors.greySoft1,
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: Container(
                          color: AppColors.greySoft1,
                          child: const Icon(Icons.home_work, color: AppColors.greyBarelyMedium),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildOverlay() {
    return Positioned(
      top: 44,
      left: 0,
      right: 0,
      height: 524,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.88),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        height: 244,
        padding: const EdgeInsets.fromLTRB(24, 30, 24, 64),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(50)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppStrings.welcome,
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: AppColors.textAccent.withValues(alpha: 0.8),
                    fontSize: 32,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.tagline,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.greyMedium,
                    fontSize: 16,
                    height: 1.5,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
