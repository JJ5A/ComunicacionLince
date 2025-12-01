import 'message.dart';

class Conversation {
  const Conversation({
    required this.id,
    required this.title,
    required this.participantIds,
    this.isGroup = false,
    this.hidePhoneNumbers = false,
    this.lastMessage,
    this.isPinned = false,
    this.isMuted = false,
  });

  final String id;
  final String title;
  final List<String> participantIds;
  final bool isGroup;
  final bool hidePhoneNumbers;
  final Message? lastMessage;
  final bool isPinned;
  final bool isMuted;

  Conversation copyWith({
    String? title,
    List<String>? participantIds,
    bool? isGroup,
    bool? hidePhoneNumbers,
    Message? lastMessage,
    bool? isPinned,
    bool? isMuted,
  }) {
    return Conversation(
      id: id,
      title: title ?? this.title,
      participantIds: participantIds ?? this.participantIds,
      isGroup: isGroup ?? this.isGroup,
      hidePhoneNumbers: hidePhoneNumbers ?? this.hidePhoneNumbers,
      lastMessage: lastMessage ?? this.lastMessage,
      isPinned: isPinned ?? this.isPinned,
      isMuted: isMuted ?? this.isMuted,
    );
  }
}
