import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/country_codes.dart';
import '../data/repositories/auth_repository.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/social_login_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  String _countryCode = '+252';
  String? _errorMessage;
  bool _loading = false;
  bool _socialLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String get _fullPhone =>
      '$_countryCode${_phoneController.text.replaceAll(RegExp(r'\D'), '')}';

  Future<void> _sendOtp() async {
    final digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 6) {
      setState(() => _errorMessage = 'Enter a valid phone number');
      return;
    }

    setState(() {
      _errorMessage = null;
      _loading = true;
    });

    final result = await AuthRepository().checkEmailPhoneAvailability(
      email: '',
      phone: _fullPhone,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (!result.phoneExists) {
      setState(() =>
          _errorMessage =
              'No account found. Create one with Register or use Google Sign-In if you signed up that way.');
      return;
    }

    context.push(AppRoutes.phoneVerificationForLogin(_fullPhone));
  }

  Future<void> _socialLogin() async {
    setState(() => _socialLoading = true);
    final result =
        await AuthRepository().socialLoginForExistingOnly(provider: 'google');
    if (!mounted) return;
    setState(() => _socialLoading = false);

    if (result.ok) {
      context.go(AppRoutes.home);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.errorMessage ??
              'No account found. Create one with Register or use phone number if you signed up that way.',
        ),
      ),
    );
  }

  Future<bool> _handleBackButton() async {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.loginOption);
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return BackButtonListener(
      onBackButtonPressed: _handleBackButton,
      child: Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              _buildBackButton(),
              const SizedBox(height: 56),
              _buildTitle(),
              const SizedBox(height: 20),
              _buildSubtitle(),
              const SizedBox(height: 40),
              _buildPhoneField(),
              const SizedBox(height: 32),
              _buildContinueButton(),
              const SizedBox(height: 22),
              _buildOrDivider(),
              const SizedBox(height: 22),
              SocialLoginButton(
                provider: SocialProvider.google,
                onPressed: _socialLogin,
                isLoading: _socialLoading,
              ),
              const SizedBox(height: 32),
              _buildRegisterPrompt(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => context.pop(),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.greySoft1,
          borderRadius: BorderRadius.circular(25),
        ),
        alignment: Alignment.center,
        child: const Icon(
            Icons.arrow_back_ios_new, size: 20, color: AppColors.textPrimary),
      ),
    );
  }

  Widget _buildTitle() {
    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.displayMedium?.copyWith(
              fontSize: 25,
              color: AppColors.textPrimary,
            ),
        children: const [
          TextSpan(text: "Let's "),
          TextSpan(
            text: 'Sign In',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtitle() {
    return Text(
      'Enter your phone number to receive an OTP.',
      style: Theme.of(context).textTheme.bodyLarge,
    );
  }

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_errorMessage != null) ...[
          Container(
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
                    _errorMessage!,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.red.shade700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        Row(
          children: [
            _buildCountryPicker(),
            const SizedBox(width: 12),
            Expanded(
              child: AppTextField(
                controller: _phoneController,
                onChanged: (_) => setState(() => _errorMessage = null),
                hintText: 'Phone number',
                keyboardType: TextInputType.phone,
                prefixIcon: const Icon(
                    Icons.phone_outlined, size: 20, color: AppColors.greyBarelyMedium),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCountryPicker() {
    return GestureDetector(
      onTap: () => _showCountryPicker(),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.greySoft1,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.greySoft2),
        ),
        alignment: Alignment.center,
        child: Text(
          _countryCode,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final sorted = List.from(kCountryCodes)
          ..sort((a, b) => a.name.compareTo(b.name));
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Select country',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: sorted.length,
                  itemBuilder: (_, i) {
                    final e = sorted[i];
                    return ListTile(
                      title: Text(e.name),
                      subtitle: Text(e.code),
                      onTap: () {
                        setState(() => _countryCode = e.code);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContinueButton() {
    return Center(
      child: AppButton(
        label: _loading ? 'Checking...' : 'Send OTP',
        isLoading: _loading,
        onPressed: _loading ? null : _sendOtp,
      ),
    );
  }

  Widget _buildOrDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.greyBarelyMedium)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            'OR',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.greyBarelyMedium,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.greyBarelyMedium)),
      ],
    );
  }

  Widget _buildRegisterPrompt() {
    return Center(
      child: GestureDetector(
        onTap: () => context.push(AppRoutes.register),
        child: RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.bodyMedium,
            children: [
              const TextSpan(text: "Don't have an account? "),
              TextSpan(
                text: 'Register',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
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
