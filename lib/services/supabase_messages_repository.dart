import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/message.dart';

class SupabaseMessagesRepository {
  SupabaseMessagesRepository(this._client);

  final SupabaseClient _client;
  final _uuid = const Uuid();
  static const String _table = 'messages';

  Future<List<Message>> fetchMessages(String conversationId) async {
    final rows = await _client
        .from(_table)
        .select('id, conversation_id, sender_id, body, message_type, media_url, timestamp')
        .eq('conversation_id', conversationId)
        .order('timestamp', ascending: true);
    return rows
        .map((row) => _mapMessage(Map<String, dynamic>.from(row as Map)))
        .toList(growable: false);
  }

  Future<Message> sendMessage({
    required String conversationId,
    required String senderId,
    required String body,
    MessageContentType type = MessageContentType.text,
    String? attachmentUrl,
  }) async {
    final messageId = _uuid.v4();
    final payload = <String, dynamic>{
      'id': messageId,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'body': body,
      'message_type': _contentTypeToString(type),
      if (attachmentUrl != null) 'media_url': attachmentUrl,
    };
    await _client.from(_table).insert(payload);
    return Message(
      id: messageId,
      conversationId: conversationId,
      senderId: senderId,
      body: body,
      timestamp: DateTime.now(),
      type: type,
      attachmentPath: attachmentUrl,
    );
  }

  Message _mapMessage(Map<String, dynamic> row) {
    return Message(
      id: row['id'] as String,
      conversationId: row['conversation_id'] as String,
      senderId: row['sender_id'] as String? ?? '',
      body: row['body'] as String? ?? '',
      timestamp: DateTime.tryParse(row['timestamp'] as String? ?? '') ?? DateTime.now(),
      type: _parseContentType(row['message_type'] as String?),
      attachmentPath: row['media_url'] as String?,
    );
  }

  MessageContentType _parseContentType(String? raw) {
    switch (raw) {
      case 'image':
        return MessageContentType.image;
      case 'video':
        return MessageContentType.video;
      case 'animation':
        return MessageContentType.animation;
      case 'emoji':
        return MessageContentType.emoji;
      default:
        return MessageContentType.text;
    }
  }

  String _contentTypeToString(MessageContentType type) {
    switch (type) {
      case MessageContentType.image:
        return 'image';
      case MessageContentType.video:
        return 'video';
      case MessageContentType.animation:
        return 'animation';
      case MessageContentType.emoji:
        return 'emoji';
      case MessageContentType.text:
        return 'text';
    }
  }
}
