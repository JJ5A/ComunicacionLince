import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_profile.dart';

class SupabaseContactsRepository {
  SupabaseContactsRepository(this._client);

  final SupabaseClient _client;
  static const String _table = 'contacts';

  Future<List<UserProfile>> fetchContacts(String ownerId) async {
    final rows = await _client
        .from(_table)
        .select('contact:profiles!contacts_contact_id_fkey(*)')
        .eq('owner_id', ownerId)
        .order('created_at', ascending: true);
    return rows
        .map((row) => UserProfile.fromMap(Map<String, dynamic>.from(row['contact'] as Map)))
        .toList(growable: false);
  }

  Future<void> addContact({required String ownerId, required String contactId}) async {
    await _client.from(_table).upsert(
      <String, dynamic>{
        'owner_id': ownerId,
        'contact_id': contactId,
      },
      onConflict: 'owner_id,contact_id',
    );
  }

  Future<void> removeContact({required String ownerId, required String contactId}) async {
    await _client
        .from(_table)
        .delete()
        .eq('owner_id', ownerId)
        .eq('contact_id', contactId);
  }
}
