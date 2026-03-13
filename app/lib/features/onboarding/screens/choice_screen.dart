import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/remote_image.dart';

class ChoiceScreen extends StatefulWidget {
  const ChoiceScreen({super.key});

  @override
  State<ChoiceScreen> createState() => _ChoiceScreenState();
}

class _ChoiceScreenState extends State<ChoiceScreen> {
  static const _heroImage = 'https://www.figma.com/api/mcp/asset/94df70e2-44bb-4611-bb3b-71196d32f193';
  static const _options = [
    'Buy',
    'Sell',
    'Rent',
    'Monitor my property',
    'Just look around',
  ];

  final Set<String> _selected = {};

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) context.go(AppRoutes.welcome);
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
              child: RemoteImage(
                url: _heroImage,
                fit: BoxFit.cover,
                errorWidget: Container(color: AppColors.greySoft1),
              ),
            ),
            Positioned(
              right: 24,
              top: 40,
              child: GestureDetector(
                onTap: () => context.go(AppRoutes.home),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    'Skip',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: const Color(0xFFF85A5A),
                        ),
                  ),
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
                  for (final label in _options)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _ChoiceRow(
                        label: label,
                        selected: _selected.contains(label),
                        onTap: () {
                          setState(() {
                            if (_selected.contains(label)) {
                              _selected.remove(label);
                            } else {
                              _selected.add(label);
                            }
                          });
                        },
                      ),
                    ),
                  const SizedBox(height: 24),
                  Center(
                    child: AppButton(
                      label: 'Next',
                      onPressed: () => context.go(AppRoutes.loginOption),
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
