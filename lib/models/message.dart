enum MessageContentType { text, image, video, animation, emoji }

class Message {
  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.body,
    required this.timestamp,
    required this.type,
    this.attachmentPath,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String body;
  final DateTime timestamp;
  final MessageContentType type;
  final String? attachmentPath;

  bool get hasAttachment => type != MessageContentType.text || attachmentPath != null;

  Message copyWith({
    String? body,
    DateTime? timestamp,
    MessageContentType? type,
    String? attachmentPath,
  }) {
    return Message(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      body: body ?? this.body,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      attachmentPath: attachmentPath ?? this.attachmentPath,
    );
  }
}
