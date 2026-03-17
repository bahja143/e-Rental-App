import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';

/// Figma 11:1155 - Success bottom sheet modal
/// "Account successfully created" with Finish button.
/// Cannot be dismissed until user taps Finish; then navigates to home.
class AccountSuccessSheet extends StatelessWidget {
  const AccountSuccessSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(50)),
      ),
      padding: EdgeInsets.only(
        top: 27,
        left: 24,
        right: 24,
        bottom: 24 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.greySoft2,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 56),
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
                colors: [
                  AppColors.primary,
                  const Color(0xFF8BC83F),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                // Soft drop shadow for depth
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 20,
                  spreadRadius: -2,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 28,
                  spreadRadius: -4,
                  offset: const Offset(0, 10),
                ),
                // Primary outer: warm yellowish-beige glow (Figma 11:1181)
                BoxShadow(
                  color: const Color(0xFF8BC83F).withOpacity(0.3),
                  blurRadius: 28,
                  spreadRadius: 4,
                  offset: const Offset(0, 6),
                ),
                // Wider diffuse halo
                BoxShadow(
                  color: const Color(0xFFB8D99B).withOpacity(0.35),
                  blurRadius: 40,
                  spreadRadius: -2,
                  offset: const Offset(0, 8),
                ),
                // Outermost faint luminous halo
                BoxShadow(
                  color: const Color(0xFFE8F5DC).withOpacity(0.5),
                  blurRadius: 50,
                  spreadRadius: -10,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: const Icon(Icons.check, size: 40, color: Colors.white),
          ),
          const SizedBox(height: 24),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.raleway(
                fontSize: 25,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
                letterSpacing: 0.75,
                height: 1.6,
              ),
              children: [
                const TextSpan(text: 'Account '),
                TextSpan(
                  text: 'successfully\ncreated',
                  style: GoogleFonts.raleway(
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Start exploring your new account.',
            textAlign: TextAlign.center,
            style: GoogleFonts.raleway(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: AppColors.greyMedium,
              letterSpacing: 0.48,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 63,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.go(AppRoutes.home);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Finish',
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
    );
  }
}
