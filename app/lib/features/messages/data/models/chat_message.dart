class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.message,
    required this.time,
    required this.isMe,
  });

  final String id;
  final String message;
  final String time;
  final bool isMe;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: '${json['id'] ?? ''}',
      message: '${json['message'] ?? ''}',
      time: '${json['time'] ?? ''}',
      isMe: json['isMe'] == true,
    );
  }
}
