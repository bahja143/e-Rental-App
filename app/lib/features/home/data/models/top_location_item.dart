class TopLocationItem {
  const TopLocationItem({
    required this.name,
    required this.avatarUrl,
  });

  final String name;
  final String avatarUrl;

  factory TopLocationItem.fromJson(Map<String, dynamic> json) {
    return TopLocationItem(
      name: '${json['name'] ?? ''}',
      avatarUrl: '${json['avatarUrl'] ?? ''}',
    );
  }
}
