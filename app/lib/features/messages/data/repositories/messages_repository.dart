import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_session.dart';
import '../models/chat_message.dart';
import '../models/chat_thread.dart';

class MessagesRepository {
  MessagesRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<ChatThread>> getThreads() async {
    try {
      final response = await _apiClient.getJsonList('/chat/conversations');
      final rawThreads = response.whereType<Map<String, dynamic>>().toList();
      final threads = <ChatThread>[];
      for (final raw in rawThreads) {
        final mapped = await _toThread(raw);
        if (mapped.id.isNotEmpty && mapped.name.isNotEmpty) {
          threads.add(mapped);
        }
      }
      return threads;
    } catch (_) {
      return const <ChatThread>[];
    }
  }

  Future<List<ChatMessage>> getConversation(String threadId) async {
    try {
      final response = await _apiClient.getJsonList('/chat/conversations/$threadId/messages');
      final messages = response
          .whereType<Map<String, dynamic>>()
          .map(_toMessage)
          .where((e) => e.id.isNotEmpty && e.message.isNotEmpty)
          .toList();
      return messages;
    } catch (_) {
      return const <ChatMessage>[];
    }
  }

  Future<ChatThread> _toThread(Map<String, dynamic> json) async {
    final lastMessage = json['last_message'];
    final listingId = '${json['listing_id'] ?? ''}'.trim();
    String title = listingId.isNotEmpty ? 'Listing #$listingId' : 'Conversation';
    final participants = json['participants'];
    final myId = ApiSession.currentUserId ?? '';
    if (participants is List) {
      final others = participants
          .map((e) => '$e')
          .where((e) => e.isNotEmpty && e != myId)
          .toList();
      if (others.isNotEmpty) {
        try {
          final user = await _apiClient.getJson('/users/${others.first}');
          final name = '${user['name'] ?? ''}'.trim();
          if (name.isNotEmpty) {
            title = name;
          }
        } catch (_) {
          // Keep computed fallback title when user lookup fails.
        }
      }
    }
    final messageText = lastMessage is Map<String, dynamic> ? '${lastMessage['text'] ?? ''}' : '';
    final updatedAt = DateTime.tryParse('${json['updated_at'] ?? ''}');
    final unread = _unreadForCurrentUser(json['unread_counts']);

    return ChatThread(
      id: '${json['_id'] ?? json['id'] ?? ''}',
      name: title,
      message: messageText.isEmpty ? 'No messages yet' : messageText,
      time: _relativeTime(updatedAt),
      unread: unread,
    );
  }

  ChatMessage _toMessage(Map<String, dynamic> json) {
    final createdAt = DateTime.tryParse('${json['created_at'] ?? ''}');
    final senderId = '${json['sender_id'] ?? ''}';
    final myId = ApiSession.currentUserId ?? '';
    return ChatMessage(
      id: '${json['_id'] ?? json['id'] ?? ''}',
      message: '${json['text'] ?? json['message'] ?? ''}',
      time: _clockTime(createdAt),
      isMe: senderId.isNotEmpty && senderId == myId,
    );
  }

  int _unreadForCurrentUser(dynamic unreadCounts) {
    final myId = ApiSession.currentUserId;
    if (myId == null || myId.isEmpty) {
      return 0;
    }
    if (unreadCounts is Map<String, dynamic>) {
      final value = unreadCounts[myId];
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse('$value') ?? 0;
    }
    return 0;
  }

  String _relativeTime(DateTime? dateTime) {
    if (dateTime == null) return 'now';
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return 'Yesterday';
  }

  String _clockTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final h = dateTime.hour.toString().padLeft(2, '0');
    final m = dateTime.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
