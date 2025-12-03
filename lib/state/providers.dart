import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_controller.dart';
import 'app_state.dart';
import '../services/supabase_contacts_repository.dart';
import '../services/supabase_conversations_repository.dart';
import '../services/supabase_messages_repository.dart';
import '../services/supabase_profile_store.dart';
import '../services/supabase_profiles_repository.dart';
import '../services/supabase_storage_service.dart';

final supabaseClientProvider = Provider<SupabaseClient?>((ref) {
  try {
    return Supabase.instance.client;
  } catch (_) {
    return null;
  }
});

final supabaseProfileStoreProvider = Provider<SupabaseProfileStore?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  return SupabaseProfileStore(client);
});

final profilesRepositoryProvider = Provider<SupabaseProfilesRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  return SupabaseProfilesRepository(client);
});

final contactsRepositoryProvider = Provider<SupabaseContactsRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  return SupabaseContactsRepository(client);
});

final conversationsRepositoryProvider = Provider<SupabaseConversationsRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  return SupabaseConversationsRepository(client);
});

final messagesRepositoryProvider = Provider<SupabaseMessagesRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  return SupabaseMessagesRepository(client);
});


final storageServiceProvider = Provider<SupabaseStorageService?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  return SupabaseStorageService(client);
});

final appControllerProvider = StateNotifierProvider<AppController, AppState>(
  (ref) => AppController(
    supabaseClient: ref.watch(supabaseClientProvider),
    profileStore: ref.watch(supabaseProfileStoreProvider),
    profilesRepository: ref.watch(profilesRepositoryProvider),
    contactsRepository: ref.watch(contactsRepositoryProvider),
    conversationsRepository: ref.watch(conversationsRepositoryProvider),
    messagesRepository: ref.watch(messagesRepositoryProvider),
    storageService: ref.watch(storageServiceProvider),
  ),
);
