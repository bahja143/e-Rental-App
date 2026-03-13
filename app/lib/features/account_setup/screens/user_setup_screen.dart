import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../data/repositories/account_setup_repository.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/setup_scaffold.dart';

/// Account Setup / User - Fill your information
class UserSetupScreen extends StatefulWidget {
  const UserSetupScreen({super.key});

  @override
  State<UserSetupScreen> createState() => _UserSetupScreenState();
}

class _UserSetupScreenState extends State<UserSetupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController(text: 'user@email.com');
  final _phoneController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SetupScaffold(
      title: 'Fill your information below',
      description: 'You can edit this later on your account setting.',
      progress: 0.25,
      onNext: _saving ? null : _onNext,
      nextLabel: _saving ? 'Saving...' : 'Next',
      child: Column(
        children: [
          _buildAvatar(),
          const SizedBox(height: 32),
          AppTextField(
            controller: _nameController,
            hintText: 'Full name',
            prefixIcon: const Icon(Icons.person_outline, size: 20, color: AppColors.greyBarelyMedium),
          ),
          const SizedBox(height: 15),
          AppTextField(
            controller: _emailController,
            hintText: 'Email',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: const Icon(Icons.email_outlined, size: 20, color: AppColors.greyBarelyMedium),
          ),
          const SizedBox(height: 15),
          AppTextField(
            controller: _phoneController,
            hintText: 'Phone number',
            keyboardType: TextInputType.phone,
            prefixIcon: const Icon(Icons.phone_outlined, size: 20, color: AppColors.greyBarelyMedium),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  void _onNext() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    if (name.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name and email.')),
      );
      return;
    }

    setState(() => _saving = true);
    final ok = await AccountSetupRepository().saveUserInfo(name: name, email: email, phone: phone);
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      context.push(AppRoutes.accountSetupLocation);
    }
  }

  Widget _buildAvatar() {
    return Center(
      child: Stack(
        children: [
          const CircleAvatar(
            radius: 55,
            backgroundColor: AppColors.greySoft1,
            child: Icon(Icons.person, size: 60, color: AppColors.greyBarelyMedium),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.edit, size: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
