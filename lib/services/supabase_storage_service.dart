import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class SupabaseStorageService {
  SupabaseStorageService(this._client);

  final SupabaseClient _client;
  final _uuid = const Uuid();
  static const String _messagesBucket = 'messages';

  /// Subir una imagen y retornar la URL pública
  Future<String> uploadMessageImage(String filePath, String senderId) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('El archivo no existe');
      }

      // Generar nombre único para el archivo
      final extension = filePath.substring(filePath.lastIndexOf('.'));
      final fileName = '${_uuid.v4()}$extension';
      final storagePath = 'users/$senderId/messages/$fileName';

      if (kDebugMode) {
        debugPrint('📤 Subiendo imagen a Storage: $storagePath');
      }

      // Subir archivo
      await _client.storage.from(_messagesBucket).upload(
            storagePath,
            file,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: false,
            ),
          );

      // Obtener URL pública
      final publicUrl = _client.storage.from(_messagesBucket).getPublicUrl(storagePath);

      if (kDebugMode) {
        debugPrint('✅ Imagen subida exitosamente: $publicUrl');
      }

      return publicUrl;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error subiendo imagen a Storage: $e');
      }
      rethrow;
    }
  }

  /// Eliminar una imagen del storage
  Future<void> deleteMessageImage(String imageUrl) async {
    try {
      // Extraer el path del storage de la URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      
      // Buscar el índice donde comienza el path del archivo
      final objectIndex = pathSegments.indexOf('object');
      if (objectIndex == -1 || objectIndex + 2 >= pathSegments.length) {
        throw Exception('URL inválida');
      }

      // Reconstruir el path: bucket + resto del path
      final storagePath = pathSegments.sublist(objectIndex + 2).join('/');

      if (kDebugMode) {
        debugPrint('🗑️ Eliminando imagen de Storage: $storagePath');
      }

      await _client.storage.from(_messagesBucket).remove([storagePath]);

      if (kDebugMode) {
        debugPrint('✅ Imagen eliminada exitosamente');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error eliminando imagen: $e');
      }
      rethrow;
    }
  }
}
