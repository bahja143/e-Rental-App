class TopAgentItem {
  const TopAgentItem({
    required this.id,
    required this.name,
    required this.avatarUrl,
  });

  final String id;
  final String name;
  final String avatarUrl;

  factory TopAgentItem.fromJson(Map<String, dynamic> json) {
    return TopAgentItem(
      id: '${json['id'] ?? ''}',
      name: '${json['name'] ?? ''}',
      avatarUrl: '${json['avatarUrl'] ?? ''}',
    );
  }
}
