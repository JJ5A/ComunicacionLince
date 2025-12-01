# Instrucciones para habilitar funcionalidad de imágenes

## Pasos a seguir:

### 1. Ejecutar en Supabase SQL Editor

Ejecuta estos dos scripts en el SQL Editor de tu dashboard de Supabase:

#### A. Habilitar Realtime (si aún no lo has hecho)
```sql
-- Archivo: docs/enable_realtime.sql
```

#### B. Crear bucket para mensajes
```sql
-- Archivo: docs/create_messages_bucket.sql
```

### 2. Reiniciar la aplicación Flutter

Después de ejecutar los scripts SQL, reinicia la aplicación para que tome los cambios.

## Funcionalidades implementadas:

✅ **Ver imágenes en pantalla completa**
   - Toca cualquier imagen en un mensaje para abrirla en el visor
   - Zoom con pellizco (pinch to zoom)
   - Soporte para imágenes locales y de red

✅ **Subir imágenes a Supabase Storage**
   - Las imágenes se suben automáticamente al bucket 'messages'
   - Se genera una URL pública para compartir
   - Las imágenes se organizan por usuario: `users/{userId}/messages/{imageId}.jpg`

✅ **Detección de cambios en tiempo real**
   - Nuevas conversaciones aparecen automáticamente
   - Nuevos grupos se actualizan en vivo
   - Mensajes nuevos se muestran instantáneamente
   - Cambios en contactos se reflejan automáticamente

## Cómo usar:

1. **Enviar imagen**: 
   - En el chat, toca el ícono de foto 📷
   - Selecciona una imagen de la galería
   - La imagen se sube automáticamente y se envía

2. **Ver imagen**:
   - Toca cualquier imagen en un mensaje
   - Se abrirá en pantalla completa
   - Usa pellizco para hacer zoom
   - Desliza para cerrar o usa el botón atrás

3. **Filtrar contactos**:
   - Usa la barra de búsqueda para filtrar por nombre, email o teléfono
   - Toca los chips "Todos", "Profesores" o "Estudiantes" para filtrar por rol
