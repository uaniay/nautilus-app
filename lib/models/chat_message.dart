enum MessageDirection { input, output }

class ChatMessage {
  final String sessionId;
  final MessageDirection direction;
  final String content;
  final DateTime timestamp;

  ChatMessage({
    required this.sessionId,
    required this.direction,
    required this.content,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
