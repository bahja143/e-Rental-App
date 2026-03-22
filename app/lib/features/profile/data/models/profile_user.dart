class ProfileUser {
  const ProfileUser({
    required this.name,
    required this.email,
    this.avatarUrl,
    this.phone,
    this.lookingFor,
    this.availableBalance = 0,
    this.pendingBalance = 0,
  });

  final String name;
  final String email;
  final String? avatarUrl;
  final String? phone;
  /// User intent: buy, sale, rent, monitor_my_property, just_look_around
  final String? lookingFor;
  final double availableBalance;
  final double pendingBalance;

  factory ProfileUser.fromJson(Map<String, dynamic> json) {
    return ProfileUser(
      name: '${json['name'] ?? ''}',
      email: '${json['email'] ?? ''}',
      avatarUrl: json['profile_picture_url'] == null ? null : '${json['profile_picture_url']}',
      phone: json['phone'] == null ? null : '${json['phone']}',
      lookingFor: json['looking_for'] == null ? null : '${json['looking_for']}',
      availableBalance: _toDouble(json['available_balance']),
      pendingBalance: _toDouble(json['pending_balance']),
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }
}
