import 'onboarding_data.dart';

/// Holds onboarding data in memory as user moves through choice -> preferable -> location.
/// Set after Firebase OTP verification, read/updated by each screen, submitted at end.
class OnboardingSession {
  OnboardingSession._();

  static OnboardingData? _data;

  static OnboardingData? get data => _data;

  static void set(OnboardingData d) {
    _data = d;
  }

  static void clear() {
    _data = null;
  }
}
