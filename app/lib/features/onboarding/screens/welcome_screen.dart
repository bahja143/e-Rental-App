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
    'assets/images/welcome/Image (1).png',
    'assets/images/welcome/Image (2).png',
    'assets/images/welcome/Image (3).png',
    'assets/images/welcome/Image (4).png',
    'assets/images/welcome/Image (5).png',
    'assets/images/welcome/Image (6).png',
    'assets/images/welcome/Image (7).png',
    'assets/images/welcome/Image (8).png',
    'assets/images/welcome/Image (9).png',
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
    return BackButtonListener(
      onBackButtonPressed: _handleBackButton,
      child: Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
          children: [
            _buildGallery(context),
            _buildOverlay(),
            Positioned(
              left: -17,
              top: 148,
              width: 409,
              height: 358,
                    child: IgnorePointer(
                child: Image.asset(
                  _centerLogo,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
            _buildContent(context),
          ],
        ),
    ),
    );
  }

  /// Figma 2063-10310 Gallery: 3 columns, 9px gap, 109px width per cell
  static const _gap = 9.0;
  static const _figmaWidth = 109.0;

  /// Per Figma: Column (col) contains 3 cells with heights [h0, h1, h2]. Aspect = width/height.
  static double _cellAspectRatio(int col, int row) {
    const heights = [
      [130.0, 140.0, 175.0], // column 0: image1, image2, image3
      [175.0, 130.0, 140.0], // column 1: image4, image5, image6
      [175.0, 140.0, 175.0], // column 2: image7, image8, image9
    ];
    return _figmaWidth / heights[col][row];
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
                            child: const Icon(Icons.home_work, color: AppColors.greyBarelyMedium),
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
              Colors.black.withValues(alpha: 0.95),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        height: 260 + bottomPadding,
        padding: EdgeInsets.fromLTRB(24, 30, 24, 24 + bottomPadding),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
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
      ),
    );
  }
}
