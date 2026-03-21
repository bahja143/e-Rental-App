class AppRoutes {
  AppRoutes._();

  static const welcome = '/';
  static const choice = '/choice';
  static const loginOption = '/login-option';
  static const login = '/login';
  static const register = '/register';
  static const otp = '/otp';
  static const phoneVerification = '/phone-verification';
  static const faq = '/faq';

  static const home = '/home';
  static const search = '/search';
  /// Figma `24:3566` / `24:3583` — opened from home search (list/grid results).
  static const searchResults = '/search-results';
  /// Figma `28:4432` — full-screen map for a listing (`ListingFullMapScreen`).
  static const listingMap = '/listing-map';
  static const saved = '/saved';
  static const profile = '/profile';
  static const notifications = '/notifications';
  static const settings = '/settings';
  static const editProfile = '/edit-profile';
  static const explore = '/explore';
  static const topLocations = '/top-locations';
  static const topAgents = '/top-agents';
  static const messages = '/messages';
  static const addEstate = '/add-estate';

  static const accountSetupUser = '/account-setup/user';
  static const accountSetupLocation = '/account-setup/location';
  static const accountSetupIntent = '/account-setup/intent';
  static const accountSetupPreferable = '/account-setup/preferable';
  static const accountSetupPayment = '/account-setup/payment';
  static const accountSetupSuccess = '/account-setup/success';

  static const transactionSummary = '/transaction/summary';
  static const transactionSuccess = '/transaction/success';

  static const estate = '/estate';
  static const agent = '/agent';
  static const location = '/location';
  static const chat = '/chat';

  static String estateDetail(String id) => '$estate/$id';

  /// Figma `28:4414` — all reviews for a listing.
  static String estateReviews(String id, {String? title}) {
    final t = title?.trim() ?? '';
    if (t.isEmpty) return '$estate/$id/reviews';
    return '$estate/$id/reviews?title=${Uri.encodeComponent(t)}';
  }
  static String agentProfile(String id, {int? rank}) {
    if (rank != null) return '$agent/$id?rank=$rank';
    return '$agent/$id';
  }
  static String locationDetail(String name, {int? rank}) {
    if (rank != null) return '$location/$name?rank=$rank';
    return '$location/$name';
  }
  static String chatDetail(String id, {String? name}) {
    if (name == null || name.isEmpty) return '$chat/$id';
    return '$chat/$id?name=${Uri.encodeComponent(name)}';
  }
  static String transactionSummaryForEstate(String estateId) => '$transactionSummary?estateId=$estateId';
  static String otpForEmail(String email) => '$otp?email=${Uri.encodeComponent(email)}';
  static String phoneVerificationForLogin(String phone) =>
      '$phoneVerification?phone=${Uri.encodeComponent(phone)}&mode=login';

  static String searchResultsRoute({String? q}) {
    if (q == null || q.trim().isEmpty) return searchResults;
    return '$searchResults?q=${Uri.encodeComponent(q.trim())}';
  }

  static String phoneVerificationRoute({
    required String phone,
    required String name,
    required String email,
    String? profilePictureUrl,
  }) {
    final params = <String, String>{
      'phone': phone,
      'name': name,
      'email': email,
    };
    if (profilePictureUrl != null && profilePictureUrl.isNotEmpty) {
      params['profilePictureUrl'] = profilePictureUrl;
    }
    final q = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
    return '$phoneVerification?$q';
  }

  static String registerWithGoogleRoute({
    required String name,
    required String email,
    String? phone,
    String? profilePictureUrl,
  }) {
    final params = <String, String>{
      'name': name,
      'email': email,
      'emailDisabled': '1',
    };
    if (phone != null && phone.isNotEmpty) params['phone'] = phone;
    if (profilePictureUrl != null && profilePictureUrl.isNotEmpty) params['profilePictureUrl'] = profilePictureUrl;
    final q = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
    return '$register?$q';
  }
}
