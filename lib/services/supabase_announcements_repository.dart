import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/announcement.dart';

class SupabaseAnnouncementsRepository {
  SupabaseAnnouncementsRepository(this._client);

  final SupabaseClient _client;
  static const String _table = 'announcements';
  static const String _receiptsTable = 'announcement_receipts';

  Future<List<Announcement>> fetchAnnouncements() async {
    final rows = await _client
        .from(_table)
        .select('id, title, body, author_id, created_at, receipts:announcement_receipts(profile_id)')
        .order('created_at', ascending: false);
    return rows.map(_mapAnnouncement).toList(growable: false);
  }

  Future<Announcement> publishAnnouncement({
    required String authorId,
    required String title,
    required String body,
    String category = 'General',
  }) async {
    final inserted = await _client
        .from(_table)
        .insert(<String, dynamic>{
          'author_id': authorId,
          'title': title,
          'body': body,
        })
        .select('id, title, body, author_id, created_at')
        .single();
    return Announcement(
      id: inserted['id'] as String,
      title: inserted['title'] as String? ?? title,
      body: inserted['body'] as String? ?? body,
      authorId: inserted['author_id'] as String? ?? authorId,
      createdAt: DateTime.parse(inserted['created_at'] as String),
      category: category,
      acknowledgedBy: <String>{authorId},
    );
  }

  Future<void> acknowledgeAnnouncement({
    required String announcementId,
    required String profileId,
  }) async {
    await _client.from(_receiptsTable).upsert(<String, dynamic>{
      'announcement_id': announcementId,
      'profile_id': profileId,
    });
  }

  Announcement _mapAnnouncement(dynamic row) {
    final map = Map<String, dynamic>.from(row as Map);
    final receipts = (map['receipts'] as List?)?.whereType<Map<String, dynamic>>().toList() ??
      const <Map<String, dynamic>>[];
    final acknowledged = receipts
        .map((receipt) => receipt['profile_id'] as String?)
        .whereType<String>()
        .toSet();
    return Announcement(
      id: map['id'] as String,
      title: map['title'] as String? ?? 'Aviso',
      body: map['body'] as String? ?? '',
      authorId: map['author_id'] as String? ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
      category: 'General', // Default value since column doesn't exist in DB
      acknowledgedBy: acknowledged,
    );
  }
}
