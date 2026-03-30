import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';

class CenteredHeaderBar extends StatelessWidget {
  const CenteredHeaderBar({
    super.key,
    required this.title,
    this.onBack,
    this.trailing,
    this.titleSize = 18,
    this.titleSpacing = 0,
  });

  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;
  final double titleSize;
  final double titleSpacing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: Row(
        children: [
          HeaderCircleButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: onBack ?? () => context.pop(),
          ),
          Expanded(
            child: Center(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: titleSpacing,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 50,
            height: 50,
            child: trailing ?? const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class HeaderCircleButton extends StatelessWidget {
  const HeaderCircleButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.iconSize = 18,
    this.iconColor = AppColors.textPrimary,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double iconSize;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(25),
        child: Container(
          width: 50,
          height: 50,
          decoration: const BoxDecoration(
            color: AppColors.greySoft1,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: iconSize,
          ),
        ),
      ),
    );
  }
}
