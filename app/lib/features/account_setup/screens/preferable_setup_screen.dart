import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/router/app_routes.dart';
import '../widgets/account_success_sheet.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../data/repositories/account_setup_repository.dart';
import '../../onboarding/data/onboarding_session.dart';
import '../../onboarding/data/pending_profile_image.dart';
import '../../onboarding/data/google_sign_in_pending.dart';
import '../../auth/data/models/register_request.dart';
import '../../auth/data/repositories/auth_repository.dart';
import '../../../shared/widgets/app_button.dart';

/// Account Setup / Preferable - Figma 11:1286 "Select your preferable real estate type"
class PreferableSetupScreen extends StatefulWidget {
  const PreferableSetupScreen({super.key});

  @override
  State<PreferableSetupScreen> createState() => _PreferableSetupScreenState();
}

class _PreferableSetupScreenState extends State<PreferableSetupScreen> {
  late final Set<String> _selectedTypes;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = OnboardingSession.data?.propertyTypes ?? [];
    _selectedTypes = Set.from(existing);
  }

  // Figma 11:1287 - Estates Card / Vertical - Category (local estate card images)
  static const _categories = [
    _EstateCategory('Apartment', 'assets/images/Estates Card/1.png'),
    _EstateCategory('Villa', 'assets/images/Estates Card/2.png'),
    _EstateCategory('House', 'assets/images/Estates Card/3.png'),
    _EstateCategory('Cottage', 'assets/images/Estates Card/4.png'),
  ];

  void _goBack() {
    final data = OnboardingSession.data;
    if (data != null && _selectedTypes.isNotEmpty) {
      OnboardingSession.set(data.copyWith(propertyTypes: _selectedTypes.toList()));
    }
    if (context.canPop()) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goBack();
      },
      child: Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildTitle(),
                    const SizedBox(height: 20),
                    _buildSubtitle(),
                    const SizedBox(height: 30),
                    _buildCategoryGrid(),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
            _buildNextButton(context),
          ],
        ),
      ),
    ),
    );
  }

  /// Figma 11:1301 – Header with back button only (Skip removed)
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: GestureDetector(
        onTap: _goBack,
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.greySoft1,
            borderRadius: BorderRadius.circular(25),
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.textPrimary),
        ),
      ),
    ),
    );
  }

  /// Figma 11:1298 - Title: Lato Medium 25px + ExtraBold for "real estate type"
  Widget _buildTitle() {
    return RichText(
      text: TextSpan(
        style: GoogleFonts.lato(
          fontSize: 25,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
          letterSpacing: 0.75,
          height: 1.6,
        ),
        children: [
          const TextSpan(text: 'Select your preferable\n'),
          TextSpan(
            text: 'real estate type',
            style: GoogleFonts.lato(
              fontSize: 25,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
              letterSpacing: 0.75,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  /// Figma 11:1300 - Subtitle: 14px, #53587a, leading 20
  Widget _buildSubtitle() {
    return Text(
      'You can edit this later on your account setting.',
      style: GoogleFonts.raleway(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.greyMedium,
        letterSpacing: 0.42,
        height: 1.25,
      ),
    );
  }

  /// Figma 11:1287 - Data List: cards 160x212, horizontal gap 7, vertical gap 10
  Widget _buildCategoryGrid() {
    const cardWidth = 160.0;
    const cardHeight = 212.0;
    const hGap = 7.0;
    const vGap = 10.0;
    return Wrap(
      spacing: hGap,
      runSpacing: vGap,
      children: _categories.map((cat) {
        final isSelected = _selectedTypes.contains(cat.name);
        return SizedBox(
          width: cardWidth,
          height: cardHeight,
          child: _EstateCard(
            category: cat,
            selected: isSelected,
            onTap: () => setState(() {
              if (isSelected) {
                _selectedTypes.remove(cat.name);
              } else {
                _selectedTypes.add(cat.name);
              }
            }),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNextButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        width: double.infinity,
        height: 63,
        child: AppButton(
          label: _saving ? 'Creating account...' : 'Finish',
          isLoading: _saving,
          onPressed: _saving ? null : _onFinish,
        ),
      ),
    );
  }

  Future<void> _onFinish() async {
    if (_selectedTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one property type.')),
      );
      return;
    }

      final data = OnboardingSession.data;
    if (data != null) {
      OnboardingSession.set(data.copyWith(propertyTypes: _selectedTypes.toList()));

      setState(() => _saving = true);

      // Try to get device location for the user record (optional)
      double? lat;
      double? lng;
      try {
        final enabled = await Geolocator.isLocationServiceEnabled();
        if (enabled) {
          var permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }
          if (permission == LocationPermission.whileInUse ||
              permission == LocationPermission.always) {
            final position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.medium,
            );
            lat = position.latitude;
            lng = position.longitude;
          }
        }
      } catch (_) {
        // Continue without location
      }

      String? profilePictureUrl;
      // Google flow: use stored photo from GoogleSignInPending (avoids URL encoding issues)
      if (GoogleSignInPending.hasData && GoogleSignInPending.photoUrl != null && GoogleSignInPending.photoUrl!.isNotEmpty) {
        profilePictureUrl = GoogleSignInPending.photoUrl;
      }
      if (profilePictureUrl == null && data.profilePictureUrl != null && data.profilePictureUrl!.isNotEmpty) {
        profilePictureUrl = data.profilePictureUrl;
      }
      debugPrint('[Preferable] profilePictureUrl (Google/OnboardingData): $profilePictureUrl');
      final pendingPath = PendingProfileImage.path;
      if (pendingPath != null) {
        final file = File(pendingPath);
        if (await file.exists()) {
          try {
            final res = await ApiClient().postMultipartFile('/upload/profile-image', file);
            final url = res['url']?.toString();
            if (url != null && url.isNotEmpty) {
              profilePictureUrl = url;
              debugPrint('[Preferable] Uploaded profile image URL: $url');
            } else {
              debugPrint('[Preferable] Upload response missing url: $res');
            }
          } catch (e) {
            debugPrint('[Preferable] Profile image upload failed: $e');
          }
          PendingProfileImage.clear();
        } else {
          PendingProfileImage.clear();
        }
      }

      debugPrint('[Preferable] Final profilePictureUrl sent: $profilePictureUrl');
      final result = GoogleSignInPending.hasData
          ? await AuthRepository().registerWithGoogleComplete(
              name: data.name,
              email: data.email,
              phone: data.phone,
              idToken: GoogleSignInPending.idToken!,
              profilePictureUrl: profilePictureUrl,
              preferredPropertyTypes: _selectedTypes.toList(),
              lookingForOptions: data.lookingForList.isNotEmpty ? data.lookingForList : null,
              lat: lat,
              lng: lng,
            )
          : await AuthRepository().registerWithGeneratedPasswordEx(
              RegisterRequest(
                name: data.name,
                email: data.email,
                password: '',
                phone: data.phone,
                preferredPropertyTypes: _selectedTypes.toList(),
                lookingForOptions: data.lookingForList.isNotEmpty ? data.lookingForList : null,
                city: null,
                lat: lat,
                lng: lng,
                lookingFor: data.lookingFor,
                lookingForSet: true,
                categorySet: true,
              ),
              profilePictureUrl: profilePictureUrl,
            );

      if (!mounted) return;
      setState(() => _saving = false);

      if (result.ok) {
        OnboardingSession.clear();
        GoogleSignInPending.clear();
        _showSuccessModal(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.errorMessage ?? 'Could not create account. Please try again.')),
        );
      }
      return;
    }

    // Non-onboarding: save preferences and go home
    setState(() => _saving = true);
    final ok = await AccountSetupRepository().savePreferences(_selectedTypes.toList());
    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      context.go(AppRoutes.home);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save. Please try again.')),
      );
    }
  }

  void _showSuccessModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => const AccountSuccessSheet(),
    );
  }
}

class _EstateCategory {
  const _EstateCategory(this.name, this.imagePath);
  final String name;
  final String imagePath;
}

/// Figma 11:1288–1293 - Estates Card / Vertical - Category
class _EstateCard extends StatelessWidget {
  const _EstateCard({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final _EstateCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        height: 212,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1F4C6B) : AppColors.greySoft1,
          borderRadius: BorderRadius.circular(25),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 168,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            category.imagePath,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: AppColors.greySoft2,
                              child: Icon(
                                Icons.home_outlined,
                                size: 48,
                                color: AppColors.greyBarelyMedium,
                              ),
                            ),
                          ),
                          if (selected)
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF884AF6).withOpacity(0.08),
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 0,
                      top: 0,
                      child: Container(
                        width: 25,
                        height: 25,
                        decoration: BoxDecoration(
                          color: selected ? AppColors.primary : Colors.white.withOpacity(0.8),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected ? AppColors.primary : AppColors.greyBarelyMedium,
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          Icons.check,
                          size: 14,
                          color: selected ? Colors.white : AppColors.textPrimary.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  category.name,
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : AppColors.textPrimary,
                    letterSpacing: 0.36,
                    height: 1.5,
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
