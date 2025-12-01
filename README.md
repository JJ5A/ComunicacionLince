# Comunicación Lince

Aplicación tipo chat para la comunidad del TecNM en Celaya. Permite mensajería segura entre alumnos y profesores, protege números telefónicos en grupos, habilita video llamadas simuladas y agrega un boletín académico interno.

## Características principales
- **Autenticación en dos pasos** respaldada por Firebase Auth (OTP por SMS) con App Check habilitado.
- **Perfil institucional** con avatar, correo, bio, rol (alumno/profesor) y especialidad.
- **Chats individuales y grupales** con envío de texto, emojis, fotos, videos y animaciones.
- **Contactos restringidos**: solo se agregan usuarios existentes mediante teléfono o correo institucional.
- **Grupos docentes** que pueden ocultar los teléfonos de los integrantes. Incluye creación y controles de privacidad.
- **Video llamadas** basadas en la cámara local para sentar la base de integraciones WebRTC.
- **Boletín académico (feature extra)** para publicar avisos y confirmar lectura.

- `StateNotifier` + `Riverpod` mantienen el estado global (`AppState`).
- Directorio y conversaciones se siembran localmente y ahora se sincronizan con Supabase cuando existe conexión.
- Vistas separadas por módulo (`features/auth`, `features/chats`, etc.) y componentes reutilizables (`widgets`).
- Controlador central (`AppController`) con métodos para OTP, contactos, mensajes, grupos, anuncios y perfil.

## Requisitos previos
- Flutter 3.24+ (Dart 3.9+).
- Dispositivo/emulador con cámara si se desea probar la videollamada simulada.

## Ejecución rápida
```powershell
cd "c:\flutter projects\watsap_clon\comunicacion_lince"
flutter pub get
flutter run
```

## Pruebas
```powershell
flutter test
```

## Integración con Firebase
1. Crea el proyecto en [Firebase Console](https://console.firebase.google.com/) y habilita autenticación por teléfono.
2. Descarga los archivos de configuración (`google-services.json`, `GoogleService-Info.plist`) y colócalos en sus plataformas.
3. Ejecuta `flutterfire configure` para regenerar `lib/firebase_options.dart` cuando cambie algún identificador.
4. Para App Check, registra los dispositivos de depuración o usa proveedores como Play Integrity / App Attest.

## Integración con Supabase
1. Crea un proyecto en [Supabase](https://supabase.com/) y copia el `API URL` y `anon public key`.
2. En la tabla `profiles` (crearla si no existe) define al menos estas columnas: `id uuid primary key`, `display_name text`, `phone_number text`, `email text`, `role text`, `avatar_path text`, `bio text`, `specialty text`, `contact_ids text[]`.
3. Expón las credenciales al build de Flutter usando variables de compilación: 
	```powershell
	flutter run --dart-define=SUPABASE_URL=https://tu-proyecto.supabase.co --dart-define=SUPABASE_ANON_KEY=pk_xxx
	```
4. El controlador intentará sincronizar el perfil al completar el registro y al reingresar; si las claves no están presentes, la app sigue funcionando solo con datos locales.

## Próximos pasos sugeridos
- Persistir estados en Firestore/Realtime DB.
- Integrar almacenamiento en la nube para adjuntos (Firebase Storage).
- Sustituir la video llamada simulada por WebRTC (por ejemplo, `flutter_webrtc`).
- Añadir notificaciones push con Firebase Cloud Messaging.
