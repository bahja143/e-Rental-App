/// Holds user data collected during post-OTP onboarding flow.
/// Passed through choice -> preferable -> location, then submitted once.
class OnboardingData {
  const OnboardingData({
    required this.name,
    required this.email,
    required this.phone,
    this.lookingFor = 'just_look_around',
    this.lookingForList = const [],
    this.propertyTypes = const [],
    this.city,
    this.lat,
    this.lng,
    this.profilePictureUrl,
  });

  final String name;
  final String email;
  final String phone;
  /// Primary intent (first selected, for backward compat).
  final String lookingFor;
  /// Full list of selected intents (buy, sale, rent, etc).
  final List<String> lookingForList;
  final List<String> propertyTypes;
  final String? city;
  final double? lat;
  final double? lng;
  /// Profile image URL (e.g. from Google). When set, used instead of uploaded file.
  final String? profilePictureUrl;

  OnboardingData copyWith({
    String? name,
    String? email,
    String? phone,
    String? lookingFor,
    List<String>? lookingForList,
    List<String>? propertyTypes,
    String? city,
    double? lat,
    double? lng,
    String? profilePictureUrl,
  }) =>
      OnboardingData(
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        lookingFor: lookingFor ?? this.lookingFor,
        lookingForList: lookingForList ?? this.lookingForList,
        propertyTypes: propertyTypes ?? this.propertyTypes,
        city: city ?? this.city,
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
        profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      );
}
