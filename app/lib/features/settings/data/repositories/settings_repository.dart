import '../../../../core/network/api_client.dart';
import '../models/app_settings.dart';

class SettingsRepository {
  SettingsRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<AppSettings> getSettings() async {
    try {
      final response = await _apiClient.getJson('/chat/settings');
      return AppSettings(
        language: 'English',
        darkMode: false,
        notificationsEnabled: response['videoSharingEnabled'] != false,
      );
    } catch (_) {
      return const AppSettings(
        language: 'English',
        darkMode: false,
        notificationsEnabled: true,
      );
    }
  }

  Future<bool> saveSettings(AppSettings settings) async {
    // Backend currently exposes read-only chat settings, so save remains local-safe.
    return true;
  }
}
