import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../data/repositories/auth_repository.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/social_login_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _errorMessage;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              _buildForm(),
              const SizedBox(height: 32),
              _buildRegisterButton(),
              const SizedBox(height: 22),
              _buildOrDivider(),
              const SizedBox(height: 22),
              _buildSocialButtons(),
              const SizedBox(height: 32),
              _buildLoginPrompt(),
              const SizedBox(height: 40),
            ],
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
        child: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.textPrimary),
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      'Create Account',
      style: Theme.of(context).textTheme.displayMedium?.copyWith(
            fontSize: 25,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
    );
  }

  Widget _buildSubtitle() {
    return Text(
      'Complete your details to get started.',
      style: Theme.of(context).textTheme.bodyLarge,
    );
  }

  Widget _buildForm() {
    return Column(
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
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.red.shade700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        AppTextField(
          controller: _emailController,
          onChanged: (_) => setState(() => _errorMessage = null),
          hintText: AppStrings.email,
          keyboardType: TextInputType.emailAddress,
          prefixIcon: const Icon(Icons.email_outlined, size: 20, color: AppColors.greyBarelyMedium),
        ),
        const SizedBox(height: 15),
        AppTextField(
          controller: _passwordController,
          onChanged: (_) => setState(() => _errorMessage = null),
          hintText: AppStrings.password,
          obscureText: _obscurePassword,
          prefixIcon: const Icon(Icons.lock_outline, size: 20, color: AppColors.greyBarelyMedium),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              size: 20,
              color: AppColors.greyBarelyMedium,
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () {},
            child: Text(AppStrings.termsOfService, style: Theme.of(context).textTheme.labelLarge),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterButton() {
    return Center(
      child: AppButton(
        label: _loading ? 'Creating...' : AppStrings.register,
        isLoading: _loading,
        onPressed: _loading ? null : _register,
      ),
    );
  }

  Future<void> _register() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all fields');
      return;
    }
    if (!_isValidEmail(email)) {
      setState(() => _errorMessage = 'Please enter a valid email address');
      return;
    }
    if (password.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters');
      return;
    }
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    final ok = await AuthRepository().register(email: email, password: password);
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      context.push(AppRoutes.otpForEmail(email));
      return;
    }
    setState(() => _errorMessage = 'Could not create account. Please try again.');
  }

  bool _isValidEmail(String email) {
    final regex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return regex.hasMatch(email);
  }

  Widget _buildOrDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.greyBarelyMedium)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text('OR', style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.greyBarelyMedium,
                fontWeight: FontWeight.w600,
              )),
        ),
        const Expanded(child: Divider(color: AppColors.greyBarelyMedium)),
      ],
    );
  }

  Widget _buildSocialButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SocialLoginButton(provider: SocialProvider.google, onPressed: () {}),
        const SizedBox(width: 11),
        SocialLoginButton(provider: SocialProvider.facebook, onPressed: () {}),
      ],
    );
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: GestureDetector(
        onTap: () => context.go(AppRoutes.login),
        child: RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.bodyMedium,
            children: [
              const TextSpan(text: 'Already have an account? '),
              TextSpan(
                text: AppStrings.login,
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
