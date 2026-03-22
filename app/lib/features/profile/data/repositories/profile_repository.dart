import '../../../../core/network/api_client.dart';
import '../models/profile_user.dart';

class ProfileRepository {
  ProfileRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<ProfileUser> getMyProfile() async {
    try {
      final response = await _apiClient.getJson('/auth/me');
      final user = response['user'];
      final userMap = user is Map<String, dynamic> ? user : response;
      final profile = ProfileUser(
        name: '${userMap['name'] ?? ''}',
        email: '${userMap['email'] ?? ''}',
        avatarUrl: userMap['profile_picture_url'] == null ? null : '${userMap['profile_picture_url']}',
        phone: userMap['phone'] == null ? null : '${userMap['phone']}',
        lookingFor: userMap['looking_for'] == null ? null : '${userMap['looking_for']}',
        availableBalance: ProfileUser.fromJson(userMap).availableBalance,
        pendingBalance: ProfileUser.fromJson(userMap).pendingBalance,
      );
      if (profile.name.isNotEmpty && profile.email.isNotEmpty) return profile;
    } catch (_) {
      // Return empty profile on failure so UI can show retry/error states.
    }
    return const ProfileUser(name: '', email: '');
  }

  Future<bool> updateMyProfile({
    required String name,
    required String email,
    String? phone,
  }) async {
    try {
      final me = await _apiClient.getJson('/auth/me');
      final user = me['user'];
      final userMap = user is Map<String, dynamic> ? user : me;
      final userId = '${userMap['id'] ?? ''}';
      if (userId.isEmpty) return false;

      await _apiClient.putJson('/users/$userId', body: {
        'name': name,
        'email': email.toLowerCase(),
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      });
      return true;
    } catch (_) {
      return false;
    }
  }
}
