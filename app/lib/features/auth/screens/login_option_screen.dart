import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/remote_image.dart';
import '../../../shared/widgets/social_login_button.dart';
import '../data/repositories/auth_repository.dart';

class LoginOptionScreen extends StatefulWidget {
  const LoginOptionScreen({super.key});

  @override
  State<LoginOptionScreen> createState() => _LoginOptionScreenState();
}

class _LoginOptionScreenState extends State<LoginOptionScreen> {
  static const _images = [
    'https://www.figma.com/api/mcp/asset/6ed2025a-3b51-4773-8b5f-34f814994b15',
    'https://www.figma.com/api/mcp/asset/05a777c7-fc50-4a41-9456-9e2e551b318e',
    'https://www.figma.com/api/mcp/asset/7c0e402c-76db-4972-8eb9-7ea281a3a615',
    'https://www.figma.com/api/mcp/asset/60d0a31b-629d-488e-8b7a-b1987de80bbe',
  ];

  bool _socialLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 17),
              Row(
                children: [
                  _topImage(_images[0]),
                  const SizedBox(width: 8),
                  _topImage(_images[1]),
                ],
              ),
              const SizedBox(height: 9),
              Row(
                children: [
                  _topImage(_images[2]),
                  const SizedBox(width: 8),
                  _topImage(_images[3]),
                ],
              ),
              const SizedBox(height: 53),
              Align(
                alignment: Alignment.centerLeft,
                child: RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontSize: 25,
                          color: AppColors.textPrimary,
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
              const SizedBox(height: 28),
              AppButton(
                label: 'Continue with Email',
                onPressed: () => context.push(AppRoutes.login),
              ),
              const SizedBox(height: 28),
              _buildOrDivider(context),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SocialLoginButton(
                    provider: SocialProvider.google,
                    onPressed: _socialLoading ? () {} : () => _socialLogin('google'),
                  ),
                  const SizedBox(width: 10),
                  SocialLoginButton(
                    provider: SocialProvider.facebook,
                    onPressed: _socialLoading ? () {} : () => _socialLogin('facebook'),
                  ),
                ],
              ),
              if (_socialLoading) ...[
                const SizedBox(height: 12),
                const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                ),
              ],
              const SizedBox(height: 48),
              GestureDetector(
                onTap: () => context.push(AppRoutes.register),
                child: RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.greyMedium,
                        ),
                    children: [
                      const TextSpan(text: "Don’t have an account? "),
                      TextSpan(
                        text: 'Register',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
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
    if (ok) {
      context.go(AppRoutes.home);
    }
  }

  Widget _topImage(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 171,
        height: 174,
        color: AppColors.greySoft1,
        child: RemoteImage(
          url: url,
          fit: BoxFit.cover,
          errorWidget: Container(color: AppColors.greySoft1),
        ),
      ),
    );
  }

  Widget _buildOrDivider(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.greySoft2)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            'OR',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.greyBarelyMedium,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.greySoft2)),
      ],
    );
  }
}
