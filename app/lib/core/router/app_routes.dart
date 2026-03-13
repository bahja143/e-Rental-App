class AppRoutes {
  AppRoutes._();

  static const welcome = '/';
  static const choice = '/choice';
  static const loginOption = '/login-option';
  static const login = '/login';
  static const register = '/register';
  static const otp = '/otp';
  static const faq = '/faq';

  static const home = '/home';
  static const search = '/search';
  static const saved = '/saved';
  static const profile = '/profile';
  static const notifications = '/notifications';
  static const settings = '/settings';
  static const editProfile = '/edit-profile';
  static const explore = '/explore';
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
  static String agentProfile(String id) => '$agent/$id';
  static String locationDetail(String name) => '$location/$name';
  static String chatDetail(String id, {String? name}) {
    if (name == null || name.isEmpty) return '$chat/$id';
    return '$chat/$id?name=${Uri.encodeComponent(name)}';
  }
  static String transactionSummaryForEstate(String estateId) => '$transactionSummary?estateId=$estateId';
  static String otpForEmail(String email) => '$otp?email=${Uri.encodeComponent(email)}';
}
