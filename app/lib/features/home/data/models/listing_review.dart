/// Single review on a listing — API + **Figma `28:4414`** mock data.
class ListingReview {
  const ListingReview({
    required this.name,
    required this.rating,
    required this.text,
    required this.dateLabel,
    this.avatarUrl,
    this.imageUrls = const [],
  });

  final String name;
  final int rating;
  final String text;
  final String dateLabel;
  /// `Photos / User - Small` — Figma `28:4414`.
  final String? avatarUrl;
  /// Optional review photos — `Card / Review - Estate` gallery row.
  final List<String> imageUrls;

  factory ListingReview.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    final userMap = user is Map<String, dynamic> ? user : const <String, dynamic>{};
    final createdAt = DateTime.tryParse('${json['createdAt'] ?? json['created_at'] ?? ''}');
    final avatar = userMap['profile_picture_url'] ?? userMap['avatar_url'] ?? userMap['avatarUrl'];
    final attachments = json['attachments'] ?? json['images'];
    final urls = <String>[];
    if (attachments is List) {
      for (final e in attachments) {
        final s = '$e'.trim();
        if (s.isNotEmpty) urls.add(s);
      }
    }
    return ListingReview(
      name: '${userMap['name'] ?? 'User'}',
      rating: _toInt(json['rating']),
      text: '${json['comment'] ?? json['text'] ?? ''}',
      dateLabel: _dateLabel(createdAt),
      avatarUrl: avatar != null && '$avatar'.trim().isNotEmpty ? '$avatar'.trim() : null,
      imageUrls: urls,
    );
  }
  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  static String _dateLabel(DateTime? date) {
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inDays >= 1) return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
    if (diff.inHours >= 1) return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    if (diff.inMinutes >= 1) return '${diff.inMinutes} min ago';
    return 'Just now';
  }
}
