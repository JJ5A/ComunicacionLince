import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase hide User;
import 'package:uuid/uuid.dart';

import '../models/announcement.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../models/user_profile.dart';
import '../services/supabase_announcements_repository.dart';
import '../services/supabase_contacts_repository.dart';
import '../services/supabase_conversations_repository.dart';
import '../services/supabase_messages_repository.dart';
import '../services/supabase_profile_store.dart';
import '../services/supabase_profiles_repository.dart';
import '../services/supabase_storage_service.dart';
import 'app_state.dart';

class AppController extends StateNotifier<AppState> {
  AppController({
    FirebaseAuth? auth,
    SupabaseProfileStore? profileStore,
    supabase.SupabaseClient? supabaseClient,
    SupabaseProfilesRepository? profilesRepository,
    SupabaseContactsRepository? contactsRepository,
    SupabaseConversationsRepository? conversationsRepository,
    SupabaseMessagesRepository? messagesRepository,
    SupabaseAnnouncementsRepository? announcementsRepository,
    SupabaseStorageService? storageService,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _profileStore = profileStore,
        _supabaseClient = supabaseClient,
        _profilesRepository = profilesRepository,
        _contactsRepository = contactsRepository,
        _conversationsRepository = conversationsRepository,
        _messagesRepository = messagesRepository,
        _announcementsRepository = announcementsRepository,
        _storageService = storageService,
        super(AppState.initial()) {
    _authSubscription = _auth.authStateChanges().listen(_onAuthStateChanged);
    _setupRealtimeSubscriptions();
  }

  final FirebaseAuth _auth;
  final SupabaseProfileStore? _profileStore;
  final supabase.SupabaseClient? _supabaseClient;
  final SupabaseProfilesRepository? _profilesRepository;
  final SupabaseContactsRepository? _contactsRepository;
  final SupabaseConversationsRepository? _conversationsRepository;
  final SupabaseMessagesRepository? _messagesRepository;
  final SupabaseAnnouncementsRepository? _announcementsRepository;
  final SupabaseStorageService? _storageService;
  final _uuid = const Uuid();
  StreamSubscription<User?>? _authSubscription;
  supabase.RealtimeChannel? _messagesChannel;
  supabase.RealtimeChannel? _conversationsChannel;
  supabase.RealtimeChannel? _participantsChannel;
  supabase.RealtimeChannel? _announcementsChannel;
  supabase.RealtimeChannel? _contactsChannel;

  Future<void> _loadRemoteData(UserProfile profile) async {
    if (kDebugMode) {
      debugPrint('🔄 Iniciando carga de datos remotos para: ${profile.displayName}');
      debugPrint('Repositorios disponibles:');
      debugPrint('  - Profiles: ${_profilesRepository != null}');
      debugPrint('  - Contacts: ${_contactsRepository != null}');
      debugPrint('  - Conversations: ${_conversationsRepository != null}');
      debugPrint('  - Messages: ${_messagesRepository != null}');
      debugPrint('  - Announcements: ${_announcementsRepository != null}');
    }
    
    if (_profilesRepository == null ||
        _contactsRepository == null ||
        _conversationsRepository == null ||
        _messagesRepository == null ||
        _announcementsRepository == null) {
      if (kDebugMode) {
        debugPrint('⚠️ Algunos repositorios son null, saltando sincronización remota');
      }
      state = state.copyWith(
        currentUser: profile,
        directory: _mergeDirectory(profile),
        step: AuthStep.home,
        pendingPhone: profile.phoneNumber,
        verificationId: null,
        resendToken: null,
        isLoading: false,
        errorMessage: null,
      );
      return;
    }
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      
      if (kDebugMode) {
        debugPrint('📥 Obteniendo datos de Supabase...');
      }
      
      final directoryFuture = _profilesRepository.fetchDirectory();
      final contactsFuture = _contactsRepository.fetchContacts(profile.id);
      final conversationsFuture = _conversationsRepository.fetchConversations(profile.id);
      final announcementsFuture = _announcementsRepository.fetchAnnouncements();

      final results = await Future.wait<dynamic>(
        <Future<dynamic>>[directoryFuture, contactsFuture, conversationsFuture, announcementsFuture],
      );
      
      if (kDebugMode) {
        debugPrint('✅ Datos obtenidos de Supabase');
        debugPrint('  - Directory: ${(results[0] as List).length} perfiles');
        debugPrint('  - Contacts: ${(results[1] as List).length} contactos');
        debugPrint('  - Conversations: ${(results[2] as List).length} conversaciones');
        debugPrint('  - Announcements: ${(results[3] as List).length} avisos');
      }

      final fetchedDirectory = List<UserProfile>.from(results[0] as List<UserProfile>);
      final contacts = List<UserProfile>.from(results[1] as List<UserProfile>);
      final conversations = List<Conversation>.from(results[2] as List<Conversation>);
      final announcements = List<Announcement>.from(results[3] as List<Announcement>);

      final contactIds = contacts.map((contact) => contact.id).toList(growable: false);
      final updatedProfile = profile.copyWith(contactIds: contactIds);
      
      if (kDebugMode) {
        debugPrint('📋 Actualizando perfil con contactIds: $contactIds');
        debugPrint('📋 Contactos cargados: ${contacts.map((c) => c.displayName).join(", ")}');
      }
      
      final mergedDirectory = _mergeDirectory(
        updatedProfile,
        extra: <UserProfile>[...fetchedDirectory, ...contacts],
      );
      
      if (kDebugMode) {
        debugPrint('📋 Directory final tiene ${mergedDirectory.length} perfiles');
        debugPrint('📋 IDs en directory: ${mergedDirectory.map((p) => p.id).join(", ")}');
      }

      final messageEntries = await Future.wait<MapEntry<String, List<Message>>>(
        conversations.map((conversation) async {
          final messages = await _messagesRepository.fetchMessages(conversation.id);
          return MapEntry<String, List<Message>>(conversation.id, messages);
        }),
      );
      final messagesMap = <String, List<Message>>{for (final entry in messageEntries) entry.key: entry.value};

      state = state.copyWith(
        currentUser: updatedProfile,
        directory: mergedDirectory,
        conversations: conversations,
        messages: messagesMap,
        announcements: announcements,
        step: AuthStep.home,
        pendingPhone: updatedProfile.phoneNumber,
        verificationId: null,
        resendToken: null,
        isLoading: false,
        errorMessage: null,
      );
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ Error en sincronización con Supabase:');
        debugPrint('Error: $error');
        debugPrint('StackTrace: $stackTrace');
      }
      _setError('No se pudo sincronizar información desde Supabase. Mostrando datos en caché.');
      state = state.copyWith(
        currentUser: profile,
        directory: _mergeDirectory(profile),
        conversations: state.conversations,
        messages: state.messages,
        announcements: state.announcements,
        step: AuthStep.home,
        pendingPhone: profile.phoneNumber,
        verificationId: null,
        resendToken: null,
        isLoading: false,
      );
    }
  }

