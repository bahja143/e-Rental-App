class ProfileUser {
  const ProfileUser({
    required this.name,
    required this.email,
    this.avatarUrl,
  });

  final String name;
  final String email;
  final String? avatarUrl;

  factory ProfileUser.fromJson(Map<String, dynamic> json) {
    return ProfileUser(
      name: '${json['name'] ?? ''}',
      email: '${json['email'] ?? ''}',
      avatarUrl: json['avatarUrl'] == null ? null : '${json['avatarUrl']}',
    );
  }
}
