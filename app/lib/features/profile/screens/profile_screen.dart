import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/data/repositories/auth_repository.dart';
import '../../../shared/widgets/bottom_nav_bar.dart';
import '../data/models/profile_user.dart';
import '../data/repositories/profile_repository.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<ProfileUser> _profileFuture;
  bool _signingOut = false;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile();
  }

  Future<ProfileUser> _loadProfile() => ProfileRepository().getMyProfile();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.go(AppRoutes.home),
        ),
        title: const Text('Profile'),
      ),
      body: FutureBuilder<ProfileUser>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (!snapshot.hasData ||
              snapshot.data == null ||
              snapshot.data!.name.isEmpty ||
              snapshot.data!.email.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_off_outlined, size: 48, color: AppColors.greyBarelyMedium),
                    const SizedBox(height: 12),
                    Text('Could not load profile', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text('Check your connection and try again.', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => setState(() => _profileFuture = _loadProfile()),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final profile = snapshot.data!;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.3),
                    child: Text(
                      profile.name.isEmpty ? 'U' : profile.name[0].toUpperCase(),
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            color: AppColors.primary,
                            fontSize: 40,
                          ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(profile.name, style: Theme.of(context).textTheme.titleLarge),
                  Text(profile.email, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 32),
                  _ProfileTile(icon: Icons.person_outline, label: 'Edit Profile', onTap: () => context.push(AppRoutes.editProfile)),
                  _ProfileTile(icon: Icons.favorite_outline, label: 'Saved Properties', onTap: () => context.go(AppRoutes.saved)),
                  _ProfileTile(icon: Icons.chat_bubble_outline, label: 'Messages', onTap: () => context.push(AppRoutes.messages)),
                  _ProfileTile(icon: Icons.settings_outlined, label: 'Settings', onTap: () => context.push(AppRoutes.settings)),
                  _ProfileTile(icon: Icons.add_home_work_outlined, label: 'Add Property', onTap: () => context.push(AppRoutes.addEstate)),
                  _ProfileTile(icon: Icons.help_outline, label: 'Help & FAQ', onTap: () => context.push(AppRoutes.faq)),
                  const Spacer(),
                  TextButton(
                    onPressed: _signingOut ? null : _signOut,
                    child: Text(
                      _signingOut ? 'Signing out...' : 'Sign Out',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 3),
    );
  }

  Future<void> _signOut() async {
    setState(() => _signingOut = true);
    await AuthRepository().logout();
    if (!mounted) return;
    setState(() => _signingOut = false);
    context.go(AppRoutes.welcome);
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.greyBarelyMedium),
      title: Text(label, style: Theme.of(context).textTheme.bodyLarge),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.greyBarelyMedium),
      onTap: onTap,
    );
  }
}
