class ProfileUser {
  const ProfileUser({
    required this.name,
    required this.email,
    this.avatarUrl,
    this.lookingFor,
  });

  final String name;
  final String email;
  final String? avatarUrl;
  /// User intent: buy, sale, rent, monitor_my_property, just_look_around
  final String? lookingFor;

  factory ProfileUser.fromJson(Map<String, dynamic> json) {
    return ProfileUser(
      name: '${json['name'] ?? ''}',
      email: '${json['email'] ?? ''}',
      avatarUrl: json['profile_picture_url'] == null ? null : '${json['profile_picture_url']}',
      lookingFor: json['looking_for'] == null ? null : '${json['looking_for']}',
    );
  }
}
