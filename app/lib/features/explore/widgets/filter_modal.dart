import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../home/widgets/category_chip.dart';

/// Filter modal - Figma node 24-3522 / 24-3540
class FilterModal extends StatefulWidget {
  const FilterModal({
    super.key,
    this.initialPropertyType = 'All',
    this.initialPreferRent = true,
    this.initialPriceMin,
    this.initialPriceMax,
    this.initialAreaMin,
    this.initialAreaMax,
    this.onApply,
  });

  final String initialPropertyType;
  final bool initialPreferRent;
  final String? initialPriceMin;
  final String? initialPriceMax;
  final String? initialAreaMin;
  final String? initialAreaMax;
  final void Function({
    String propertyType,
    bool preferRent,
    String? priceMin,
    String? priceMax,
    String? areaMin,
    String? areaMax,
  })? onApply;

  static Future<void> show(
    BuildContext context, {
    String initialPropertyType = 'House',
    bool initialPreferRent = true,
    String? initialPriceMin,
    String? initialPriceMax,
    String? initialAreaMin,
    String? initialAreaMax,
    void Function({
      String propertyType,
      bool preferRent,
      String? priceMin,
      String? priceMax,
      String? areaMin,
      String? areaMax,
    })? onApply,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => FilterModal(
        initialPropertyType: initialPropertyType,
        initialPreferRent: initialPreferRent,
        initialPriceMin: initialPriceMin,
        initialPriceMax: initialPriceMax,
        initialAreaMin: initialAreaMin,
        initialAreaMax: initialAreaMax,
        onApply: ({
          String propertyType = 'All',
          bool preferRent = true,
          String? priceMin,
          String? priceMax,
          String? areaMin,
          String? areaMax,
        }) {
          onApply?.call(
            propertyType: propertyType,
            preferRent: preferRent,
            priceMin: priceMin,
            priceMax: priceMax,
            areaMin: areaMin,
            areaMax: areaMax,
          );
          Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  State<FilterModal> createState() => _FilterModalState();
}

class _FilterModalState extends State<FilterModal> {
  late String _propertyType;
  late bool _preferRent;
  final _priceMin = TextEditingController();
  final _priceMax = TextEditingController();
  final _areaMin = TextEditingController();
  final _areaMax = TextEditingController();

  @override
  void initState() {
    super.initState();
    _propertyType = widget.initialPropertyType;
    _preferRent = widget.initialPreferRent;
    if (widget.initialPriceMin != null && widget.initialPriceMin!.isNotEmpty) {
      _priceMin.text = widget.initialPriceMin!;
    }
    if (widget.initialPriceMax != null && widget.initialPriceMax!.isNotEmpty) {
      _priceMax.text = widget.initialPriceMax!;
    }
    if (widget.initialAreaMin != null && widget.initialAreaMin!.isNotEmpty) {
      _areaMin.text = widget.initialAreaMin!;
    }
    if (widget.initialAreaMax != null && widget.initialAreaMax!.isNotEmpty) {
      _areaMax.text = widget.initialAreaMax!;
    }
  }

  @override
  void dispose() {
    _priceMin.dispose();
    _priceMax.dispose();
    _areaMin.dispose();
    _areaMax.dispose();
    super.dispose();
  }

  void _resetAll() {
    setState(() {
      _propertyType = 'All';
      _preferRent = true;
      _priceMin.clear();
      _priceMax.clear();
      _areaMin.clear();
      _areaMax.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInsets = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInsets),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(50)),
        ),
        child: SafeArea(
          child: Column(
          mainAxisSize: MainAxisSize.min,
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
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Text(
                    'Filter',
                    style: GoogleFonts.lato(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.54,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _resetAll,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.rotate_left,
                          size: 20,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Reset all',
                          style: GoogleFonts.lato(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: AppColors.navGray,
                            letterSpacing: 0.208,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPropertyType(),
                    const SizedBox(height: 20),
                    _buildNeedToggle(),
                    const SizedBox(height: 20),
                    _buildPriceRange(),
                    const SizedBox(height: 20),
                    _buildAreaRange(),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 63,
                      child: ElevatedButton(
                        onPressed: () => widget.onApply?.call(
                          propertyType: _propertyType,
                          preferRent: _preferRent,
                          priceMin: _priceMin.text.trim().isEmpty
                              ? null
                              : _priceMin.text.trim(),
                          priceMax: _priceMax.text.trim().isEmpty
                              ? null
                              : _priceMax.text.trim(),
                          areaMin: _areaMin.text.trim().isEmpty
                              ? null
                              : _areaMin.text.trim(),
                          areaMax: _areaMax.text.trim().isEmpty
                              ? null
                              : _areaMax.text.trim(),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Apply Filter',
                          style: GoogleFonts.lato(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildPropertyType() {
    const types = ['All', 'House', 'Apartment', 'Villa'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Property type',
              style: GoogleFonts.lato(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 5),
            Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final t in types)
                Padding(
                  padding: EdgeInsets.only(right: t != types.last ? 10 : 0),
                  child: GestureDetector(
                    onTap: () => setState(() => _propertyType = t),
                    child: CategoryChip(
                      label: t,
                      isSelected: _propertyType == t,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNeedToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What do you need?',
          style: GoogleFonts.lato(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: 0.18,
          ),
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: () => setState(() => _preferRent = !_preferRent),
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F3),
              borderRadius: BorderRadius.circular(72),
              border: Border.all(color: const Color(0xFFE3E3E7), width: 0.8),
            ),
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 200),
                  left: _preferRent ? 8 : null,
                  right: _preferRent ? null : 8,
                  top: 8,
                  child: Container(
                    width: 156,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFE9BD36), AppColors.primary],
                      ),
                      borderRadius: BorderRadius.circular(72),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Center(
                        child: Text(
                          'I need to rent',
                          style: GoogleFonts.lato(
                            fontSize: 15,
                            color: _preferRent
                                ? Colors.white
                                : AppColors.navGray,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'I need to buy',
                          style: GoogleFonts.lato(
                            fontSize: 15,
                            color: !_preferRent
                                ? Colors.white
                                : AppColors.navGray,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRange() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Price Range',
          style: GoogleFonts.lato(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _FilterDropdownField(
                controller: _priceMin,
                hint: 'Min',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _FilterDropdownField(
                controller: _priceMax,
                hint: 'Max',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAreaRange() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Area (sqft)',
          style: GoogleFonts.lato(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _FilterDropdownField(
                controller: _areaMin,
                hint: 'Min',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _FilterDropdownField(
                controller: _areaMax,
                hint: 'Max',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Text input field - Figma node 24-3522 (filter modal inputs)
/// Aligned with explore search bar: h-70, bg #F5F4F8, radius 20, primary border when focused
class _FilterDropdownField extends StatefulWidget {
  const _FilterDropdownField({
    required this.controller,
    required this.hint,
  });

  final TextEditingController controller;
  final String hint;

  @override
  State<_FilterDropdownField> createState() => _FilterDropdownFieldState();
}

class _FilterDropdownFieldState extends State<_FilterDropdownField> {
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  BoxDecoration _inputDecoration(bool hasFocus) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: hasFocus ? AppColors.primary : AppColors.greyBarelyMedium,
        width: hasFocus ? 1.5 : 1,
      ),
      boxShadow: hasFocus
          ? [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.06),
                blurRadius: 2,
                spreadRadius: 0,
              ),
            ]
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _focusNode,
      builder: (context, _) {
        final hasFocus = _focusNode.hasFocus;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: _inputDecoration(hasFocus),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  keyboardType: TextInputType.number,
                  cursorColor: AppColors.primary,
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    hintStyle: GoogleFonts.raleway(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.greyBarelyMedium,
                      letterSpacing: 0.36,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    isDense: true,
                    fillColor: Colors.white,
                  ),
                  style: GoogleFonts.raleway(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.36,
                  ),
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down,
                color: hasFocus ? AppColors.primary : AppColors.greyBarelyMedium,
                size: 24,
              ),
            ],
          ),
        );
      },
    );
  }
}
