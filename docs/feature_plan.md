# Comunicacion Lince - Feature Plan

## Objetivo general
Construir una experiencia tipo WhatsApp enfocada en la comunidad TecNM Celaya que permita comunicación segura entre alumnos y profesores, protegiendo números telefónicos y agregando funciones académicas claves (video llamadas, multimedia, avisos oficiales y un plus propuesto por el alumno).

## Arquitectura propuesta
- **State management:** `StateNotifier` + `Riverpod` para exponer el estado global (`AppState`).
- **UI shell:** `MaterialApp` con un `AuthGate` que redirige al flujo correspondiente (registro → verificación → perfil → Home).
- **Navegación principal:** `HomeShell` con `NavigationBar` y 5 pestañas (Chats, Contactos, Grupos, Boletines, Perfil).
- **Repositorios simulados:** Datos en memoria para usuarios, conversaciones, grupos y anuncios que imitan respuestas remotas; fáciles de reemplazar por Firebase/Firestore.
- **Adjuntos:** Uso de `image_picker` y `file_picker` para seleccionar fotos, videos y animaciones; `emoji_picker_flutter` para emojis.
- **Video llamadas:** Pantalla dedicada que abre la cámara local (plugin `camera`) para simular la sesión y sentar la base para integrar WebRTC.
- **Función adicional:** "Boletín Académico" donde profesores publican avisos importantes y alumnos confirman lectura.

## Flujo de autenticación
1. **Registro de teléfono:** Captura del número y envío de un código OTP simulado (preparado para Firebase Auth con verificación en dos pasos).
2. **Verificación OTP:** Pantalla para ingresar el código de 6 dígitos.
3. **Perfil inicial:** Captura de avatar, correo institucional, rol (alumno/profesor) y datos adicionales.
4. **Acceso a Home:** Al completar el perfil se desbloquea la navegación principal. Se ofrece botón de cerrar sesión para re-probar el flujo.

## Pantallas principales
- **Chats:** Lista de conversaciones recientes; soporte de búsqueda y estado (grupos con teléfonos ocultos). Al tocar una conversación se abre el detalle con:
  - Envío de texto, emojis, fotos, videos, GIF/animaciones.
  - Acceso rápido a video llamada.
- **Contactos:** Buscador por teléfono o correo; sólo se agregan usuarios registrados.
- **Grupos:** Profesores crean grupos con la opción "Ocultar teléfonos". Los grupos muestran miembros y su visibilidad.
- **Perfil:** Muestra/edita avatar, correo, bio, especialidad y ofrece ajustes rápidos (silenciar notificaciones, tema).
- **Boletines (feature extra):** Profesores publican avisos; alumnos marcan *Recibido*. Historial filtrable por curso.

## Funcionalidades clave
- **Mensajería completa:** modelo `Conversation` + `Message`, almacenamiento en memoria, timestamps con `intl`.
- **Adjuntos multimedia:** Carpeta local, previsualizaciones, íconos por tipo de archivo.
- **Video llamada simulada:** Uso de la cámara local, mute, colgar, y estado de red.
- **Contactos restringidos:** Validaciones para teléfono/correo institucional.
- **Privacidad:** En grupos con teléfonos ocultos se muestra "Oculto por el profesor" salvo para el docente o para el dueño del número.
- **Extra (Boletín Académico):** Notificaciones internas para tareas, avisos, eventos con confirmación.

## Próximos pasos de implementación
1. Actualizar `pubspec.yaml` con dependencias (`flutter_riverpod`, `intl`, `uuid`, `image_picker`, `file_picker`, `emoji_picker_flutter`, `camera`).
2. Crear modelos base (`UserProfile`, `Conversation`, `Message`, `Announcement`).
3. Implementar `AppController` y estado global.
4. Construir flujo de autenticación (Phone → OTP → Perfil).
5. Añadir `HomeShell` con las cinco pestañas y sus páginas.
6. Implementar detalle de conversación con adjuntos y emoji picker.
7. Construir pantalla de video llamada y boletas académicas.
8. Actualizar README con instrucciones de uso y futuros reemplazos por Firebase.
