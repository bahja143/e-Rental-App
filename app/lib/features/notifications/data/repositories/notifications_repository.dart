import '../../../../core/network/api_client.dart';
import '../models/notification_item.dart';
import '../../widgets/notification_card.dart';

class NotificationsRepository {
  NotificationsRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<NotificationItem>> getNotifications() async {
    var requestSucceeded = false;
    try {
      final response = await _apiClient.getJsonList('/notifications');
      requestSucceeded = true;
      final items = response
          .whereType<Map<String, dynamic>>()
          .map(_toNotificationItem)
          .where((e) => e.id.isNotEmpty && e.title.isNotEmpty)
          .toList();
      if (items.isNotEmpty) return items;
      return const <NotificationItem>[];
    } catch (_) {
      // Keep app usable while backend endpoint is not ready.
    }
    if (requestSucceeded) return const <NotificationItem>[];
    return _fallback;
  }

  NotificationItem _toNotificationItem(Map<String, dynamic> json) {
    final createdAt = DateTime.tryParse('${json['createdAt'] ?? ''}');
    return NotificationItem.fromJson({
      'id': '${json['id'] ?? ''}',
      'type': _normalizeType('${json['type'] ?? ''}'),
      'title': '${json['title'] ?? ''}',
      'body': '${json['message'] ?? json['body'] ?? ''}',
      'time': _relativeTime(createdAt),
      'avatarText': _avatarText(json),
      'period': _period(createdAt),
      'imageUrl': json['imageUrl'],
    });
  }

  String _normalizeType(String value) {
    switch (value.toLowerCase()) {
      case 'review':
        return 'review';
      case 'sold':
      case 'sale':
      case 'rented':
        return 'sold';
      case 'favorite':
      case 'favourite':
        return 'favorite';
      default:
        return 'message';
    }
  }

  String _avatarText(Map<String, dynamic> json) {
    final user = json['user'];
    if (user is Map<String, dynamic>) {
      final name = '${user['name'] ?? ''}'.trim();
      if (name.isNotEmpty) return name.substring(0, 1).toUpperCase();
    }
    final title = '${json['title'] ?? ''}'.trim();
    if (title.isNotEmpty) return title.substring(0, 1).toUpperCase();
    return '•';
  }

  String _period(DateTime? dateTime) {
    if (dateTime == null) return 'Today';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dateTime.year, dateTime.month, dateTime.day);
    if (target == today) return 'Today';
    if (target == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return 'Older notifications';
  }

  String _relativeTime(DateTime? dateTime) {
    if (dateTime == null) return 'Just now';
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hour ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays} days ago';
  }

  static const List<NotificationItem> _fallback = [
    NotificationItem(
      id: 'n1',
      type: NotificationType.message,
      title: 'Emmett Perry',
      body: 'Just messaged you. Check the message in message tab.',
      time: '10 mins ago',
      avatarText: 'E',
      period: 'Today',
      bodyBoldParts: ['message'],
    ),
    NotificationItem(
      id: 'n2',
      type: NotificationType.review,
      title: 'Geraldo',
      body: 'Just giving 5 Star review on your listing Fairview Apartment',
      time: '40 mins ago',
      avatarText: 'G',
      period: 'Today',
      imageUrl: 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=200',
      bodyBoldParts: ['5', 'Star', 'Fairview Apartment'],
    ),
    NotificationItem(
      id: 'n3',
      type: NotificationType.sold,
      title: 'Walter Lindsey',
      body: 'Just buy your listing Schoolview House',
      time: '4 hours ago',
      avatarText: 'W',
      period: 'Today',
      imageUrl: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=200',
      bodyBoldParts: ['Schoolview House'],
    ),
    NotificationItem(
      id: 'n4',
      type: NotificationType.favorite,
      title: 'Velma Cole',
      body: 'Just favorited your listing Schoolview House',
      time: '2 Days ago',
      avatarText: 'V',
      period: 'Older notifications',
      imageUrl: 'https://images.unsplash.com/photo-1600566753190-17f0baa2a6c3?w=200',
      bodyBoldParts: ['Schoolview House'],
    ),
  ];
}
