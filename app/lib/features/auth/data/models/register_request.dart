/// Registration payload matching backend User model (POST /api/users)
class RegisterRequest {
  const RegisterRequest({
    required this.name,
    required this.email,
    required this.password,
    this.phone,
    this.profilePictureUrl,
    this.preferredPropertyTypes,
    this.lookingForOptions,
    this.city,
    this.lat,
    this.lng,
    this.lookingFor = 'just_look_around',
    this.lookingForSet = true,
    this.categorySet = false,
  });

  final String name;
  final String email;
  final String password;
  final String? phone;
  final String? profilePictureUrl;
  final List<String>? preferredPropertyTypes;
  /// Multiple intents (buy, sale, rent, etc). Primary is lookingFor.
  final List<String>? lookingForOptions;
  final String? city;
  final double? lat;
  final double? lng;
  final String lookingFor;
  final bool lookingForSet;
  final bool categorySet;

  Map<String, dynamic> toJson() => {
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
        if (phone != null && phone!.trim().isNotEmpty) 'phone': _sanitizePhone(phone!),
        if (profilePictureUrl != null && profilePictureUrl!.trim().isNotEmpty) 'profile_picture_url': profilePictureUrl!.trim(),
        if (preferredPropertyTypes != null && preferredPropertyTypes!.isNotEmpty) 'preferred_property_types': preferredPropertyTypes!,
        if (lookingForOptions != null && lookingForOptions!.isNotEmpty) 'looking_for_options': lookingForOptions!,
        if (city != null && city!.trim().isNotEmpty)
          'city': city!.trim().length > 255 ? city!.trim().substring(0, 255) : city!.trim(),
        if (lat != null && lng != null) 'lat': lat,
        if (lat != null && lng != null) 'lng': lng,
        'looking_for': lookingFor,
        'looking_for_set': lookingForSet,
        'category_set': categorySet,
        'role': 'user',
        'user_type': 'buyer',
      };

  static String _sanitizePhone(String phone) {
    return phone.replaceAll(RegExp(r'[^\d+\-\s()]'), '');
  }
}
