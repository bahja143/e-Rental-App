import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../shared/widgets/app_button.dart';

/// Welcome screen - Gallery grid with Hanti riyo branding
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  /// Local gallery images: row1 image1-3, row2 image4-6, row3 image7-9
  static const _galleryImages = [
    'assets/images/realistic_images/WhatsApp Image 2026-04-08 at 1.21.45 AM (1).jpeg',
    'assets/images/realistic_images/WhatsApp Image 2026-04-08 at 1.21.47 AM.jpeg',
    'assets/images/realistic_images/WhatsApp Image 2026-04-08 at 1.21.49 AM.jpeg',
    'assets/images/realistic_images/WhatsApp Image 2026-04-08 at 1.21.50 AM (1).jpeg',
    'assets/images/realistic_images/WhatsApp Image 2026-04-08 at 1.21.51 AM (1).jpeg',
    'assets/images/realistic_images/WhatsApp Image 2026-04-08 at 1.21.51 AM.jpeg',
    'assets/images/realistic_images/WhatsApp Image 2026-04-08 at 1.21.52 AM (1).jpeg',
    'assets/images/realistic_images/WhatsApp Image 2026-04-08 at 1.21.52 AM.jpeg',
    'assets/images/realistic_images/WhatsApp Image 2026-04-08 at 1.21.53 AM (1).jpeg',
  ];
  static const _centerLogo = 'assets/images/logo.png';

  void _showExitModal() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.greySoft1,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.greySoft2, width: 1),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  size: 28,
                  color: AppColors.greyMedium,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Exit app',
                style: GoogleFonts.lato(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to exit the app?',
                textAlign: TextAlign.center,
                style: GoogleFonts.raleway(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: AppColors.greyMedium,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.greySoft1,
                          foregroundColor: AppColors.textPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          SystemNavigator.pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Exit'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _handleBackButton() async {
    _showExitModal();
    return true; // Prevent default exit
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return BackButtonListener(
      onBackButtonPressed: _handleBackButton,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final bottomPadding = mediaQuery.padding.bottom;
            final heroHeight = constraints.maxHeight - _contentHeight(constraints.maxHeight, bottomPadding);

            return Column(
              children: [
                SizedBox(
                  height: heroHeight,
                  child: _buildHero(
                    context,
                    safeTop: mediaQuery.padding.top,
                  ),
                ),
                _buildContent(
                  context,
                  bottomPadding: bottomPadding,
                  height: constraints.maxHeight - heroHeight,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Figma 2063-10310 Gallery: 3 columns, 9px gap, 109px width per cell
  static const _gap = 9.0;
  static const _figmaWidth = 109.0;
  static const _contentMinHeight = 220.0;
  static const _contentMaxHeight = 300.0;

  /// Per Figma: Column (col) contains 3 cells with heights [h0, h1, h2]. Aspect = width/height.
  static double _cellAspectRatio(int col, int row) {
    const heights = [
      [130.0, 140.0, 175.0], // column 0: image1, image2, image3
      [175.0, 130.0, 140.0], // column 1: image4, image5, image6
      [175.0, 140.0, 175.0], // column 2: image7, image8, image9
    ];
    return _figmaWidth / heights[col][row];
  }

  double _contentHeight(double screenHeight, double bottomPadding) {
    final responsiveHeight = screenHeight * 0.34;
    return responsiveHeight.clamp(_contentMinHeight, _contentMaxHeight).toDouble() + bottomPadding;
  }

  double _galleryHeightForTileWidth(double tileWidth) {
    final columnHeights = List.generate(3, (col) {
      final imageHeights = List.generate(
        3,
        (row) => tileWidth / _cellAspectRatio(col, row),
      ).fold<double>(0, (sum, height) => sum + height);
      return imageHeights + (_gap * 2);
    });

    return columnHeights.reduce(math.max);
  }

  Widget _buildHero(BuildContext context, {required double safeTop}) {
    return ClipRect(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final galleryWidth = constraints.maxWidth - 30;
          final tileWidth = (galleryWidth - (_gap * 2)) / 3;
          final galleryHeight = _galleryHeightForTileWidth(tileWidth);
          final galleryTop = math.max(
            safeTop + 12,
            constraints.maxHeight - galleryHeight - 18,
          );
          final logoWidth = math.min(constraints.maxWidth * 0.78, 300.0);

          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                top: galleryTop,
                left: 15,
                right: 15,
                child: _buildGalleryGrid(),
              ),
              _buildOverlay(),
              Align(
                alignment: const Alignment(0, -0.08),
                child: IgnorePointer(
                  child: SizedBox(
                    width: logoWidth,
                    child: AspectRatio(
                      aspectRatio: 375 / 358,
                      child: Image.asset(
                        _centerLogo,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGalleryGrid() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(3, (col) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: col < 2 ? _gap : 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (row) {
                final idx = col * 3 + row;
                if (idx >= _galleryImages.length) return const SizedBox.shrink();
                return Padding(
                  padding: EdgeInsets.only(bottom: row < 2 ? _gap : 0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: AspectRatio(
                      aspectRatio: _cellAspectRatio(col, row),
                      child: Image.asset(
                        _galleryImages[idx],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppColors.greySoft1,
                          child: const Icon(
                            Icons.home_work,
                            color: AppColors.greyBarelyMedium,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildOverlay() {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.95),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context, {
    required double bottomPadding,
    required double height,
  }) {
    return Container(
      height: height,
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24, 30, 24, 24 + bottomPadding),
      decoration: const BoxDecoration(
        color: AppColors.background,
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppStrings.welcome,
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                color: AppColors.textAccent.withValues(alpha: 1),
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
            const SizedBox(height: 24),
            AppButton(
              label: 'Continue',
              onPressed: () => context.push(AppRoutes.loginOption),
            ),
          ],
        ),
      ),
    );
  }
}
