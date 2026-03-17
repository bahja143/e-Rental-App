import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../data/onboarding_session.dart';
import '../../../shared/widgets/app_button.dart';

class ChoiceScreen extends StatefulWidget {
  const ChoiceScreen({super.key, this.fromOtp = false});

  final bool fromOtp;

  @override
  State<ChoiceScreen> createState() => _ChoiceScreenState();
}

class _ChoiceScreenState extends State<ChoiceScreen> {
  /// Figma 9:295 – top city life illustration
  static const _heroAsset = 'assets/images/welcome/undraw_city_life_gnpr 1.png';
  static const _options = [
    ('Buy', 'buy'),
    ('Sell', 'sale'),
    ('Rent', 'rent'),
    ('Monitor my property', 'monitor_my_property'),
    ('Just look around', 'just_look_around'),
  ];

  late final Set<String> _selected;

  @override
  void initState() {
    super.initState();
    final data = OnboardingSession.data;
    _selected = {};
    final list = data?.lookingForList ?? (data != null && data.lookingFor.isNotEmpty ? [data.lookingFor] : <String>[]);
    for (final v in list) {
      final match = _options.where((o) => o.$2 == v).firstOrNull;
      if (match != null) _selected.add(match.$1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && context.canPop()) context.pop();
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: Stack(
          children: [
            Positioned(
              left: -11,
              top: -31,
              width: 408,
              height: 175,
              child: Image.asset(
                _heroAsset,
                fit: BoxFit.cover,
                width: 408,
                height: 175,
              ),
            ),
            Positioned(
              left: 24,
              top: 24,
              child: GestureDetector(
                onTap: () { if (context.canPop()) context.pop(); },
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 160),
                  Text(
                    'So, we can help you to find your way,\nwhat are you looking to do?',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 16,
                          height: 1.25,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Choose a few options if you need to:',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: 16,
                          color: AppColors.greyMedium,
                        ),
                  ),
                  const SizedBox(height: 24),
                  for (final option in _options)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _ChoiceRow(
                        label: option.$1,
                        selected: _selected.contains(option.$1),
                        onTap: () {
                          setState(() {
                            if (_selected.contains(option.$1)) {
                              _selected.remove(option.$1);
                            } else {
                              _selected.add(option.$1);
                            }
                          });
                        },
                      ),
                    ),
                  const SizedBox(height: 24),
                  Center(
                    child: AppButton(
                      label: 'Next',
                      onPressed: () {
                        if (widget.fromOtp) {
                          if (_selected.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please select at least one option.')),
                            );
                            return;
                          }
                          final data = OnboardingSession.data;
                          if (data != null) {
                            final list = _options
                                    .where((o) => _selected.contains(o.$1))
                                    .map((o) => o.$2)
                                    .toList();
                            final lookingFor = list.isNotEmpty ? list.first : 'just_look_around';
                            OnboardingSession.set(data.copyWith(
                              lookingFor: lookingFor,
                              lookingForList: list,
                            ));
                          }
                          context.push(AppRoutes.accountSetupPreferable);
                        } else {
                          context.go(AppRoutes.loginOption);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ));
  }
}

class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
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
        height: 48,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? AppColors.primary : const Color(0xFFB3D4FF),
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
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
                borderRadius: BorderRadius.circular(5),
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
