import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/country_codes.dart';
import '../data/repositories/auth_repository.dart';
import '../../onboarding/data/pending_profile_image.dart';
import '../../onboarding/data/google_sign_in_pending.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/social_login_button.dart';

/// Create Account screen - Figma 11:1214 "Fill your information below"
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    super.key,
    this.initialName,
    this.initialEmail,
    this.initialPhone,
    this.initialProfilePictureUrl,
    this.emailDisabled = false,
  });

  final String? initialName;
  final String? initialEmail;
  final String? initialPhone;
  final String? initialProfilePictureUrl;
  final bool emailDisabled;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _imagePicker = ImagePicker();

  File? _profileImage;
  String? _nameError;
  String? _emailError;
  String? _phoneError;
  String? _generalError;
  bool _loading = false;
  bool _socialLoading = false;
  String _countryCode = '+252';
  final _scrollController = ScrollController();
  final _nameKey = GlobalKey();
  final _emailKey = GlobalKey();
  final _phoneKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _nameFocus.addListener(() => setState(() {}));
    _phoneFocus.addListener(() => setState(() {}));
    _emailFocus.addListener(() => setState(() {}));
    if (widget.initialName != null && widget.initialName!.isNotEmpty) {
      _nameController.text = widget.initialName!;
    }
    if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      _emailController.text = widget.initialEmail!;
    }
    if (widget.initialPhone != null && widget.initialPhone!.isNotEmpty) {
      final full = widget.initialPhone!;
      final sorted = List.from(kCountryCodes)..sort((a, b) => b.code.length.compareTo(a.code.length));
      for (final entry in sorted) {
        if (full.startsWith(entry.code)) {
          _countryCode = entry.code;
          _phoneController.text = full.substring(entry.code.length).replaceAll(RegExp(r'\D'), '');
          break;
        }
      }
      if (_phoneController.text.isEmpty) {
        _phoneController.text = full.replaceAll(RegExp(r'[^\d]'), '');
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _nameFocus.dispose();
    _phoneFocus.dispose();
    _emailFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _clearFieldError(String field) {
    setState(() {
      switch (field) {
        case 'name': _nameError = null; break;
        case 'email': _emailError = null; break;
        case 'phone': _phoneError = null; break;
      }
      _generalError = null;
    });
  }

  /// Figma input styling: h-70, bg #F5F4F8, radius 10 + active border when focused
  static const _inputHeight = 70.0;
  static const _inputPaddingH = 16.0;
  static const _iconGap = 10.0;
  static const _figmaTextSize = 14.0; // Match login input size
  static const _figmaLetterSpacing = 0.36;

  BoxDecoration _inputDecoration(bool isActive, bool hasError, {bool isDisabled = false}) {
    Color borderColor = Colors.transparent;
    if (isDisabled) {
      borderColor = AppColors.greySoft2;
    } else if (hasError) {
      borderColor = Colors.red.shade400;
    } else if (isActive) {
      borderColor = AppColors.primary.withOpacity(0.5);
    }
    return BoxDecoration(
      color: isDisabled ? AppColors.greySoft1.withOpacity(0.6) : AppColors.greySoft1,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: borderColor, width: 1),
      boxShadow: isActive && !hasError && !isDisabled ? [BoxShadow(color: AppColors.primary.withOpacity(0.06), blurRadius: 2, spreadRadius: 0)] : null,
    );
  }

  Widget _buildFieldError(String? error) {
    if (error == null || error.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 4),
      child: Text(
        error,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.red.shade700,
          fontSize: 11,
        ),
      ),
    );
  }

  Future<bool> _handleBackButton() async {
    _goBack();
    return true; // Consume back - we handle navigation
  }

  @override
  Widget build(BuildContext context) {
    return BackButtonListener(
      onBackButtonPressed: _handleBackButton,
      child: Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              _buildBackButton(),
              const SizedBox(height: 24),
              _buildTitle(),
                    const SizedBox(height: 20),
                    _buildSubtitle(),
                    const SizedBox(height: 32),
                    _buildAvatar(),
                    const SizedBox(height: 32),
                    if (_generalError != null) ...[
                      _buildErrorMessage(),
                      const SizedBox(height: 16),
                    ],
                    _buildNameField(),
                    _buildFieldError(_nameError),
                    const SizedBox(height: 12),
                    _buildPhoneField(),
                    _buildFieldError(_phoneError),
                    const SizedBox(height: 12),
                    _buildEmailField(),
                    _buildFieldError(_emailError),
                    const SizedBox(height: 15),
                    _buildTermsRow(),
                    const SizedBox(height: 28),
                    _buildRegisterButton(),
                    if (!widget.emailDisabled) ...[
                    const SizedBox(height: 24),
                    _buildOrDivider(),
                    const SizedBox(height: 24),
                    _buildSocialButtons(),
                    ],
                    const SizedBox(height: 28),
                    _buildLoginPrompt(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
      ),
    ),
    );
  }

  void _goBack() {
    GoogleSignInPending.clear();
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.loginOption);
    }
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: _goBack,
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
    );
  }

  Widget _buildTitle() {
    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.displayMedium?.copyWith(
          fontSize: 25,
          color: AppColors.textPrimary,
          height: 1.6,
          letterSpacing: 0.75,
        ),
        children: const [
          TextSpan(text: 'Fill your '),
          TextSpan(
            text: 'information',
            style: TextStyle(
              color: Color(0xFF234F68),
              fontWeight: FontWeight.w800,
            ),
          ),
          TextSpan(text: ' below '),
        ],
      ),
    );
  }

  Widget _buildSubtitle() {
    return Text(
      'You can edit this later on your account setting.',
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontSize: 14,
        color: AppColors.greyMedium,
        letterSpacing: 0.42,
      ),
    );
  }

  Future<void> _pickProfileImage() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 85,
      );
      if (picked != null && mounted) {
        setState(() => _profileImage = File(picked.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick image: $e')),
        );
      }
    }
  }

  Widget _buildAvatar() {
    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.greySoft1,
              shape: BoxShape.circle,
            ),
            clipBehavior: Clip.antiAlias,
            child: _profileImage != null
                ? Image.file(_profileImage!, fit: BoxFit.cover)
                : widget.initialProfilePictureUrl != null && widget.initialProfilePictureUrl!.isNotEmpty
                    ? Image.network(
                        widget.initialProfilePictureUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(Icons.person, size: 50, color: AppColors.greyBarelyMedium.withOpacity(0.5)),
                      )
                    : Icon(Icons.person, size: 50, color: AppColors.greyBarelyMedium.withOpacity(0.5)),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: _pickProfileImage,
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFF234F68),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 20, color: Colors.red.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _generalError!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.red.shade700),
            ),
          ),
        ],
      ),
    );
  }

  /// Full name - Figma 11:1216 Form/Text-Fill: icon on RIGHT
  Widget _buildNameField() {
    return KeyedSubtree(
      key: _nameKey,
      child: Container(
        height: _inputHeight,
        padding: const EdgeInsets.symmetric(horizontal: _inputPaddingH),
        decoration: _inputDecoration(_nameFocus.hasFocus, _nameError != null),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _nameController,
                focusNode: _nameFocus,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => FocusScope.of(context).requestFocus(_phoneFocus),
                onChanged: (_) => _clearFieldError('name'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: _figmaTextSize,
                  letterSpacing: _figmaLetterSpacing,
                ),
                decoration: InputDecoration(
                  hintText: 'Full name',
                  hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.greyBarelyMedium,
                    fontSize: _figmaTextSize,
                    fontWeight: FontWeight.w400,
                    letterSpacing: _figmaLetterSpacing,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 25),
                  isDense: true,
                ),
              ),
            ),
            const Icon(Icons.person_outline, size: 20, color: AppColors.textPrimary),
          ],
        ),
      ),
    );
  }

  /// Mobile number - country code as icon/prefix, no separate phone icon
  Widget _buildPhoneField() {
    return KeyedSubtree(
      key: _phoneKey,
      child: Container(
        height: _inputHeight,
        padding: const EdgeInsets.symmetric(horizontal: _inputPaddingH),
        decoration: _inputDecoration(_phoneFocus.hasFocus, _phoneError != null),
        child: Row(
        children: [
          GestureDetector(
            onTap: _showCountryCodePicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.greySoft1,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.greySoft2, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _countryCode,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: _figmaTextSize,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.greyMedium),
                ],
              ),
            ),
          ),
          const SizedBox(width: _iconGap),
          Expanded(
            child: TextField(
              controller: _phoneController,
              focusNode: _phoneFocus,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => FocusScope.of(context).requestFocus(_emailFocus),
              onChanged: (_) => _clearFieldError('phone'),
              keyboardType: TextInputType.phone,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w400,
                fontSize: _figmaTextSize,
                letterSpacing: _figmaLetterSpacing,
              ),
              decoration: InputDecoration(
                hintText: 'mobile number',
                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.greyBarelyMedium,
                  fontSize: _figmaTextSize,
                  fontWeight: FontWeight.w400,
                  letterSpacing: _figmaLetterSpacing,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 25),
                isDense: true,
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  void _showCountryCodePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _CountryCodePickerSheet(
        selectedCode: _countryCode,
        onSelected: (code) {
          setState(() => _countryCode = code);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  /// Email - Figma Form/Text-Empty: icon on LEFT (same as mobile)
  Widget _buildEmailField() {
    final isDisabled = widget.emailDisabled;
    return KeyedSubtree(
      key: _emailKey,
      child: Container(
        height: _inputHeight,
        padding: const EdgeInsets.only(left: _inputPaddingH),
        decoration: _inputDecoration(_emailFocus.hasFocus, _emailError != null, isDisabled: isDisabled),
        child: Row(
          children: [
            Icon(Icons.email_outlined, size: 20, color: AppColors.greyBarelyMedium),
            const SizedBox(width: _iconGap),
            Expanded(
              child: TextField(
                controller: _emailController,
                focusNode: _emailFocus,
                readOnly: isDisabled,
                showCursor: !isDisabled,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => FocusScope.of(context).unfocus(),
                onChanged: (_) => _clearFieldError('email'),
                keyboardType: TextInputType.emailAddress,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDisabled ? AppColors.greyMedium : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: _figmaTextSize,
                  letterSpacing: _figmaLetterSpacing,
                ),
              decoration: InputDecoration(
                hintText: AppStrings.email,
                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.greyBarelyMedium,
                    fontSize: _figmaTextSize,
                    fontWeight: FontWeight.w400,
                    letterSpacing: _figmaLetterSpacing,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 25),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: _inputPaddingH),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsRow() {
    return GestureDetector(
      onTap: _openTermsOfService,
      child: Text(
        AppStrings.termsOfService,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _openTermsOfService() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Terms of Service - Coming soon')),
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      height: 63,
      child: AppButton(
        label: _loading ? 'Creating account...' : AppStrings.register,
        isLoading: _loading,
        onPressed: _loading ? null : _register,
      ),
    );
  }

  void _scrollToKey(GlobalKey key) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = key.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(context, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      }
    });
  }

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();

    setState(() {
      _nameError = null;
      _emailError = null;
      _phoneError = null;
      _generalError = null;
    });

    if (name.isEmpty) {
      setState(() => _nameError = 'Enter your full name');
      _scrollToKey(_nameKey);
      return;
    }
    if (name.length < 2) {
      setState(() => _nameError = 'Name must be at least 2 characters');
      _scrollToKey(_nameKey);
      return;
    }

    if (email.isEmpty) {
      setState(() => _emailError = 'Enter your email');
      _scrollToKey(_emailKey);
      return;
    }
    if (!_isValidEmail(email)) {
      setState(() => _emailError = 'Enter a valid email address');
      _scrollToKey(_emailKey);
      return;
    }

    final phoneDigits = _phoneController.text.trim();
    if (phoneDigits.isEmpty) {
      setState(() => _phoneError = 'Enter your mobile number');
      _scrollToKey(_phoneKey);
      return;
    }
    final phone = '$_countryCode${phoneDigits.replaceAll(RegExp(r'\s'), '')}';
    if (!_isValidPhone(phone)) {
      setState(() => _phoneError = 'Enter a valid phone number');
      _scrollToKey(_phoneKey);
      return;
    }

    setState(() => _loading = true);
    _nameError = null;
    _emailError = null;
    _phoneError = null;
    _generalError = null;

    final availability = await AuthRepository().checkEmailPhoneAvailability(email: email, phone: phone);
    if (!mounted) return;
    if (availability.emailExists || availability.phoneExists) {
      setState(() {
        _loading = false;
        if (availability.emailExists && availability.phoneExists) {
          _generalError = 'This email and mobile number are already linked to an account.';
        } else if (availability.emailExists) {
          _emailError = 'This email is already linked to an account.';
        } else {
          _phoneError = 'This mobile number is already linked to an account.';
        }
      });
      return;
    }

    setState(() => _loading = false);
    if (!mounted) return;
    if (_profileImage != null) {
      PendingProfileImage.set(_profileImage!);
    }
    final profilePictureUrl = _profileImage == null && widget.initialProfilePictureUrl != null && widget.initialProfilePictureUrl!.isNotEmpty
        ? widget.initialProfilePictureUrl
        : null;
    context.push(AppRoutes.phoneVerificationRoute(
      phone: phone,
      name: name,
      email: email,
      profilePictureUrl: profilePictureUrl,
    ));
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
  }

  bool _isValidPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[^\d+\-\s()]'), '');
    return RegExp(r'^[\+]?[1-9][\d]{0,15}$').hasMatch(cleaned);
  }

  Widget _buildOrDivider() {
    return Row(
        children: [
          const Expanded(child: Divider(color: AppColors.greySoft2)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Text(
              AppStrings.orSeparator,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.greyBarelyMedium,
                fontWeight: FontWeight.w600,
                fontSize: 10,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const Expanded(child: Divider(color: AppColors.greySoft2)),
        ],
      );
  }

  Widget _buildSocialButtons() {
    return SocialLoginButton(
      provider: SocialProvider.google,
      onPressed: () { _socialLogin(); },
      isLoading: _socialLoading,
    );
  }

  Future<void> _socialLogin() async {
    setState(() => _socialLoading = true);
    final result = await AuthRepository().getGoogleDataForRegistration();
    if (!mounted) return;
    setState(() => _socialLoading = false);
    if (result.errorMessage != null && result.errorMessage!.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.errorMessage!)),
      );
      return;
    }
    context.go(AppRoutes.registerWithGoogleRoute(
      name: result.name ?? '',
      email: result.email ?? '',
      phone: result.phone,
      profilePictureUrl: result.photoUrl,
    ));
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: GestureDetector(
        onTap: () => context.go(AppRoutes.login),
        child: RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.greyMedium,
              fontSize: 12,
              height: 1.67,
            ),
            children: [
              TextSpan(text: '${AppStrings.haveAccount} '),
              TextSpan(
                text: 'Log in',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountryCodePickerSheet extends StatefulWidget {
  const _CountryCodePickerSheet({
    required this.selectedCode,
    required this.onSelected,
  });

  final String selectedCode;
  final ValueChanged<String> onSelected;

  @override
  State<_CountryCodePickerSheet> createState() => _CountryCodePickerSheetState();
}

class _CountryCodePickerSheetState extends State<_CountryCodePickerSheet> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Select country', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search country...',
                      hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14),
                      prefixIcon: Icon(Icons.search_rounded, size: 22, color: AppColors.greyBarelyMedium),
                      filled: true,
                      fillColor: AppColors.greySoft1,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: _searchController,
                builder: (context, _) {
                  final query = _searchController.text.toLowerCase();
                  final filtered = query.isEmpty
                      ? kCountryCodes
                      : kCountryCodes.where((c) =>
                          c.name.toLowerCase().contains(query) ||
                          c.code.contains(query)).toList();
                  return ListView.builder(
                    controller: scrollController,
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final country = filtered[i];
                      final selected = widget.selectedCode == country.code;
                      return ListTile(
                        leading: selected ? Icon(Icons.check_circle, color: AppColors.primary, size: 22) : null,
                        title: Text(
                          country.name,
                          style: TextStyle(
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                            color: selected ? AppColors.primary : AppColors.textPrimary,
                          ),
                        ),
                        subtitle: Text(country.code, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.greyMedium)),
                        selected: selected,
                        onTap: () => widget.onSelected(country.code),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
