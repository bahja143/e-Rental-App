import '../../../../core/network/api_client.dart';
import '../models/notification_item.dart';

class NotificationsRepository {
  NotificationsRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<NotificationItem>> getNotifications() async {
    try {
      final response = await _apiClient.getJsonList('/notifications');
      final items = response
          .whereType<Map<String, dynamic>>()
          .map(_toNotificationItem)
          .where((e) => e.id.isNotEmpty && e.title.isNotEmpty)
          .toList();
      return items;
    } catch (_) {
      return const <NotificationItem>[];
    }
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
}