  Future<void> sendVerificationCode(String phoneNumber) async {
    final sanitized = phoneNumber.trim();
    if (sanitized.isEmpty) {
      _setError('Ingresa un número de teléfono válido.');
      return;
    }
    
    // Validar formato internacional (+52...)
    if (!sanitized.startsWith('+')) {
      _setError('El número debe incluir el código de país (ej. +52 para México).');
      return;
    }
    
    // Validar longitud mínima
    final digitsOnly = sanitized.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length < 10) {
      _setError('El número debe tener al menos 10 dígitos.');
      return;
    }
    
    if (kDebugMode) {
      debugPrint('Enviando código de verificación a: $sanitized');
    }
    final previousResendToken = state.resendToken;
    state = state.copyWith(isLoading: true, errorMessage: null, verificationId: null);
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: sanitized,
        timeout: const Duration(seconds: 60),
        forceResendingToken: previousResendToken,
        verificationCompleted: (credential) async {
          try {
            await _auth.signInWithCredential(credential);
            state = state.copyWith(pendingPhone: sanitized);
          } on FirebaseAuthException catch (error) {
            _setError(error.message ?? 'No se pudo completar la verificación automática.');
          } finally {
            state = state.copyWith(isLoading: false);
          }
        },
        verificationFailed: (error) {
          String errorMsg = 'Error al enviar el código.';
          if (error.code == 'invalid-phone-number') {
            errorMsg = 'Formato de número inválido. Usa +52 seguido de 10 dígitos.';
          } else if (error.code == 'too-many-requests') {
            errorMsg = 'Demasiados intentos. Espera unos minutos e intenta de nuevo.';
          } else if (error.message != null) {
            errorMsg = error.message!;
          }
          _setError(errorMsg);
          state = state.copyWith(isLoading: false);
        },
        codeSent: (verificationId, resendToken) {
          state = state.copyWith(
            isLoading: false,
            step: AuthStep.otp,
            pendingPhone: sanitized,
            verificationId: verificationId,
            resendToken: resendToken,
            errorMessage: null,
          );
        },
        codeAutoRetrievalTimeout: (verificationId) {
          state = state.copyWith(verificationId: verificationId);
        },
      );
    } on FirebaseAuthException catch (error) {
      _setError(error.message ?? 'No se pudo enviar el código.');
      state = state.copyWith(isLoading: false);
    } catch (_) {
      _setError('Algo salió mal al enviar el SMS.');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> verifyCode(String code) async {
    final verificationId = state.verificationId;
    if (verificationId == null) {
      _setError('Solicita un código antes de verificar.');
      return;
    }
    final trimmed = code.trim();
    if (trimmed.isEmpty) {
      _setError('Ingresa el código enviado por SMS.');
      return;
    }
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: trimmed,
      );
      await _auth.signInWithCredential(credential);
      final nextStep = state.currentUser == null ? AuthStep.profile : AuthStep.home;
      state = state.copyWith(isLoading: false, step: nextStep, errorMessage: null);
    } on FirebaseAuthException catch (error) {
      _setError(error.message ?? 'Código incorrecto.');
      state = state.copyWith(isLoading: false);
    } catch (_) {
      _setError('No se pudo verificar el código.');
      state = state.copyWith(isLoading: false);
    }
  }

  /// Sube una imagen de avatar a Supabase Storage y retorna la URL pública
  Future<String?> uploadAvatar(File imageFile) async {
    if (_supabaseClient == null) {
      debugPrint('❌ No hay cliente de Supabase disponible');
      return null;
    }

    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      debugPrint('❌ No hay usuario autenticado');
      return null;
    }

    try {
      // Generar nombre único para el archivo
      final fileName = '${firebaseUser.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = 'avatars/$fileName';

      debugPrint('📤 Subiendo imagen a Supabase Storage: $filePath');

      // Subir archivo
      await _supabaseClient.storage
          .from('avatars')
          .upload(filePath, imageFile, fileOptions: supabase.FileOptions(upsert: true));

      // Obtener URL pública
      final publicUrl = _supabaseClient.storage
          .from('avatars')
          .getPublicUrl(filePath);

      debugPrint('✅ Imagen subida exitosamente: $publicUrl');
      return publicUrl;
    } catch (e, stack) {
      debugPrint('❌ Error subiendo imagen: $e');
      debugPrint('StackTrace: $stack');
      return null;
    }
  }

  Future<void> completeProfile({
    required String displayName,
    required String email,
    required UserRole role,
    String? avatarPath,
    String? bio,
    String? specialty,
  }) async {
    final firebaseUser = _auth.currentUser;
    final verifiedPhone = firebaseUser?.phoneNumber ?? state.pendingPhone;
    if (firebaseUser == null || verifiedPhone == null) {
      _setError('No se encontró un número verificado en la sesión.');
      return;
    }
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    final newUser = UserProfile(
      id: firebaseUser.uid,
      displayName: displayName,
      phoneNumber: verifiedPhone,
      email: email,
      role: role,
      avatarPath: avatarPath,
      bio: bio,
      specialty: specialty,
      contactIds: const <String>[],
    );
    
    // Actualizar displayName en Firebase Auth (opcional, no crítico)
    try {
      await firebaseUser.updateDisplayName(displayName);
      if (kDebugMode) {
        debugPrint('✅ DisplayName actualizado en Firebase Auth');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ No se pudo actualizar displayName en Firebase: $e');
      }
    }
    // Intentar guardar en Supabase (CRÍTICO - debe tener éxito para que el usuario sea encontrable)
    if (_profilesRepository != null) {
      try {
        if (kDebugMode) {
          debugPrint('🔄 Guardando perfil en Supabase - Teléfono: ${newUser.phoneNumber}, ID: ${newUser.id}');
          debugPrint('   Nombre: ${newUser.displayName}');
          debugPrint('   Email: ${newUser.email}');
          debugPrint('   Rol: ${newUser.role.name}');
        }
        await _profilesRepository.upsertProfile(newUser);
        if (kDebugMode) {
          debugPrint('✅ Perfil guardado exitosamente en Supabase');
        }
      } catch (e, stackTrace) {
        if (kDebugMode) {
          debugPrint('❌ Error guardando perfil en Supabase: $e');
          debugPrint('StackTrace: $stackTrace');
        }
        state = state.copyWith(isLoading: false);
        _setError('No se pudo guardar tu perfil en el servidor. Verifica tu conexión e intenta de nuevo.');
        return; // Bloquear el avance hasta que se guarde correctamente
      }
    } else {
      if (kDebugMode) {
        debugPrint('⚠️ ProfilesRepository es null - no se puede guardar en Supabase');
      }
      state = state.copyWith(isLoading: false);
      _setError('Error de configuración: no se puede conectar con el servidor.');
      return;
    }
    
    // Guardar también en cache local como respaldo
    try {
      await _profileStore?.upsertProfile(newUser);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ No se pudo guardar en profile store: $e (no crítico)');
      }
    }
    
    final updatedDirectory = List<UserProfile>.from(state.directory)..add(newUser);
    final seeded = _withWelcomeConversations(newUser, updatedDirectory);
    state = state.copyWith(
      directory: updatedDirectory,
      conversations: seeded.conversations,
      messages: seeded.messages,
      currentUser: newUser,
      step: AuthStep.home,
      pendingPhone: null,
      verificationId: null,
      resendToken: null,
      isLoading: false,
      errorMessage: null,
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
    state = state.copyWith(
      step: AuthStep.phoneEntry,
      currentUser: null,
      pendingPhone: null,
      verificationId: null,
      resendToken: null,
      errorMessage: null,
    );
  }

  Future<void> sendMessage({
    required String conversationId,
    required String text,
    MessageContentType type = MessageContentType.text,
    String? attachmentPath,
  }) async {
    final sender = state.currentUser;
    if (sender == null) return;
    final body = text.trim();
    if (body.isEmpty && attachmentPath == null) {
      _setError('Escribe un mensaje o adjunta un archivo.');
      return;
    }

    // Si hay un archivo adjunto y es imagen o video, subirlo a Storage
    String? uploadedUrl = attachmentPath;
    if (attachmentPath != null && 
        (type == MessageContentType.image || 
         type == MessageContentType.animation ||
         type == MessageContentType.video) &&
        _storageService != null &&
        !attachmentPath.startsWith('http')) {
      try {
        if (kDebugMode) {
          debugPrint('📤 Subiendo ${type == MessageContentType.video ? "video" : "imagen"} a Supabase Storage...');
        }
        uploadedUrl = await _storageService.uploadMessageImage(attachmentPath, sender.id);
        if (kDebugMode) {
          debugPrint('✅ Archivo subido: $uploadedUrl');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ Error subiendo archivo, usando path local: $e');
        }
        // Si falla, usar el path local
        uploadedUrl = attachmentPath;
      }
    }

    Message message;
    if (_messagesRepository == null) {
      message = Message(
        id: _uuid.v4(),
        conversationId: conversationId,
        senderId: sender.id,
        body: body,
        timestamp: DateTime.now(),
        type: type,
        attachmentPath: uploadedUrl,
      );
    } else {
      try {
        message = await _messagesRepository.sendMessage(
          conversationId: conversationId,
          senderId: sender.id,
          body: body,
          type: type,
          attachmentUrl: uploadedUrl,
        );
      } catch (e, stack) {
        debugPrint('❌ Error enviando mensaje: $e');
        debugPrint('StackTrace: $stack');
        _setError('No se pudo enviar el mensaje, intenta de nuevo.');
        return;
      }
    }

    _upsertMessage(message);
  }

  Future<void> addContactByPhone(String phone) async {
    final sanitized = phone.trim();
    final current = state.currentUser;
    if (current == null) return;
    
    if (sanitized.isEmpty) {
      _setError('Ingresa un número de teléfono válido.');
      return;
    }
    
    // Validar formato
    if (!sanitized.startsWith('+')) {
      _setError('El número debe incluir el código de país (ej. +52 para México).');
      return;
    }
    
    final digitsOnly = sanitized.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length < 10) {
      _setError('El número debe tener al menos 10 dígitos.');
      return;
    }
    
    if (kDebugMode) {
      debugPrint('🔍 Buscando contacto con teléfono: $sanitized');
    }
    
    UserProfile? match;
    
    // Primero intentar buscar en Supabase (perfiles completos)
    if (_profilesRepository != null) {
      try {
        match = await _profilesRepository.findByPhone(sanitized);
        if (kDebugMode) {
          debugPrint(match != null 
            ? '✅ Usuario encontrado en Supabase: ${match.displayName}' 
            : '⚠️ No se encontró perfil completo en Supabase para ese número');
        }
      } catch (error) {
        if (kDebugMode) {
          debugPrint('❌ Error al buscar en Supabase: $error');
        }
      }
    }
    
    // Si no se encontró en Supabase, buscar en el directorio local
    if (match == null) {
      match = UserProfile.findByPhone(sanitized, state.directory);
      if (kDebugMode && match != null) {
        debugPrint('✅ Usuario encontrado en directorio local: ${match.displayName}');
      }
    }
    
    // Si aún no se encuentra, informar que no está registrado
    if (match == null) {
      _setError('Este número ($sanitized) no está registrado. El usuario debe crear una cuenta primero.');
      return;
    }
    
    await _addContact(current, match);
  }

  Future<void> _addContact(UserProfile current, UserProfile? toAdd) async {
    if (toAdd == null) {
      _setError('No existe un usuario con esos datos.');
      return;
    }
    if (toAdd.id == current.id) {
      _setError('No puedes agregarte a ti mismo.');
      return;
    }
    
    // Verificar si el contacto ya existe en Supabase
    if (_contactsRepository != null) {
      try {
        final existingContacts = await _contactsRepository.fetchContacts(current.id);
        if (existingContacts.any((c) => c.id == toAdd.id)) {
          _setError('Ese contacto ya está en tu lista.');
          return;
        }
      } catch (e) {
        debugPrint('⚠️ Error verificando contactos existentes: $e');
      }
    }
    
    // También verificar en el estado local
    if (current.contactIds.contains(toAdd.id)) {
      _setError('Ese contacto ya está en tu lista.');
      return;
    }
    
    final updatedContacts = List<String>.from(current.contactIds)..add(toAdd.id);
    final updatedUser = current.copyWith(contactIds: updatedContacts);
    
    // Guardar en Supabase
    if (_contactsRepository != null) {
      try {
        await _contactsRepository.addContact(ownerId: current.id, contactId: toAdd.id);
        
        // Recargar contactos desde Supabase después de agregar
        final refreshedContacts = await _contactsRepository.fetchContacts(current.id);
        final contactIds = refreshedContacts.map((c) => c.id).toList();
        
        debugPrint('✅ Contacto agregado. Total de contactos: ${refreshedContacts.length}');
        
        // Actualizar estado con los contactos recargados
        final refreshedUser = updatedUser.copyWith(contactIds: contactIds);
        
        // Actualizar también el perfil en Supabase con la lista de contact_ids
        if (_profileStore != null) {
          await _profileStore.upsertProfile(refreshedUser);
          debugPrint('✅ Perfil actualizado con contact_ids en Supabase');
        }
        
        final directory = _mergeDirectory(refreshedUser, extra: refreshedContacts);
        state = state.copyWith(
          currentUser: refreshedUser,
          directory: directory,
          errorMessage: null,
        );
        return;
      } catch (e, stack) {
        debugPrint('❌ Error guardando contacto: $e');
        debugPrint('StackTrace: $stack');
        _setError('No se pudo guardar el contacto en Supabase.');
        return;
      }
    }
    
    // Fallback si no hay repositorio
    final directory = _mergeDirectory(updatedUser, extra: <UserProfile>[toAdd]);
    state = state.copyWith(currentUser: updatedUser, directory: directory, errorMessage: null);
  }

  void _setupRealtimeSubscriptions() {
    final client = _supabaseClient;
    if (client == null) {
      if (kDebugMode) {
        debugPrint('⚠️ No se puede configurar Realtime: cliente Supabase es null');
      }
      return;
    }

    if (kDebugMode) {
      debugPrint('🔌 Configurando suscripciones Realtime...');
    }

    _messagesChannel = client.channel('public:messages')
      ..onPostgresChanges(
        event: supabase.PostgresChangeEvent.insert,
        schema: 'public',
        table: 'messages',
        callback: _handleMessageChange,
      )
      ..onPostgresChanges(
        event: supabase.PostgresChangeEvent.update,
        schema: 'public',
        table: 'messages',
        callback: _handleMessageChange,
      )
      ..onPostgresChanges(
        event: supabase.PostgresChangeEvent.delete,
        schema: 'public',
        table: 'messages',
        callback: _handleMessageChange,
      )
      ..subscribe((status, error) {
        if (kDebugMode) {
          debugPrint('📡 Canal messages: $status ${error != null ? "- Error: $error" : ""}');
        }
      });

    _conversationsChannel = client.channel('public:conversations')
      ..onPostgresChanges(
        event: supabase.PostgresChangeEvent.insert,
        schema: 'public',
        table: 'conversations',
        callback: _handleConversationChange,
      )
      ..onPostgresChanges(
        event: supabase.PostgresChangeEvent.update,
        schema: 'public',
        table: 'conversations',
        callback: _handleConversationChange,
      )
      ..subscribe((status, error) {
        if (kDebugMode) {
          debugPrint('📡 Canal conversations: $status ${error != null ? "- Error: $error" : ""}');
        }
      });

    _participantsChannel = client.channel('public:conversation_participants')
      ..onPostgresChanges(
        event: supabase.PostgresChangeEvent.insert,
        schema: 'public',
        table: 'conversation_participants',
        callback: _handleParticipantChange,
      )
      ..onPostgresChanges(
        event: supabase.PostgresChangeEvent.delete,
        schema: 'public',
        table: 'conversation_participants',
        callback: _handleParticipantChange,
      )
      ..subscribe((status, error) {
        if (kDebugMode) {
          debugPrint('📡 Canal conversation_participants: $status ${error != null ? "- Error: $error" : ""}');
        }
      });

    _announcementsChannel = client.channel('public:announcements')
      ..onPostgresChanges(
        event: supabase.PostgresChangeEvent.insert,
        schema: 'public',
        table: 'announcements',
        callback: _handleAnnouncementChange,
      )
      ..onPostgresChanges(
        event: supabase.PostgresChangeEvent.update,
        schema: 'public',
        table: 'announcements',
        callback: _handleAnnouncementChange,
      )
      ..subscribe((status, error) {
        if (kDebugMode) {
          debugPrint('📡 Canal announcements: $status ${error != null ? "- Error: $error" : ""}');
        }
      });

    _contactsChannel = client.channel('public:contacts')
      ..onPostgresChanges(
        event: supabase.PostgresChangeEvent.insert,
        schema: 'public',
        table: 'contacts',
        callback: _handleContactsChange,
      )
      ..onPostgresChanges(
        event: supabase.PostgresChangeEvent.delete,
        schema: 'public',
        table: 'contacts',
        callback: _handleContactsChange,
      )
      ..subscribe((status, error) {
        if (kDebugMode) {
          debugPrint('📡 Canal contacts: $status ${error != null ? "- Error: $error" : ""}');
        }
      });

    if (kDebugMode) {
      debugPrint('✅ Suscripciones Realtime configuradas');
    }
  }

  void _handleMessageChange(supabase.PostgresChangePayload payload) {
    if (kDebugMode) {
      debugPrint('🔔 Cambio detectado en messages: ${payload.eventType}');
    }
    final conversationId =
        payload.newRecord['conversation_id'] as String? ?? payload.oldRecord['conversation_id'] as String?;
    if (conversationId == null) return;
    if (!state.conversations.any((conversation) => conversation.id == conversationId)) return;
    if (kDebugMode) {
      debugPrint('♻️ Refrescando mensajes para conversación: $conversationId');
    }
    unawaited(_refreshMessagesForConversation(conversationId));
  }

  void _handleConversationChange(supabase.PostgresChangePayload payload) {
    if (kDebugMode) {
      debugPrint('🔔 Cambio detectado en conversations: ${payload.eventType}');
    }
    unawaited(_refreshConversationsList());
  }

  void _handleParticipantChange(supabase.PostgresChangePayload payload) {
    if (kDebugMode) {
      debugPrint('🔔 Cambio detectado en conversation_participants: ${payload.eventType}');
    }
    final currentId = state.currentUser?.id;
    if (currentId == null) return;
    final profileId = payload.newRecord['profile_id'] as String? ?? payload.oldRecord['profile_id'] as String?;
    if (profileId != currentId) return;
    unawaited(_refreshConversationsList());
  }

  void _handleAnnouncementChange(supabase.PostgresChangePayload payload) {
    if (kDebugMode) {
      debugPrint('🔔 Cambio detectado en announcements: ${payload.eventType}');
    }
    unawaited(_refreshAnnouncements());
  }

  void _handleContactsChange(supabase.PostgresChangePayload payload) {
    if (kDebugMode) {
      debugPrint('🔔 Cambio detectado en contacts: ${payload.eventType}');
    }
    final currentId = state.currentUser?.id;
    if (currentId == null) return;
    final ownerId = payload.newRecord['owner_id'] as String? ?? payload.oldRecord['owner_id'] as String?;
    if (ownerId != currentId) return;
    unawaited(_refreshContactsDirectory());
  }

  Future<Conversation> ensureDirectConversation(String contactId) async {
    final current = state.currentUser;
    if (current == null) {
      throw StateError('No hay sesión activa');
    }
    final existing = state.conversations.firstWhere(
      (conversation) =>
          !conversation.isGroup &&
          conversation.participantIds.contains(current.id) &&
          conversation.participantIds.contains(contactId),
      orElse: () =>
          const Conversation(id: '', title: '', participantIds: <String>[]),
    );
    if (existing.id.isNotEmpty) {
      return existing;
    }

    final contact = state.directory.firstWhere((user) => user.id == contactId);
    Conversation conversation;
    if (_conversationsRepository == null) {
      conversation = Conversation(
        id: _uuid.v4(),
        title: contact.displayName,
        participantIds: <String>[current.id, contact.id],
      );
    } else {
      try {
        conversation = await _conversationsRepository.createDirectConversation(
          creatorId: current.id,
          contactId: contact.id,
          title: contact.displayName,
        );
      } catch (e, stack) {
        debugPrint('❌ Error creando conversación: $e');
        debugPrint('StackTrace: $stack');
        _setError('No se pudo crear la conversación.');
        rethrow;
      }
    }

    final updatedConversations = List<Conversation>.from(state.conversations)..add(conversation);
    state = state.copyWith(conversations: updatedConversations, errorMessage: null);

    await sendMessage(
      conversationId: conversation.id,
      text: 'Hola ${contact.displayName.split(' ').first}, ¡gracias por conectar!',
    );
    return conversation;
  }

  Future<void> createGroup({
    required String title,
    required List<String> participantIds,
    bool hidePhoneNumbers = false,
  }) async {
    final current = state.currentUser;
    if (current == null || !current.isProfessor) {
      _setError('Solo los profesores pueden crear grupos.');
      return;
    }
    if (title.trim().isEmpty || participantIds.length < 2) {
      _setError('Agrega al menos 2 participantes.');
      return;
    }
    final uniqueParticipants = <String>{current.id, ...participantIds}.toList();
    Conversation group;
    if (_conversationsRepository == null) {
      group = Conversation(
        id: _uuid.v4(),
        title: title.trim(),
        participantIds: uniqueParticipants,
        isGroup: true,
        hidePhoneNumbers: hidePhoneNumbers,
      );
    } else {
      try {
        group = await _conversationsRepository.createGroupConversation(
          creatorId: current.id,
          title: title.trim(),
          participantIds: participantIds,
          hidePhoneNumbers: hidePhoneNumbers,
        );
      } catch (_) {
        _setError('No se pudo crear el grupo.');
        return;
      }
    }

    final conversations = List<Conversation>.from(state.conversations)..add(group);
    state = state.copyWith(conversations: conversations, errorMessage: null);

    await sendMessage(
      conversationId: group.id,
      text: 'Bienvenidos al grupo ${group.title}',
    );
  }

  Future<void> toggleGroupPrivacy(String conversationId, bool hidePhones) async {
    if (_conversationsRepository != null) {
      try {
        await _conversationsRepository.updatePrivacy(
          conversationId: conversationId,
          hidePhoneNumbers: hidePhones,
        );
      } catch (_) {
        _setError('No se pudo actualizar la privacidad del grupo.');
      }
    }
    final conversations = state.conversations
        .map((conversation) => conversation.id == conversationId
            ? conversation.copyWith(hidePhoneNumbers: hidePhones)
            : conversation)
        .toList(growable: false);
    state = state.copyWith(conversations: conversations, errorMessage: null);
  }

  void toggleMute(String conversationId) {
    final conversations = state.conversations
        .map((conversation) => conversation.id == conversationId
            ? conversation.copyWith(isMuted: !conversation.isMuted)
            : conversation)
        .toList(growable: false);
    state = state.copyWith(conversations: conversations, errorMessage: null);
  }

  Future<void> _refreshMessagesForConversation(String conversationId) async {
    if (_messagesRepository == null) return;
    if (!state.conversations.any((conversation) => conversation.id == conversationId)) return;
    try {
      final messages = await _messagesRepository.fetchMessages(conversationId);
      final updatedMessages = Map<String, List<Message>>.from(state.messages)
        ..[conversationId] = messages;
      final lastMessage = messages.isNotEmpty ? messages.last : null;
      final updatedConversations = state.conversations
          .map((conversation) => conversation.id == conversationId
              ? conversation.copyWith(lastMessage: lastMessage)
              : conversation)
          .toList(growable: false);
      state = state.copyWith(messages: updatedMessages, conversations: updatedConversations);
    } catch (_) {
      _setError('No se pudo actualizar los mensajes más recientes.');
    }
  }

  Future<void> _refreshConversationsList() async {
    final current = state.currentUser;
    if (current == null || _conversationsRepository == null) return;
    try {
      final conversations = await _conversationsRepository.fetchConversations(current.id);
      Map<String, List<Message>> updatedMessages = state.messages;
      final messagesRepository = _messagesRepository;
      if (messagesRepository != null) {
        final mutableMessages = Map<String, List<Message>>.from(state.messages);
        final fetches = <Future<void>>[];
        for (final conversation in conversations) {
          if (!mutableMessages.containsKey(conversation.id)) {
            fetches.add(
              messagesRepository
                  .fetchMessages(conversation.id)
                  .then((messages) => mutableMessages[conversation.id] = messages),
            );
          }
        }
        if (fetches.isNotEmpty) {
          await Future.wait(fetches);
        }
        updatedMessages = mutableMessages;
      }
      state = state.copyWith(conversations: conversations, messages: updatedMessages);
    } catch (_) {
      _setError('No se pudo actualizar tus conversaciones.');
    }
  }

  Future<void> _refreshAnnouncements() async {
    if (_announcementsRepository == null) return;
    try {
      final announcements = await _announcementsRepository.fetchAnnouncements();
      state = state.copyWith(announcements: announcements);
    } catch (_) {
      _setError('No se pudieron actualizar los avisos.');
    }
  }

  Future<void> _refreshContactsDirectory() async {
    final current = state.currentUser;
    if (current == null || _profilesRepository == null || _contactsRepository == null) return;
    try {
      final directory = await _profilesRepository.fetchDirectory();
      final contacts = await _contactsRepository.fetchContacts(current.id);
      final contactIds = contacts.map((user) => user.id).toList(growable: false);
      final updatedProfile = current.copyWith(contactIds: contactIds);
      final mergedDirectory = _mergeDirectory(
        updatedProfile,
        extra: <UserProfile>[...directory, ...contacts],
      );
      state = state.copyWith(currentUser: updatedProfile, directory: mergedDirectory);
    } catch (_) {
      _setError('No se pudo actualizar el directorio.');
    }
  }

  void _upsertMessage(Message message) {
    final updatedMessages = Map<String, List<Message>>.from(state.messages);
    final thread = List<Message>.from(updatedMessages[message.conversationId] ?? const <Message>[]);
    final existingIndex = thread.indexWhere((entry) => entry.id == message.id);
    if (existingIndex >= 0) {
      thread[existingIndex] = message;
    } else {
      thread.add(message);
    }
    thread.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    updatedMessages[message.conversationId] = thread;

    var found = false;
    final updatedConversations = state.conversations
        .map((conversation) {
          if (conversation.id == message.conversationId) {
            found = true;
            return conversation.copyWith(lastMessage: message);
          }
          return conversation;
        })
        .toList(growable: false);

    state = state.copyWith(
      messages: updatedMessages,
      conversations: found ? updatedConversations : state.conversations,
      errorMessage: null,
    );
  }

  Future<void> acknowledgeAnnouncement(String announcementId) async {
    final user = state.currentUser;
    if (user == null) return;
    if (_announcementsRepository != null) {
      try {
        await _announcementsRepository.acknowledgeAnnouncement(
          announcementId: announcementId,
          profileId: user.id,
        );
      } catch (_) {
        _setError('No se pudo confirmar la lectura del aviso.');
      }
    }
    final announcements = state.announcements
        .map((announcement) => announcement.id == announcementId
            ? announcement.copyWith(
                acknowledgedBy: <String>{...announcement.acknowledgedBy, user.id},
              )
            : announcement)
        .toList(growable: false);
    state = state.copyWith(announcements: announcements);
  }

  Future<void> publishAnnouncement({
    required String title,
    required String body,
    String category = 'General',
  }) async {
    final user = state.currentUser;
    if (user == null || !user.isProfessor) {
      _setError('Solo profesores publican boletines.');
      return;
    }
    Announcement announcement;
    if (_announcementsRepository == null) {
      announcement = Announcement(
        id: _uuid.v4(),
        title: title,
        body: body,
        category: category,
        authorId: user.id,
        createdAt: DateTime.now(),
        acknowledgedBy: <String>{user.id},
      );
    } else {
      try {
        announcement = await _announcementsRepository.publishAnnouncement(
          authorId: user.id,
          title: title,
          body: body,
          category: category,
        );
      } catch (_) {
        _setError('No se pudo publicar el aviso.');
        return;
      }
    }
    final announcements = List<Announcement>.from(state.announcements)..insert(0, announcement);
    state = state.copyWith(announcements: announcements, errorMessage: null);
  }

  Future<void> updateProfile({
    String? displayName,
    String? bio,
    String? specialty,
    String? avatarPath,
  }) async {
    final current = state.currentUser;
    if (current == null) return;

    // Si hay una nueva imagen de avatar, subirla a Supabase Storage
    String? uploadedAvatarUrl = avatarPath;
    if (avatarPath != null && 
        !avatarPath.startsWith('http://') && 
        !avatarPath.startsWith('https://') &&
        _supabaseClient != null) {
      try {
        if (kDebugMode) {
          debugPrint('📤 Subiendo avatar a Supabase Storage...');
        }
        
        final imageFile = File(avatarPath);
        final userId = current.id;
        final extension = avatarPath.split('.').last;
        final fileName = 'avatar.$extension';
        final filePath = 'users/$userId/$fileName';

        // Subir archivo
        await _supabaseClient!.storage
            .from('avatars')
            .upload(filePath, imageFile, fileOptions: supabase.FileOptions(upsert: true));

        // Obtener URL pública
        uploadedAvatarUrl = _supabaseClient!.storage
            .from('avatars')
            .getPublicUrl(filePath);

        if (kDebugMode) {
          debugPrint('✅ Avatar subido: $uploadedAvatarUrl');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ Error subiendo avatar: $e');
          debugPrint('Usando path local como fallback');
        }
        // Si falla la subida, usar el path local
        uploadedAvatarUrl = avatarPath;
      }
    }

    final next = current.copyWith(
      displayName: displayName ?? current.displayName,
      bio: bio ?? current.bio,
      specialty: specialty ?? current.specialty,
      avatarPath: uploadedAvatarUrl ?? current.avatarPath,
    );
    if (_profilesRepository != null) {
      try {
        await _profilesRepository.updateProfile(
          current.id,
          displayName: displayName,
          bio: bio,
          specialty: specialty,
          avatarPath: uploadedAvatarUrl,
        );
      } catch (_) {
        _setError('No se pudo actualizar el perfil en Supabase.');
      }
    }
    try {
      await _profileStore?.upsertProfile(next);
    } catch (_) {
      if (kDebugMode) {
        debugPrint('No se pudo guardar el perfil localmente.');
      }
    }
    final directory = _mergeDirectory(next);
    state = state.copyWith(currentUser: next, directory: directory, errorMessage: null);
  }

  void _setError(String message) {
    state = state.copyWith(errorMessage: message);
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  void _onAuthStateChanged(User? user) {
    if (user == null) {
      state = state.copyWith(
        step: AuthStep.phoneEntry,
        currentUser: null,
        pendingPhone: null,
        verificationId: null,
        resendToken: null,
        isLoading: false,
        errorMessage: null,
      );
      return;
    }
    unawaited(_handleAuthenticatedUser(user));
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    unawaited(_messagesChannel?.unsubscribe());
    unawaited(_conversationsChannel?.unsubscribe());
    unawaited(_participantsChannel?.unsubscribe());
    unawaited(_announcementsChannel?.unsubscribe());
    unawaited(_contactsChannel?.unsubscribe());
    super.dispose();
  }

  ({List<Conversation> conversations, Map<String, List<Message>> messages}) _withWelcomeConversations(
    UserProfile newUser,
    List<UserProfile> directory,
  ) {
    final mentor = directory.firstWhere((user) => user.id == 'prof-alvarez', orElse: () => directory.first);
    final tutoringConversationId = _uuid.v4();
    final welcomeMessage = Message(
      id: _uuid.v4(),
      conversationId: tutoringConversationId,
      senderId: mentor.id,
      body: 'Hola ${newUser.displayName}, soy ${mentor.displayName.split(' ').first} y te apoyaré en el TecNM Celaya.',
      timestamp: DateTime.now(),
      type: MessageContentType.text,
    );
    final tutoringConversation = Conversation(
      id: tutoringConversationId,
      title: 'Mentoría con ${mentor.displayName.split(' ').first}',
      participantIds: <String>[mentor.id, newUser.id],
      lastMessage: welcomeMessage,
    );

    final campusGroupId = _uuid.v4();
    final campusGroupMessage = Message(
      id: _uuid.v4(),
      conversationId: campusGroupId,
      senderId: mentor.id,
      body: 'Bienvenido al canal general del campus. Recuerda las normas de convivencia.',
      timestamp: DateTime.now(),
      type: MessageContentType.text,
    );
    final campusParticipants = <String>{
      mentor.id,
      ...directory.where((user) => user.role == UserRole.professor).map((user) => user.id),
      newUser.id,
    };
    final campusGroup = Conversation(
      id: campusGroupId,
      title: 'TecNM Celaya General',
      participantIds: campusParticipants.toList(),
      isGroup: true,
      hidePhoneNumbers: true,
      lastMessage: campusGroupMessage,
    );

    final updatedConversations = List<Conversation>.from(state.conversations)
      ..add(tutoringConversation)
      ..add(campusGroup);
    final updatedMessages = Map<String, List<Message>>.from(state.messages)
      ..[tutoringConversationId] = <Message>[welcomeMessage]
      ..[campusGroupId] = <Message>[campusGroupMessage];
    return (conversations: updatedConversations, messages: updatedMessages);
  }

  Future<void> _handleAuthenticatedUser(User user) async {
    if (kDebugMode) {
      debugPrint('🔐 Usuario autenticado: ${user.uid}');
      debugPrint('  - Email: ${user.email}');
      debugPrint('  - Phone: ${user.phoneNumber}');
    }
    
    // Nota: Firebase Auth y Supabase Auth son independientes.
    // Usamos políticas públicas en el bucket 'messages' para permitir subidas.
    
    final store = _profileStore;
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      pendingPhone: user.phoneNumber ?? state.pendingPhone,
      verificationId: null,
      resendToken: null,
    );

    // Buscar perfil en Supabase
    UserProfile? profile;
    if (store != null) {
      try {
        if (kDebugMode) {
          debugPrint('📥 Buscando perfil en Supabase para UID: ${user.uid}');
        }
        profile = await store.fetchProfile(user.uid);
        if (kDebugMode) {
          if (profile != null) {
            debugPrint('✅ Perfil encontrado en Supabase: ${profile.displayName}');
          } else {
            debugPrint('⚠️ Perfil no encontrado en Supabase - usuario nuevo');
          }
        }
      } catch (error, stackTrace) {
        if (kDebugMode) {
          debugPrint('❌ Error al buscar perfil en Supabase:');
          debugPrint('Error: $error');
          debugPrint('StackTrace: $stackTrace');
        }
      }
    }

    // Si el perfil existe en Supabase, cargar datos y continuar
    if (profile != null) {
      await _loadRemoteData(profile);
      return;
    }

    // Si no existe perfil, pedir al usuario que complete su información
    state = state.copyWith(
      step: AuthStep.profile,
      isLoading: false,
    );
  }

  List<UserProfile> _mergeDirectory(
    UserProfile profile, {
    List<UserProfile> extra = const <UserProfile>[],
  }) {
    final merged = <String, UserProfile>{
      for (final user in state.directory) user.id: user,
    };
    for (final user in extra) {
      merged[user.id] = user;
    }
    merged[profile.id] = profile;
    return merged.values.toList(growable: false);
  }
}
