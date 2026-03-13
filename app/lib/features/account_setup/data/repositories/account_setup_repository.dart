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

  Future<bool> saveUserInfo({
    required String name,
    required String email,
    required String phone,
  }) async {
    try {
      final userId = await _currentUserId();
      if (userId == null) return false;
      await _apiClient.putJson('/users/$userId', body: {
        'name': name,
        'email': email.toLowerCase(),
        'phone': phone,
        'looking_for_set': true,
      });
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

  /// Saves user intent: buy, sale, rent, monitor_my_property, just_look_around
  Future<bool> saveLookingFor(String lookingFor) async {
    try {
      final userId = await _currentUserId();
      if (userId == null) return false;
      await _apiClient.putJson('/users/$userId', body: {
        'looking_for': lookingFor,
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
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> savePayment({
    required String method,
    String? cardNumber,
    String? expiry,
    String? cvc,
  }) async {
    try {
      final userId = await _currentUserId();
      if (userId == null) return false;

      const holderName = 'Primary Account Holder';
      final normalizedMethod = method.toLowerCase();
      await _apiClient.postJson('/user-bank-accounts', body: {
        'user_id': int.tryParse(userId) ?? userId,
        'bank_name': normalizedMethod == 'paypal' ? 'PayPal' : 'Card Payment',
        'branch': normalizedMethod == 'paypal' ? 'Online' : 'Main',
        'account_no': _normalizeAccountNo(cardNumber),
        'account_holder_name': holderName,
        if (normalizedMethod != 'paypal' && cvc != null && cvc.isNotEmpty) 'swift_code': 'HANTUS33',
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
      return digits.substring(0, digits.length > 20 ? 20 : digits.length);
    }
    return '100020003000';
  }
}
