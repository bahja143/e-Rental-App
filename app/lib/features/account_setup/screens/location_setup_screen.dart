import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../data/repositories/account_setup_repository.dart';
import '../widgets/account_success_sheet.dart';
import '../../../shared/widgets/app_button.dart';
import '../../auth/data/models/register_request.dart';
import '../../auth/data/repositories/auth_repository.dart';
import '../../onboarding/data/onboarding_session.dart';

/// Account Setup / Location - Get current location in background, Finish to create account
class LocationSetupScreen extends StatefulWidget {
  const LocationSetupScreen({super.key});

  @override
  State<LocationSetupScreen> createState() => _LocationSetupScreenState();
}

class _LocationSetupScreenState extends State<LocationSetupScreen> {
  bool _saving = false;
  double? _lat;
  double? _lng;

  @override
  void initState() {
    super.initState();
    _getCurrentLocationInBackground();
  }

  /// Fetch location silently in background; no UI blocking
  Future<void> _getCurrentLocationInBackground() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse &&
            permission != LocationPermission.always) {
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      if (!mounted) return;
      setState(() {
        _lat = position.latitude;
        _lng = position.longitude;
      });
    } catch (_) {
      // Silently ignore; account can be created without location
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    const SizedBox(height: 40),
                    _buildTitle(),
                    const SizedBox(height: 12),
                    _buildSubtitle(),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
            _buildFinishButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: GestureDetector(
        onTap: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(AppRoutes.accountSetupPreferable);
          }
        },
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

  Widget _buildTitle() {
    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.displayMedium?.copyWith(
          fontSize: 25,
          color: AppColors.textPrimary,
          height: 1.6,
        ),
        children: const [
          TextSpan(text: 'Where are you '),
          TextSpan(
            text: 'based?',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtitle() {
    return Text(
      'We\'ll use this to show you relevant properties.',
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontSize: 14,
        color: AppColors.greyMedium,
      ),
    );
  }

  Widget _buildFinishButton(BuildContext context) {
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
    final data = OnboardingSession.data;
    if (data != null) {
      setState(() => _saving = true);

      final request = RegisterRequest(
        name: data.name,
        email: data.email,
        password: '',
        phone: data.phone,
        preferredPropertyTypes: data.propertyTypes.isNotEmpty ? data.propertyTypes : null,
        lookingForOptions: data.lookingForList.isNotEmpty ? data.lookingForList : null,
        city: null,
        lat: _lat,
        lng: _lng,
        lookingFor: data.lookingFor,
        lookingForSet: true,
        categorySet: data.propertyTypes.isNotEmpty,
      );

      final ok = await AuthRepository().registerWithGeneratedPassword(request);

      if (!mounted) return;
      setState(() => _saving = false);

      if (ok) {
        OnboardingSession.clear();
        _showSuccessModal(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not create account. Please try again.')),
        );
      }
      return;
    }

    // Non-onboarding: existing user updating location
    setState(() => _saving = true);
    final ok = await AccountSetupRepository().saveLocationWithCoordinates(
      city: null,
      lat: _lat,
      lng: _lng,
    );
    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      context.push(AppRoutes.accountSetupSuccess);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save. Please try again.')),
      );
      context.push(AppRoutes.accountSetupSuccess);
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
