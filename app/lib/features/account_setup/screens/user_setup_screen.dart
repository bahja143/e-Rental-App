import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../data/repositories/account_setup_repository.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';

/// Account Setup / User - Figma 11:1214 "Fill your information below"
class UserSetupScreen extends StatefulWidget {
  const UserSetupScreen({super.key});

  @override
  State<UserSetupScreen> createState() => _UserSetupScreenState();
}

class _UserSetupScreenState extends State<UserSetupScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _saving = false;
  bool _loading = true;
  String _email = '';

  static const _emailBgColor = Color(0xFF234F68); // Figma disabled field

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final info = await AccountSetupRepository().getCurrentUserInfo();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (info != null) {
        _nameController.text = '${info['name'] ?? ''}'.trim();
        _email = '${info['email'] ?? ''}'.trim();
        _phoneController.text = '${info['phone'] ?? ''}'.trim();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    _buildTitle(),
                    const SizedBox(height: 20),
                    _buildSubtitle(),
                    const SizedBox(height: 32),
                    if (_loading)
                      const Center(child: CircularProgressIndicator())
                    else ...[
                      _buildAvatar(),
                      const SizedBox(height: 32),
                      _buildNameField(),
                      const SizedBox(height: 15),
                      _buildPhoneField(),
                      const SizedBox(height: 15),
                      _buildEmailField(),
                      const SizedBox(height: 80),
                    ],
                  ],
                ),
              ),
            ),
            _buildNextButton(context),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.greySoft1,
              borderRadius: BorderRadius.circular(100),
            ),
            child: GestureDetector(
              onTap: () => context.go(AppRoutes.home),
              child: Text(
                'skip',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF3A3F67),
                  fontSize: 12,
                ),
              ),
            ),
          ),
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
            child: Icon(Icons.person, size: 50, color: AppColors.greyBarelyMedium.withOpacity(0.5)),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile photo upload coming soon')),
                );
              },
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

  Widget _buildNameField() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.greySoft1,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _nameController,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
                letterSpacing: 0.36,
              ),
              decoration: const InputDecoration(
                hintText: 'Full name',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const Icon(Icons.person_outline, size: 20, color: AppColors.textPrimary),
        ],
      ),
    );
  }

  Widget _buildPhoneField() {
    return AppTextField(
      controller: _phoneController,
      hintText: 'mobile number',
      keyboardType: TextInputType.phone,
      prefixIcon: const Icon(Icons.phone_outlined, size: 20, color: AppColors.greyBarelyMedium),
    );
  }

  Widget _buildEmailField() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _emailBgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _email.isEmpty ? 'Email' : _email,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.greySoft2,
                fontWeight: FontWeight.w600,
                fontSize: 14,
                letterSpacing: 0.36,
              ),
            ),
          ),
          const Icon(Icons.email_outlined, size: 20, color: AppColors.greySoft2),
        ],
      ),
    );
  }

  Widget _buildNextButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        width: double.infinity,
        height: 63,
        child: AppButton(
          label: _saving ? 'Saving...' : 'Next',
          onPressed: _saving ? null : _onNext,
        ),
      ),
    );
  }

  Future<void> _onNext() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name.')),
      );
      return;
    }
    if (name.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name must be at least 2 characters.')),
      );
      return;
    }

    setState(() => _saving = true);
    final phone = _phoneController.text.trim();
    final ok = await AccountSetupRepository().saveUserInfo(
      name: name,
      email: _email,
      phone: phone.isEmpty ? null : phone,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      context.push(AppRoutes.accountSetupPreferable);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save. Please try again.')),
      );
    }
  }
}
