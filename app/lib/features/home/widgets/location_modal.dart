import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../data/models/top_location_item.dart';

/// Bottom sheet modal for selecting location - matches Figma node 13-1231
class LocationModal extends StatefulWidget {
  const LocationModal({
    super.key,
    this.onSelect,
    this.onSelectFuture,
    this.topLocations = const [],
    this.initialLocation,
  }) : assert(
          onSelect != null || onSelectFuture != null,
          'Provide onSelect or onSelectFuture',
        );

  /// Sync callback (e.g. home header). Sheet closes after this returns.
  final void Function(String)? onSelect;

  /// Async callback (e.g. map geocoding). Awaited before the sheet closes.
  final Future<void> Function(String)? onSelectFuture;

  final List<TopLocationItem> topLocations;
  final String? initialLocation;

  static Future<void> show(
    BuildContext context, {
    void Function(String)? onSelect,
    Future<void> Function(String)? onSelectFuture,
    List<TopLocationItem> topLocations = const [],
    String? initialLocation,
  }) {
    assert(onSelect != null || onSelectFuture != null);
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => LocationModal(
        onSelect: onSelect,
        onSelectFuture: onSelectFuture,
        topLocations: topLocations,
        initialLocation: initialLocation,
      ),
    );
  }

  @override
  State<LocationModal> createState() => _LocationModalState();
}

class _LocationModalState extends State<LocationModal> {
  late String? _selectedLocation;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
  }

  List<TopLocationItem> get _displayItems {
    return widget.topLocations.isNotEmpty
        ? widget.topLocations
        : _fallbackLocations
            .map((n) => TopLocationItem(name: n, avatarUrl: ''))
            .toList();
  }

  static const _fallbackLocations = [
    'Mogadishu',
    'Hargeisa',
    'Kismayo',
    'Bosaso',
    'Jakarta, Indonesia',
    'Bali, Indonesia',
  ];

  @override
  Widget build(BuildContext context) {
    final items = _displayItems;
    final sheetH = MediaQuery.sizeOf(context).height * 0.72;

    return Container(
      height: sheetH,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(50)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 27),
            Center(
              child: Container(
                width: 60,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.greyBarelyMedium,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Select Location',
                style: GoogleFonts.lato(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.54,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < items.length; i++) ...[
                      _LocationCard(
                        address: items[i].name,
                        isSelected: _selectedLocation == items[i].name,
                        onTap: () =>
                            setState(() => _selectedLocation = items[i].name),
                      ),
                      if (i < items.length - 1) const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                height: 63,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _busy
                      ? null
                      : () async {
                          if (_selectedLocation == null) {
                            Navigator.pop(context);
                            return;
                          }
                          final loc = _selectedLocation!;
                          setState(() => _busy = true);
                          try {
                            if (widget.onSelectFuture != null) {
                              await widget.onSelectFuture!(loc);
                            } else {
                              widget.onSelect!(loc);
                            }
                          } finally {
                            if (context.mounted) {
                              setState(() => _busy = false);
                              Navigator.pop(context);
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _busy
                      ? const SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Choose Location',
                          style: GoogleFonts.lato(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.48,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({
    required this.address,
    required this.isSelected,
    required this.onTap,
  });

  final String address;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(25),
        child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.categoryActive : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: isSelected
              ? null
              : Border.all(color: AppColors.greySoft2, width: 1.2),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 50,
              height: 50,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withOpacity(0.3)
                          : AppColors.greySoft2,
                      borderRadius: BorderRadius.circular(25),
                      border: isSelected
                          ? null
                          : Border.all(
                              color: AppColors.greySoft2,
                              width: 1.2,
                            ),
                    ),
                  ),
                  Icon(
                    Icons.location_on,
                    size: 20,
                    color: isSelected ? Colors.white : AppColors.greyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                address,
                style: GoogleFonts.raleway(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: isSelected ? Colors.white : AppColors.greyMedium,
                  height: 20 / 12,
                  letterSpacing: 0.36,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
