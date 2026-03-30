import '../../../../core/network/api_client.dart';

class AccountSetupRepository {
  AccountSetupRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<String?> _currentUserId() async {
    final me = await _apiClient.getJson('/auth/me');
    final user = me['user'];
    if (user is Map<String, dynamic>) {
      final id = '${user['id'] ?? ''}';
      if (id.isNotEmpty) return id;
    }
    return null;
  }

  /// Fetch current user info for setup screens (name, email, phone, profile_picture_url)
  Future<Map<String, dynamic>?> getCurrentUserInfo() async {
    try {
      final me = await _apiClient.getJson('/auth/me');
      final user = me['user'];
      return user is Map<String, dynamic> ? user : null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> saveLocationWithCoordinates({
    String? city,
    double? lat,
    double? lng,
  }) async {
    try {
      final userId = await _currentUserId();
      if (userId == null) return false;
      final body = <String, dynamic>{};
      if (city != null && city.isNotEmpty) body['city'] = city;
      if (lat != null && lng != null) {
        body['lat'] = lat;
        body['lng'] = lng;
      }
      if (body.isEmpty) return false;
      await _apiClient.putJson('/users/$userId', body: body);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> saveUserInfo({
    required String name,
    required String email,
    String? phone,
  }) async {
    try {
      final userId = await _currentUserId();
      if (userId == null) return false;
      final body = <String, dynamic>{
        'name': name,
        'email': email.toLowerCase(),
        'looking_for_set': true,
      };
      if (phone != null) body['phone'] = phone.isEmpty ? null : phone;
      await _apiClient.putJson('/users/$userId', body: body);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> saveLocation(String location) async {
    try {
      final userId = await _currentUserId();
      if (userId == null) return false;
      await _apiClient.putJson('/users/$userId', body: {
        'city': location,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Saves user intent(s): buy, sale, rent, monitor_my_property, just_look_around.
  /// Pass a list to store multiple; pass [value] for single selection.
  Future<bool> saveLookingFor(String lookingFor) async {
    return saveLookingForOptions([lookingFor]);
  }

  /// Saves multiple intents. Primary (looking_for) is first in list.
  Future<bool> saveLookingForOptions(List<String> options) async {
    try {
      final userId = await _currentUserId();
      if (userId == null) return false;
      final list = options.where((v) => v.isNotEmpty).toList();
      final primary = list.isNotEmpty ? list.first : 'just_look_around';
      await _apiClient.putJson('/users/$userId', body: {
        'looking_for': primary,
        'looking_for_options': list,
        'looking_for_set': true,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> savePreferences(List<String> propertyTypes) async {
    try {
      final userId = await _currentUserId();
      if (userId == null) return false;
      await _apiClient.putJson('/users/$userId', body: {
        'category_set': propertyTypes.isNotEmpty,
        'preferred_property_types': propertyTypes,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> savePayment({
    required String method,
    required String holderName,
    String? email,
    String? cardNumber,
    String? expiry,
    String? cvc,
  }) async {
    try {
      final userId = await _currentUserId();
      if (userId == null) return false;
      final normalizedMethod = method.toLowerCase();
      final normalizedHolder = holderName.trim();
      if (normalizedHolder.length < 2) return false;
      final bankName = normalizedMethod == 'paypal'
          ? 'PayPal'
          : normalizedMethod == 'visa'
              ? 'Visa'
              : 'Mastercard';
      final accountNo = normalizedMethod == 'paypal'
          ? (email?.trim().toLowerCase() ?? '')
          : _normalizeAccountNo(cardNumber);
      final branch = normalizedMethod == 'paypal'
          ? 'Online'
          : (expiry?.trim().isNotEmpty == true ? expiry!.trim() : 'Card');
      if (accountNo.isEmpty || branch.length < 2) return false;

      await _apiClient.postJson('/user-bank-accounts', body: {
        'user_id': int.tryParse(userId) ?? userId,
        'bank_name': bankName,
        'branch': branch,
        'account_no': accountNo,
        'account_holder_name': normalizedHolder,
        'is_default': true,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  String _normalizeAccountNo(String? cardNumber) {
    final digits = (cardNumber ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length >= 8) {
      return digits.substring(0, digits.length > 120 ? 120 : digits.length);
    }
    return '';
  }
}
