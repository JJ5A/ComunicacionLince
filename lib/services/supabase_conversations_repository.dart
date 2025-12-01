import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/conversation.dart';
import '../models/message.dart';

class SupabaseConversationsRepository {
  SupabaseConversationsRepository(this._client);

  final SupabaseClient _client;
  final _uuid = const Uuid();

  static const String _conversationsTable = 'conversations';
  static const String _participantsTable = 'conversation_participants';
  static const String _messagesTable = 'messages';

  Future<List<Conversation>> fetchConversations(String profileId) async {
    final participantRows = await _client
        .from(_participantsTable)
        .select('conversation_id')
        .eq('profile_id', profileId);
    final conversationIds = participantRows
        .map((row) => row['conversation_id'] as String?)
        .whereType<String>()
        .toSet()
        .toList(growable: false);
    if (conversationIds.isEmpty) {
      return const <Conversation>[];
    }

    final conversations = await Future.wait(
      conversationIds.map((conversationId) async {
        final conversationRow = await _client
            .from(_conversationsTable)
            .select('id,title,is_group,hide_phone_numbers,updated_at')
            .eq('id', conversationId)
            .single();
        final participantsRows = await _client
            .from(_participantsTable)
            .select('profile_id')
            .eq('conversation_id', conversationId);
        final lastMessageRow = await _client
            .from(_messagesTable)
            .select('id, conversation_id, sender_id, body, message_type, media_url, timestamp')
            .eq('conversation_id', conversationId)
            .order('timestamp', ascending: false)
            .limit(1)
            .maybeSingle();

        return Conversation(
          id: conversationRow['id'] as String,
          title: conversationRow['title'] as String? ?? 'Conversación',
          participantIds: participantsRows
              .map((row) => row['profile_id'] as String?)
              .whereType<String>()
              .toList(growable: false),
          isGroup: conversationRow['is_group'] as bool? ?? false,
          hidePhoneNumbers: conversationRow['hide_phone_numbers'] as bool? ?? false,
          lastMessage: lastMessageRow == null
              ? null
              : _mapMessage(Map<String, dynamic>.from(lastMessageRow as Map)),
        );
      }),
    );

    final sorted = List<Conversation>.from(conversations)
      ..sort((a, b) {
        final aTime = a.lastMessage?.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.lastMessage?.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
    return sorted;
  }

  Future<Conversation> createDirectConversation({
    required String creatorId,
    required String contactId,
    required String title,
  }) async {
    final conversationId = _uuid.v4();
    await _client
        .from(_conversationsTable)
        .insert(<String, dynamic>{
          'id': conversationId,
          'title': title,
          'is_group': false,
          'created_by': creatorId,
        });
    await _client.from(_participantsTable).insert(<Map<String, dynamic>>[
      <String, dynamic>{
        'conversation_id': conversationId,
        'profile_id': creatorId,
      },
      <String, dynamic>{
        'conversation_id': conversationId,
        'profile_id': contactId,
      },
    ]);
    return Conversation(
      id: conversationId,
      title: title,
      participantIds: <String>{creatorId, contactId}.toList(growable: false),
      isGroup: false,
    );
  }

  Future<Conversation> createGroupConversation({
    required String creatorId,
    required String title,
    required List<String> participantIds,
    bool hidePhoneNumbers = false,
  }) async {
    final uniqueParticipants = <String>{creatorId, ...participantIds};
    final conversationId = _uuid.v4();
    await _client
        .from(_conversationsTable)
        .insert(<String, dynamic>{
          'id': conversationId,
          'title': title,
          'is_group': true,
          'hide_phone_numbers': hidePhoneNumbers,
          'created_by': creatorId,
        });
    await _client.from(_participantsTable).insert(
      uniqueParticipants
          .map(
            (participantId) => <String, dynamic>{
              'conversation_id': conversationId,
              'profile_id': participantId,
            },
          )
          .toList(growable: false),
    );
    return Conversation(
      id: conversationId,
      title: title,
      participantIds: uniqueParticipants.toList(growable: false),
      isGroup: true,
      hidePhoneNumbers: hidePhoneNumbers,
    );
  }

  Future<void> updatePrivacy({
    required String conversationId,
    required bool hidePhoneNumbers,
  }) async {
    await _client
        .from(_conversationsTable)
        .update(<String, dynamic>{'hide_phone_numbers': hidePhoneNumbers})
        .eq('id', conversationId);
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
}
