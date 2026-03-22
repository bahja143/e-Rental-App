import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/remote_image.dart';
import '../data/models/profile_user.dart';
import '../data/repositories/profile_repository.dart';
import '../utils/profile_avatar_letter.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  late final Future<ProfileUser> _profileFuture;
  String _avatarUrl = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _profileFuture = ProfileRepository().getMyProfile();
    _profileFuture.then((profile) {
      if (!mounted) return;
      _nameController.text = profile.name;
      _emailController.text = profile.email;
      _phoneController.text = profile.phone?.trim().isNotEmpty == true ? profile.phone!.trim() : '+252 61 123 4567';
      _avatarUrl = profile.avatarUrl?.trim() ?? '';
      setState(() {});
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

  void _showSocialAction(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label is not connected yet.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<ProfileUser>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && _nameController.text.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          final letter = profileAvatarLetterFromName(_nameController.text);
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Column(
                children: [
                  SizedBox(
                    height: 50,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Center(
                          child: Text(
                            'Edit Profile',
                            style: GoogleFonts.lato(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              letterSpacing: 0.54,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => context.pop(),
                              borderRadius: BorderRadius.circular(25),
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: const BoxDecoration(
                                  color: AppColors.greySoft1,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  size: 18,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: SizedBox(
                      width: 100,
                      height: 100,
                      child: _avatarUrl.isNotEmpty
                          ? RemoteImage(
                              url: _avatarUrl,
                              fit: BoxFit.cover,
                              errorWidget: _EditAvatarFallback(letter: letter),
                            )
                          : _EditAvatarFallback(letter: letter),
                    ),
                  ),
                  const SizedBox(height: 31),
                  _EditProfileField(
                    controller: _nameController,
                    icon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 15),
                  _EditProfileField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    icon: Icons.call_outlined,
                  ),
                  const SizedBox(height: 15),
                  _EditProfileField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    icon: Icons.mail_outline_rounded,
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: _SocialButton(
                          dark: true,
                          icon: Icons.g_mobiledata_rounded,
                          label: 'Unlink',
                          onTap: () => _showSocialAction('Google unlink'),
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: _SocialButton(
                          dark: false,
                          icon: Icons.facebook_rounded,
                          label: 'Link',
                          onTap: () => _showSocialAction('Facebook link'),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  AppButton(
                    label: _saving ? 'Updating...' : 'Update',
                    onPressed: _saving ? null : _save,
                    isLoading: _saving,
                    width: double.infinity,
                    height: 70,
                    borderRadius: 10,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EditAvatarFallback extends StatelessWidget {
  const _EditAvatarFallback({required this.letter});

  final String letter;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.greySoft2,
      alignment: Alignment.center,
      child: Text(
        letter.isEmpty ? 'U' : letter,
        style: GoogleFonts.lato(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _EditProfileField extends StatelessWidget {
  const _EditProfileField({
    required this.controller,
    required this.icon,
    this.keyboardType,
  });

  final TextEditingController controller;
  final IconData icon;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.greySoft1,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              style: GoogleFonts.lato(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                letterSpacing: 0.36,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          Icon(icon, size: 20, color: AppColors.textPrimary),
        ],
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.dark,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool dark;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = dark ? Colors.white : AppColors.textPrimary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            color: dark ? AppColors.primaryBackground : AppColors.greySoft1,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 25, color: dark ? Colors.amberAccent : Colors.blue),
              const SizedBox(width: 10),
              Text(
                label,
                style: GoogleFonts.lato(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                  letterSpacing: 0.36,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
