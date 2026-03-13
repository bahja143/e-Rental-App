import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../data/models/app_settings.dart';
import '../data/repositories/settings_repository.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final Future<AppSettings> _settingsFuture;
  AppSettings? _settings;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _settingsFuture = SettingsRepository().getSettings();
    _settingsFuture.then((value) {
      if (!mounted) return;
      setState(() => _settings = value);
    });
  }

  Future<void> _saveSettings() async {
    final settings = _settings;
    if (settings == null) return;
    setState(() => _saving = true);
    final ok = await SettingsRepository().saveSettings(settings);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Settings saved' : 'Could not save settings')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
      ),
      body: FutureBuilder<AppSettings>(
        future: _settingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && _settings == null) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          final settings = _settings ?? snapshot.data ?? const AppSettings(language: 'English', darkMode: false, notificationsEnabled: true);
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _SettingsSection(
                title: 'Account',
                items: [
                  _SettingsTile(icon: Icons.person_outline, label: 'Edit Profile', onTap: () => context.push(AppRoutes.editProfile)),
                  _SettingsTile(icon: Icons.notifications_outlined, label: 'Notifications', onTap: () => context.push(AppRoutes.notifications)),
                  _SettingsTile(icon: Icons.lock_outline, label: 'Privacy & Security', onTap: () {}),
                ],
              ),
              const SizedBox(height: 24),
              _SettingsSection(
                title: 'Preferences',
                items: [
                  _SettingsTile(icon: Icons.language, label: 'Language', trailing: settings.language, onTap: () {}),
                  _SettingsSwitchTile(
                    icon: Icons.dark_mode_outlined,
                    label: 'Dark Mode',
                    value: settings.darkMode,
                    onChanged: (v) => setState(() => _settings = settings.copyWith(darkMode: v)),
                  ),
                  _SettingsSwitchTile(
                    icon: Icons.notifications_active_outlined,
                    label: 'Push Notifications',
                    value: settings.notificationsEnabled,
                    onChanged: (v) => setState(() => _settings = settings.copyWith(notificationsEnabled: v)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _SettingsSection(
                title: 'Support',
                items: [
                  _SettingsTile(icon: Icons.help_outline, label: 'Help & FAQ', onTap: () => context.push(AppRoutes.faq)),
                  _SettingsTile(icon: Icons.description_outlined, label: 'Terms of Service', onTap: () {}),
                ],
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _saving ? null : _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(54),
                ),
                child: Text(_saving ? 'Saving...' : 'Save Preferences'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.items});

  final String title;
  final List<Widget> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.greyBarelyMedium,
              ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    this.trailing,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.greyBarelyMedium, size: 22),
      title: Text(label, style: Theme.of(context).textTheme.bodyLarge),
      trailing: trailing != null
          ? Text(trailing!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.greyBarelyMedium))
          : const Icon(Icons.chevron_right, size: 20, color: AppColors.greyBarelyMedium),
      onTap: onTap,
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  const _SettingsSwitchTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Icon(icon, color: AppColors.greyBarelyMedium, size: 22),
      title: Text(label, style: Theme.of(context).textTheme.bodyLarge),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primary,
    );
  }
}
