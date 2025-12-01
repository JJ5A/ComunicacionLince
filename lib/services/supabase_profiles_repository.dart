import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_profile.dart';

class SupabaseProfilesRepository {
  SupabaseProfilesRepository(this._client);

  final SupabaseClient _client;
  static const String _table = 'profiles';

  Future<UserProfile?> fetchProfile(String id) async {
    final data = await _client.from(_table).select().eq('id', id).maybeSingle();
    if (data == null) return null;
    return UserProfile.fromMap(Map<String, dynamic>.from(data as Map));
  }

  Future<List<UserProfile>> fetchDirectory({String? search, int limit = 200}) async {
    final rows = await _client.from(_table).select().order('display_name', ascending: true).limit(limit);
    final profiles = rows
      .map((row) => UserProfile.fromMap(Map<String, dynamic>.from(row as Map)))
        .toList(growable: false);
    if (search == null || search.trim().isEmpty) {
      return profiles;
    }
    final needle = search.trim().toLowerCase();
    return profiles
        .where(
          (profile) => profile.displayName.toLowerCase().contains(needle) ||
              profile.email.toLowerCase().contains(needle) ||
              profile.phoneNumber.toLowerCase().contains(needle),
        )
        .toList(growable: false);
  }

  Future<UserProfile?> findByPhone(String phoneNumber) async {
    final data = await _client
      .from(_table)
      .select()
      .eq('phone_number', phoneNumber.trim())
      .maybeSingle();
    if (data == null) return null;
    return UserProfile.fromMap(Map<String, dynamic>.from(data as Map));
  }

  Future<UserProfile?> findByEmail(String email) async {
    final data = await _client.from(_table).select().eq('email', email.trim()).maybeSingle();
    if (data == null) return null;
    return UserProfile.fromMap(Map<String, dynamic>.from(data as Map));
  }

  Future<void> upsertProfile(UserProfile profile) {
    return _client.from(_table).upsert(profile.toMap());
  }

  Future<void> updateProfile(
    String id, {
    String? displayName,
    String? bio,
    String? specialty,
    String? avatarPath,
  }) async {
    final payload = <String, dynamic>{
      if (displayName != null) 'display_name': displayName,
      if (bio != null) 'bio': bio,
      if (specialty != null) 'specialty': specialty,
      if (avatarPath != null) 'avatar_path': avatarPath,
    };
    if (payload.isEmpty) return;
    await _client.from(_table).update(payload).eq('id', id);
  }
}
