import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.hintText,
    this.label,
    this.obscureText = false,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.validator,
    this.errorText,
    this.inputFormatters,
  });

  final TextEditingController? controller;
  final String? hintText;
  final String? label;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final String? errorText;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      validator: validator,
      style: GoogleFonts.raleway(
        fontSize: 14,
        color: AppColors.textPrimary,
        letterSpacing: 0.36,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.raleway(
          fontSize: 14,
          color: AppColors.inputPlaceholder,
          letterSpacing: 0.36,
        ),
        labelText: label,
        prefixIcon: prefixIcon != null
            ? Padding(
                padding: const EdgeInsets.only(left: 16, right: 10),
                child: prefixIcon,
              )
            : null,
        prefixIconConstraints: const BoxConstraints(minWidth: 46),
        suffixIcon: suffixIcon,
        errorText: errorText,
      ),
    );
  }
}
