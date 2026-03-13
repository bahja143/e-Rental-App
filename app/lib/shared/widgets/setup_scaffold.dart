import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';

/// Reusable scaffold for Account Setup screens - Header (back, skip), title, progress
class SetupScaffold extends StatelessWidget {
  const SetupScaffold({
    super.key,
    required this.title,
    this.description,
    this.child,
    this.progress,
    this.onNext,
    this.nextLabel = 'Next',
    this.showSkip = true,
  });

  final String title;
  final String? description;
  final Widget? child;
  final double? progress;
  final VoidCallback? onNext;
  final String nextLabel;
  final bool showSkip;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            if (progress != null) _buildProgressBar(progress!),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    if (description != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        description!,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                    if (child != null) ...[
                      const SizedBox(height: 32),
                      child!,
                    ],
                  ],
                ),
              ),
            ),
            if (onNext != null) _buildNextButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _backButton(context),
          if (showSkip)
            TextButton(
              onPressed: () => context.go(AppRoutes.home),
              child: Text('Skip', style: Theme.of(context).textTheme.labelLarge),
            )
          else
            const SizedBox(width: 86),
        ],
      ),
    );
  }

  Widget _backButton(BuildContext context) {
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

  Widget _buildProgressBar(double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: LinearProgressIndicator(
        value: value,
        backgroundColor: AppColors.greySoft1,
        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
      ),
    );
  }

  Widget _buildNextButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        width: double.infinity,
        height: 63,
        child: ElevatedButton(
          onPressed: onNext,
          child: Text(nextLabel),
        ),
      ),
    );
  }
}
