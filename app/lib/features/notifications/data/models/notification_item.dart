import '../../widgets/notification_card.dart';

class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.time,
    required this.avatarText,
    required this.period,
    this.imageUrl,
    this.avatarUrl,
    this.bodyBoldParts = const [],
  });

  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final String time;
  final String avatarText;
  final String period; // e.g. "Today", "Yesterday", "Older notifications"
  final String? imageUrl;
  final String? avatarUrl;
  /// Substrings in body to render in bold (e.g. listing name, star rating)
  final List<String> bodyBoldParts;

  bool get isUnread => time.contains('min') || time.contains('hour');

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    final boldRaw = json['bodyBoldParts'];
    final bodyBoldParts = boldRaw is List
        ? boldRaw.map((e) => '$e').where((e) => e.isNotEmpty).toList()
        : <String>[];
    return NotificationItem(
      id: '${json['id'] ?? ''}',
      type: _parseType('${json['type'] ?? ''}'),
      title: '${json['title'] ?? ''}',
      body: '${json['body'] ?? ''}',
      time: '${json['time'] ?? ''}',
      avatarText: '${json['avatarText'] ?? ''}',
      period: '${json['period'] ?? 'Today'}',
      imageUrl: json['imageUrl'] == null ? null : '${json['imageUrl']}',
      avatarUrl: json['avatarUrl'] == null ? null : '${json['avatarUrl']}',
      bodyBoldParts: bodyBoldParts,
    );
  }

  static NotificationType _parseType(String value) {
    switch (value.toLowerCase()) {
      case 'message':
        return NotificationType.message;
      case 'review':
        return NotificationType.review;
      case 'sold':
        return NotificationType.sold;
      case 'favorite':
        return NotificationType.favorite;
      default:
        return NotificationType.message;
    }
  }
}
