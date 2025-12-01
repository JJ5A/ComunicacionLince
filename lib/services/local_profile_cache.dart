import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile.dart';

class LocalProfileCache {
  const LocalProfileCache();

  static const String _lastUserKey = 'cl_cached_user_id';
  static const String _profileKeyPrefix = 'cl_cached_profile_';

  Future<void> saveProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastUserKey, profile.id);
    await prefs.setString('$_profileKeyPrefix${profile.id}', jsonEncode(profile.toMap()));
  }

  Future<UserProfile?> readProfile(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_profileKeyPrefix$userId');
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return UserProfile.fromMap(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearProfile(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_profileKeyPrefix$userId');
    final lastUserId = prefs.getString(_lastUserKey);
    if (lastUserId == userId) {
      await prefs.remove(_lastUserKey);
    }
  }
}
