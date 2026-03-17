import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../data/repositories/account_setup_repository.dart';
import '../../../shared/widgets/setup_scaffold.dart';

/// Account Setup / Intent - What do you want to do? (Buy, Rent, Sell, etc.)
class IntentSetupScreen extends StatefulWidget {
  const IntentSetupScreen({super.key});

  @override
  State<IntentSetupScreen> createState() => _IntentSetupScreenState();
}

class _IntentSetupScreenState extends State<IntentSetupScreen> {
  String? _selected;
  bool _saving = false;

  /// Display label -> backend value for looking_for
  static const _options = [
    ('Buy', 'buy'),
    ('Rent', 'rent'),
    ('Sell', 'sale'),
    ('Monitor my property', 'monitor_my_property'),
    ('Just look around', 'just_look_around'),
  ];

  @override
  Widget build(BuildContext context) {
    return SetupScaffold(
      title: 'What are you looking to do?',
      description: 'We\'ll use this to show you relevant listings.',
      progress: 0.6,
      onNext: _saving ? null : _onNext,
      nextLabel: _saving ? 'Saving...' : 'Next',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _options
            .map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _IntentOption(
                  label: e.$1,
                  selected: _selected == e.$2,
                  onTap: () => setState(() => _selected = e.$2),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Future<void> _onNext() async {
    if (_selected == null || _selected!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an option.')),
      );
      return;
    }
    setState(() => _saving = true);
    final ok = await AccountSetupRepository().saveLookingFor(_selected!);
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      context.push(AppRoutes.accountSetupPreferable);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save. Please try again.')),
      );
      context.push(AppRoutes.accountSetupPreferable);
    }
  }
}

class _IntentOption extends StatelessWidget {
  const _IntentOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? AppColors.primary : const Color(0xFFB3D4FF),
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: selected ? AppColors.primary : const Color(0xFFA1A5C1),
                  width: 1.5,
                ),
                shape: BoxShape.circle,
              ),
              child: selected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.black87,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
