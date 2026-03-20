class TopAgentItem {
  const TopAgentItem({
    required this.id,
    required this.name,
    required this.avatarUrl,
    this.rating,
    this.soldCount,
  });

  final String id;
  final String name;
  final String avatarUrl;
  final double? rating;
  final int? soldCount;

  factory TopAgentItem.fromJson(Map<String, dynamic> json) {
    final r = json['rating'];
    final s = json['soldCount'];
    return TopAgentItem(
      id: '${json['id'] ?? ''}',
      name: '${json['name'] ?? ''}',
      avatarUrl: '${json['avatarUrl'] ?? ''}',
      rating: r != null ? (r is num ? r.toDouble() : double.tryParse('$r')) : null,
      soldCount: s != null ? (s is int ? s : int.tryParse('$s')) : null,
    );
  }
}
