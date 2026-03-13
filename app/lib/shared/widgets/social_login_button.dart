import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

enum SocialProvider { google, facebook }

class SocialLoginButton extends StatelessWidget {
  const SocialLoginButton({
    super.key,
    required this.provider,
    required this.onPressed,
  });

  final SocialProvider provider;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.greySoft1,
      borderRadius: BorderRadius.circular(25),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(25),
        child: SizedBox(
          height: 70,
          width: 158.5,
          child: Center(child: _buildIcon()),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    switch (provider) {
      case SocialProvider.google:
        return Text(
          'G',
          style: GoogleFonts.raleway(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF4285F4),
          ),
        );
      case SocialProvider.facebook:
        return Container(
          width: 25,
          height: 25,
          decoration: BoxDecoration(
            color: const Color(0xFF1877F2),
            borderRadius: BorderRadius.circular(4),
          ),
          alignment: Alignment.center,
          child: Text(
            'f',
            style: GoogleFonts.raleway(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        );
    }
  }
}
