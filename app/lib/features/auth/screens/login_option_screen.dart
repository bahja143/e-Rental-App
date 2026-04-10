import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/social_login_button.dart';
import '../data/repositories/auth_repository.dart';

class LoginOptionScreen extends StatefulWidget {
  const LoginOptionScreen({super.key});

  @override
  State<LoginOptionScreen> createState() => _LoginOptionScreenState();
}

class _LoginOptionScreenState extends State<LoginOptionScreen> {
  // Local images: top-left, top-right, bottom-left, bottom-right
  static const _images = [
    'assets/images/realistic_images/WhatsApp Image 2026-04-08 at 1.21.53 AM (2).jpeg',
    'assets/images/realistic_images/WhatsApp Image 2026-04-08 at 1.21.54 AM (1).jpeg',
    'assets/images/realistic_images/WhatsApp Image 2026-04-08 at 1.21.54 AM.jpeg',
    'assets/images/realistic_images/WhatsApp Image 2026-04-08 at 1.21.52 AM.jpeg',
  ];

  bool _socialLoading = false;

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.welcome);
    }
  }

  Future<bool> _handleBackButton() async {
    _goBack();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return BackButtonListener(
      onBackButtonPressed: _handleBackButton,
      child: Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Column(
            children: [
              Expanded(
                flex: 5,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(child: _topImage(_images[0])),
                        const SizedBox(width: 8),
                        Expanded(child: _topImage(_images[1])),
                      ],
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        Expanded(child: _topImage(_images[2])),
                        const SizedBox(width: 8),
                        Expanded(child: _topImage(_images[3])),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 5,
                child: Column(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: RichText(
                              text: TextSpan(
                                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                  fontSize: 25,
                                  color: AppColors.textPrimary,
                                  height: 1.6,
                                  letterSpacing: 0.75,
                                ),
                                children: const [
                                  TextSpan(text: 'Ready to '),
                                  TextSpan(
                                    text: 'explore?',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                    const SizedBox(height: 16),
                    AppButton(
                      label: 'Continue with Phone Number',
                      onPressed: () => context.push(AppRoutes.login),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => context.go(AppRoutes.home),
                      child: Text(
                        'Browse as guest',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.greyMedium,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildOrDivider(context),
                    const SizedBox(height: 12),
                    SocialLoginButton(
                      provider: SocialProvider.google,
                      onPressed: () { _socialLogin(); },
                      isLoading: _socialLoading,
                    ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: GestureDetector(
                        onTap: () => context.push(AppRoutes.register),
                        child: RichText(
                          text: TextSpan(
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.greyMedium,
                              fontSize: 12,
                              height: 1.67,
                            ),
                            children: [
                              const TextSpan(text: "Don’t have an account? "),
                              TextSpan(
                                text: 'Register',
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                        ),
                      ),
                    ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  }

  Future<void> _socialLogin() async {
    setState(() => _socialLoading = true);
    final result = await AuthRepository().socialLoginForExistingOnly(provider: 'google');
    if (!mounted) return;
    setState(() => _socialLoading = false);
    if (result.ok) {
      context.go(AppRoutes.home);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.errorMessage ?? 'Sign in failed.')),
    );
  }

  Widget _topImage(String assetPath) {
    return AspectRatio(
      aspectRatio: 171 / 174,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.asset(
          assetPath,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(color: AppColors.greySoft1),
        ),
      ),
    );
  }

  Widget _buildOrDivider(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.greySoft2)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Text(
            'OR',
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
}
