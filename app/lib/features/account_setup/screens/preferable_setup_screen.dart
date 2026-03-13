import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../data/repositories/account_setup_repository.dart';
import '../../../shared/widgets/setup_scaffold.dart';

/// Account Setup / Preferable - Select preferred property types
class PreferableSetupScreen extends StatefulWidget {
  const PreferableSetupScreen({super.key});

  @override
  State<PreferableSetupScreen> createState() => _PreferableSetupScreenState();
}

class _PreferableSetupScreenState extends State<PreferableSetupScreen> {
  final _selectedTypes = <String>{};
  bool _saving = false;

  static const _categories = [
    'Apartment',
    'House',
    'Villa',
    'Studio',
    'Office',
    'Land',
  ];

  @override
  Widget build(BuildContext context) {
    return SetupScaffold(
      title: 'What are you looking for?',
      description: 'Select your preferred property types.',
      progress: 0.75,
      onNext: _saving ? null : _onNext,
      nextLabel: _saving ? 'Saving...' : 'Next',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: _categories.map((c) {
          final isSelected = _selectedTypes.contains(c);
          return GestureDetector(
            onTap: () => setState(() {
              if (isSelected) {
                _selectedTypes.remove(c);
              } else {
                _selectedTypes.add(c);
              }
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.greySoft1,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Text(
                c,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _onNext() async {
    if (_selectedTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one property type.')),
      );
      return;
    }
    setState(() => _saving = true);
    final ok = await AccountSetupRepository().savePreferences(_selectedTypes.toList());
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      context.push(AppRoutes.accountSetupPayment);
    }
  }
}
