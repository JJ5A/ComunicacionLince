# Configuración de Videollamadas con Agora

## 1. Obtener Agora App ID

1. Ve a [Agora Console](https://console.agora.io/)
2. Regístrate o inicia sesión (es gratis)
3. Crea un nuevo proyecto:
   - Click en "Create Project"
   - Nombre: "Comunicación Lince" (o el que prefieras)
   - Authentication Mode: **Testing Mode** (para desarrollo)
   - Click "Submit"
4. En la lista de proyectos, verás tu nuevo proyecto
5. Click en el ícono de "ojo" 👁️ para ver el **App ID**
6. Copia el App ID

## 2. Configurar el App ID en la aplicación

1. Abre el archivo `.env` en la raíz del proyecto
2. Reemplaza `YOUR_AGORA_APP_ID_HERE` con tu App ID real:
   ```
   AGORA_APP_ID=tu_app_id_aquí
   ```
3. Guarda el archivo

## 3. Instalar dependencias

Ejecuta en la terminal:
```bash
flutter pub get
```

## 4. Ejecutar la aplicación

1. Reinicia la aplicación completamente
2. Abre un chat
3. Presiona el botón de videollamada 📹
4. ¡Listo! La videollamada debería iniciar

## Características implementadas

✅ Video bidireccional (local y remoto)
✅ Silenciar micrófono
✅ Activar/desactivar cámara
✅ Cambiar entre altavoz y auricular
✅ Cambiar cámara frontal/trasera
✅ Colgar llamada

## Notas importantes

- **Plan gratuito de Agora**: Incluye 10,000 minutos gratis al mes
- **Testing Mode**: Solo para desarrollo. Para producción, necesitarás implementar un servidor de tokens
- **Canal único**: Dos usuarios con el mismo `channelName` se conectarán entre sí
- **Permisos**: La app solicitará permisos de cámara y micrófono automáticamente

## Solución de problemas

### "Configura AGORA_APP_ID en el archivo .env"
- Verifica que reemplazaste `YOUR_AGORA_APP_ID_HERE` con tu App ID real
- Reinicia la aplicación después de cambiar el `.env`

### La cámara no se muestra
- Verifica que otorgaste permisos de cámara y micrófono
- En Android: Configuración → Apps → Comunicación Lince → Permisos
- En iOS: Configuración → Comunicación Lince → Permisos

### No veo al otro usuario
- Ambos usuarios deben estar en la misma conversación
- Verifica que ambos tienen conexión a internet
- Revisa que no hay errores en la consola

## Para producción

Cuando vayas a producción, necesitarás:
1. Cambiar a **Secured Mode** en Agora Console
2. Implementar un servidor de tokens (Node.js, Python, etc.)
3. Pasar el token al constructor `VideoCallPage`:
   ```dart
   VideoCallPage(
     conversationTitle: title,
     channelName: conversationId,
     agoraAppId: agoraAppId,
     token: 'token_from_server', // ← Agregar esto
   )
   ```

## Referencias

- [Agora Flutter SDK Documentation](https://docs.agora.io/en/video-calling/get-started/get-started-sdk?platform=flutter)
- [Agora Token Server](https://docs.agora.io/en/video-calling/develop/authentication-workflow)
