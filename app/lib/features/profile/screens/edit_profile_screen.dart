import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../data/models/profile_user.dart';
import '../data/repositories/profile_repository.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController(text: '+252 61 123 4567');
  late final Future<ProfileUser> _profileFuture;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _profileFuture = ProfileRepository().getMyProfile();
    _profileFuture.then((profile) {
      if (!mounted) return;
      _nameController.text = profile.name;
      _emailController.text = profile.email;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    if (name.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and email are required.')),
      );
      return;
    }

    setState(() => _saving = true);
    final ok = await ProfileRepository().updateMyProfile(
      name: name,
      email: email,
      phone: _phoneController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      context.pop();
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not save profile. Please try again.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
      ),
      body: FutureBuilder<ProfileUser>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 55,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.3),
                        child: Text(
                          _nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : 'U',
                          style: Theme.of(context).textTheme.displayMedium?.copyWith(color: AppColors.primary, fontSize: 40),
                        ),
                      ),
                      const Positioned(
                        right: 0,
                        bottom: 0,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.primary,
                          child: Icon(Icons.camera_alt, size: 20, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
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
                  hintText: 'Phone',
                  keyboardType: TextInputType.phone,
                  prefixIcon: const Icon(Icons.phone_outlined, size: 20, color: AppColors.greyBarelyMedium),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    label: _saving ? 'Saving...' : 'Save Changes',
                    isLoading: _saving,
                    onPressed: _saving ? null : _save,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
