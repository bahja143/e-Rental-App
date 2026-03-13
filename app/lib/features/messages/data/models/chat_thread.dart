class ChatThread {
  const ChatThread({
    required this.id,
    required this.name,
    required this.message,
    required this.time,
    required this.unread,
  });

  final String id;
  final String name;
  final String message;
  final String time;
  final int unread;

  factory ChatThread.fromJson(Map<String, dynamic> json) {
    return ChatThread(
      id: '${json['id'] ?? ''}',
      name: '${json['name'] ?? ''}',
      message: '${json['message'] ?? ''}',
      time: '${json['time'] ?? ''}',
      unread: _toInt(json['unread']),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }
}
