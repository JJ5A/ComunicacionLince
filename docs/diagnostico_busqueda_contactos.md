# 🔍 Diagnóstico: Por qué no se encuentran algunos contactos

## Problema
Los números de teléfono registrados en Firebase Auth no aparecen en la búsqueda de contactos.

## Causa Raíz
Tu app utiliza **dos sistemas de almacenamiento**:
1. **Firebase Auth**: Guarda usuarios autenticados (UID + teléfono)
2. **Supabase**: Guarda perfiles completos (nombre, teléfono, rol, etc.)

Cuando buscas un contacto por teléfono, la app **solo busca en Supabase**. Si el usuario:
- ✅ Se registró con Firebase Auth (recibió SMS)
- ❌ NO completó su perfil (nombre, rol, etc.)
- ❌ Su perfil NO está en Supabase

→ **No podrá ser encontrado por búsqueda de teléfono** ❌

## Cómo Diagnosticar

### 1. Ver los logs de registro
Cuando un usuario completa su perfil, deberías ver:
```
🔄 Guardando perfil en Supabase - Teléfono: +52..., ID: abc123...
✅ Perfil guardado exitosamente en Supabase
```

Si ves esto en su lugar:
```
❌ Error guardando perfil en Supabase: ...
```
→ Hay un problema de permisos o conexión.

### 2. Verificar Supabase directamente
1. Ve a tu proyecto en [https://supabase.com](https://supabase.com)
2. Abre **Table Editor** → **profiles**
3. Busca el usuario por `phone_number` (ej. `+52 461 123 4567`)
4. Si NO aparece → El perfil nunca se guardó
5. Si SÍ aparece → El problema es otro (formato de número, etc.)

### 3. Ver logs de búsqueda
Cuando alguien busca un contacto, verás:
```
🔍 Buscando contacto con teléfono: +52...
✅ Usuario encontrado en Supabase: Juan Pérez
```

O si falla:
```
⚠️ No se encontró perfil completo en Supabase para ese número
```

## Soluciones

### Opción 1: Configurar Permisos de Supabase (RECOMENDADO) ✅

Ejecuta el script SQL en tu proyecto de Supabase:

1. Abre Supabase → **SQL Editor**
2. Carga el archivo `docs/supabase_rls_policies.sql`
3. Ejecuta el script completo
4. Verifica que las políticas se crearon correctamente

**Este script permite:**
- ✅ Usuarios autenticados pueden leer todos los perfiles (búsqueda)
- ✅ Cada usuario puede crear/actualizar su propio perfil
- ✅ Políticas seguras para contactos, mensajes, conversaciones

### Opción 2: Forzar Completar Perfil

Si quieres que TODOS los usuarios completen su perfil obligatoriamente:

**En el código ya está implementado**: cuando un usuario se autentica por primera vez, el sistema lo lleva automáticamente a la pantalla de perfil (`AuthStep.profile`).

El problema puede ser que el usuario:
1. Cierre la app antes de completar el perfil
2. El guardado falle por permisos de Supabase

**Solución**: Ejecuta el script SQL de la Opción 1.

### Opción 3: Depurar el .env

Si el problema es que Supabase no se está conectando:

1. Verifica que `.env` existe en la raíz del proyecto
2. Verifica que contenga:
   ```
   SUPABASE_URL=https://tu-proyecto.supabase.co
   SUPABASE_ANON_KEY=tu-clave-anonima-aqui
   ```
3. En `pubspec.yaml`, verifica que `.env` esté en assets:
   ```yaml
   assets:
     - .env
   ```
4. Ejecuta:
   ```
   flutter clean
   flutter pub get
   flutter run
   ```

## Flujo Correcto de Registro

```
1. Usuario ingresa teléfono → Firebase envía SMS
2. Usuario ingresa código → Firebase Auth crea cuenta
3. App detecta perfil faltante → Muestra pantalla de perfil
4. Usuario completa perfil (nombre, rol, etc.)
5. App guarda en Supabase ✅
6. Ahora el usuario PUEDE ser encontrado por búsqueda ✅
```

## Comandos para Depurar

### Ver logs en tiempo real
```bash
flutter run
```

### Limpiar y reiniciar
```bash
flutter clean
flutter pub get
flutter run
```

### Ver errores de Supabase
En los logs busca líneas que empiecen con:
- `❌ Error guardando perfil en Supabase:`
- `❌ Error al buscar en Supabase:`

## Casos Específicos

### Caso 1: Número de prueba funciona, números reales no
**Causa**: El número de prueba tiene un perfil completo en Supabase (creado manualmente o en pruebas anteriores). Los números reales solo están en Firebase Auth.

**Solución**: 
1. Ejecuta el script SQL (Opción 1)
2. Pide a los usuarios reales que completen su perfil
3. Verifica en Supabase Table Editor que sus perfiles se guardaron

### Caso 2: Usuario completó perfil pero no aparece
**Causa**: Error al guardar en Supabase (permisos RLS)

**Solución**:
1. Ejecuta el script SQL inmediatamente
2. Pide al usuario que cierre sesión y vuelva a completar su perfil
3. Verifica los logs para confirmar: `✅ Perfil guardado exitosamente en Supabase`

### Caso 3: "La sincronización con Supabase falló"
**Causa**: Problema de conexión o credenciales incorrectas en `.env`

**Solución**:
1. Verifica `.env` tiene las credenciales correctas
2. Verifica internet/firewall
3. Ejecuta el script SQL para permisos
4. Reinicia la app

## Checklist de Verificación

- [ ] Script SQL ejecutado en Supabase
- [ ] `.env` tiene credenciales correctas
- [ ] Usuario completó perfil (nombre, rol, etc.)
- [ ] Logs muestran "✅ Perfil guardado exitosamente en Supabase"
- [ ] Usuario aparece en Supabase Table Editor → profiles
- [ ] Búsqueda por teléfono encuentra al usuario

---

**Si después de seguir todos estos pasos el problema persiste**, comparte:
1. Los logs completos de registro
2. Los logs completos de búsqueda
3. Screenshot de Supabase Table Editor → profiles
