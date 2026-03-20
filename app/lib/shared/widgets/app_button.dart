import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum AppButtonVariant { primary, secondary, outline }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.width,
    this.height = 63,
    this.borderRadius,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final double? width;
  final double height;

  /// When set, overrides theme shape (e.g. listing detail `28:4568` — 25px pill).
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? 278,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: variant == AppButtonVariant.primary
              ? AppColors.primary
              : variant == AppButtonVariant.secondary
                  ? AppColors.greySoft1
                  : Colors.transparent,
          foregroundColor: variant == AppButtonVariant.outline
              ? AppColors.textSecondary
              : variant == AppButtonVariant.secondary
                  ? AppColors.textPrimary
                  : Colors.white,
          side: variant == AppButtonVariant.outline
              ? const BorderSide(color: AppColors.textSecondary)
              : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius ?? 10),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(label),
      ),
    );
  }
}
