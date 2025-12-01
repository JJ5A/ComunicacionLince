import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_profile.dart';

class SupabaseProfileStore {
  const SupabaseProfileStore(this._client);

  final SupabaseClient _client;
  static const String _table = 'profiles';

  Future<UserProfile?> fetchProfile(String userId) async {
    final data = await _client.from(_table).select().eq('id', userId).maybeSingle();
    if (data == null) return null;
    return UserProfile.fromMap(Map<String, dynamic>.from(data));
  }

  Future<void> upsertProfile(UserProfile profile) {
    return _client.from(_table).upsert(profile.toMap());
  }
}
