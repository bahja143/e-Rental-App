class AppSettings {
  const AppSettings({
    required this.language,
    required this.darkMode,
    required this.notificationsEnabled,
  });

  final String language;
  final bool darkMode;
  final bool notificationsEnabled;

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      language: '${json['language'] ?? 'English'}',
      darkMode: json['darkMode'] == true,
      notificationsEnabled: json['notificationsEnabled'] != false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'language': language,
      'darkMode': darkMode,
      'notificationsEnabled': notificationsEnabled,
    };
  }

  AppSettings copyWith({
    String? language,
    bool? darkMode,
    bool? notificationsEnabled,
  }) {
    return AppSettings(
      language: language ?? this.language,
      darkMode: darkMode ?? this.darkMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}
