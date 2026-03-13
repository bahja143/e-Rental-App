import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../data/repositories/account_setup_repository.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/setup_scaffold.dart';

/// Account Setup / Location - Set your location
class LocationSetupScreen extends StatefulWidget {
  const LocationSetupScreen({super.key});

  @override
  State<LocationSetupScreen> createState() => _LocationSetupScreenState();
}

class _LocationSetupScreenState extends State<LocationSetupScreen> {
  final _locationController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SetupScaffold(
      title: 'Where are you based?',
      description: 'We\'ll use this to show you relevant properties.',
      progress: 0.5,
      onNext: _saving ? null : _onNext,
      nextLabel: _saving ? 'Saving...' : 'Next',
      child: Column(
        children: [
          Container(
            height: 300,
            decoration: BoxDecoration(
              color: AppColors.greySoft1,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.map_outlined, size: 64, color: AppColors.greyBarelyMedium),
                  const SizedBox(height: 16),
                  Text(
                    'Select on map',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.greyBarelyMedium,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          AppTextField(
            controller: _locationController,
            hintText: 'City or area',
            prefixIcon: const Icon(Icons.location_on_outlined, size: 20, color: AppColors.greyBarelyMedium),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  void _onNext() async {
    final location = _locationController.text.trim();
    if (location.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your city or area.')),
      );
      return;
    }
    setState(() => _saving = true);
    final ok = await AccountSetupRepository().saveLocation(location);
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      context.push(AppRoutes.accountSetupIntent);
    }
  }
}
