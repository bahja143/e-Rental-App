import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_strings.dart';
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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _errorMessage;
  bool _loading = false;
  bool _socialLoading = false;
  bool _forgotLoading = false;

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
              _buildLoginButton(),
              const SizedBox(height: 22),
              _buildOrDivider(),
              const SizedBox(height: 22),
              _buildSocialButtons(),
              const SizedBox(height: 32),
              _buildRegisterPrompt(),
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
      AppStrings.enterDetailsToContinue,
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
          hintText: AppStrings.password,
          obscureText: _obscurePassword,
          onChanged: (_) => setState(() => _errorMessage = null),
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
            onPressed: _forgotLoading ? null : _forgotPassword,
            child: Text(AppStrings.forgotPassword, style: Theme.of(context).textTheme.labelLarge),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return Center(
      child: AppButton(
        label: _loading ? 'Signing in...' : AppStrings.login,
        isLoading: _loading,
        onPressed: _loading ? null : _login,
      ),
    );
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all fields');
      return;
    }
    if (!_isValidEmail(email)) {
      setState(() => _errorMessage = 'Please enter a valid email address');
      return;
    }
    if (_passwordController.text.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters');
      return;
    }

    setState(() {
      _errorMessage = null;
      _loading = true;
    });
    final ok = await AuthRepository().login(
      email: email,
      password: _passwordController.text,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      context.push(AppRoutes.otpForEmail(email));
      return;
    }
    setState(() => _errorMessage = 'Could not sign in. Please try again.');
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
        SocialLoginButton(
          provider: SocialProvider.google,
          onPressed: _socialLoading ? () {} : () => _socialLogin('google'),
        ),
        const SizedBox(width: 11),
        SocialLoginButton(
          provider: SocialProvider.facebook,
          onPressed: _socialLoading ? () {} : () => _socialLogin('facebook'),
        ),
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
                text: AppStrings.register,
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

  Future<void> _socialLogin(String provider) async {
    setState(() => _socialLoading = true);
    final ok = await AuthRepository().socialLogin(provider);
    if (!mounted) return;
    setState(() => _socialLoading = false);
    if (ok) context.go(AppRoutes.home);
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (!_isValidEmail(email)) {
      setState(() => _errorMessage = 'Enter a valid email to reset password');
      return;
    }
    setState(() => _forgotLoading = true);
    final ok = await AuthRepository().requestPasswordReset(email);
    if (!mounted) return;
    setState(() => _forgotLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Password reset link sent.' : 'Could not send reset link.')),
    );
  }
}
