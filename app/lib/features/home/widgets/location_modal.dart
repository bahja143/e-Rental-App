import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Bottom sheet modal for selecting location
class LocationModal extends StatelessWidget {
  const LocationModal({
    super.key,
    required this.onSelect,
    this.locations = const ['Mogadishu', 'Hargeisa', 'Kismayo', 'Bosaso'],
  });

  final void Function(String) onSelect;
  final List<String> locations;

  static Future<void> show(BuildContext context, {void Function(String)? onSelect}) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => LocationModal(
        onSelect: (loc) {
          onSelect?.call(loc);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.greyBarelyMedium,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Location',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Reset', style: Theme.of(context).textTheme.labelLarge),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...locations.map((loc) => _LocationTile(
                  label: loc,
                  onTap: () => onSelect(loc),
                )),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 63,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Apply'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationTile extends StatelessWidget {
  const _LocationTile({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: Theme.of(context).textTheme.bodyLarge),
      trailing: const Icon(Icons.chevron_right, color: AppColors.greyBarelyMedium),
      onTap: onTap,
    );
  }
}
