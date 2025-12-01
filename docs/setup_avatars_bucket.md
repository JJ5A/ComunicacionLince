# Configuración del Bucket de Avatares en Supabase Storage

## Pasos para crear el bucket desde la UI de Supabase:

1. **Ir a Storage** en el panel de Supabase
2. **Crear nuevo bucket** con el nombre: `avatars`
3. **Marcar como público** ✅ (Public bucket)
4. **Guardar**

## Políticas de Storage (RLS)

⚠️ **IMPORTANTE**: Como usamos Firebase Auth (no Supabase Auth), las políticas deben ser permisivas sin `auth.uid()`.

El bucket `avatars` debe tener las siguientes políticas configuradas:

### Política 1: Inserción (Upload)
- **Nombre**: "Permitir subida de avatares"
- **Operación**: INSERT
- **Target roles**: `public`
- **Policy command**: `WITH CHECK`
- **Policy definition**:
```sql
bucket_id = 'avatars'
```

### Política 2: Lectura (Download)
- **Nombre**: "Permitir lectura de avatares"
- **Operación**: SELECT
- **Target roles**: `public`
- **Policy command**: `USING`
- **Policy definition**:
```sql
bucket_id = 'avatars'
```

### Política 3: Actualización
- **Nombre**: "Permitir actualización de avatares"
- **Operación**: UPDATE
- **Target roles**: `public`
- **Policy command**: `USING` y `WITH CHECK`
- **Policy definition**:
```sql
bucket_id = 'avatars'
```

### Política 4: Eliminación
- **Nombre**: "Permitir eliminación de avatares"
- **Operación**: DELETE
- **Target roles**: `public`
- **Policy command**: `USING`
- **Policy definition**:
```sql
bucket_id = 'avatars'
```

## ⚠️ Solución rápida si ya creaste el bucket con políticas incorrectas

Si ya tienes el bucket creado y estás obteniendo error 403, ejecuta este SQL en Supabase SQL Editor:

```sql
-- Eliminar todas las políticas existentes del bucket avatars
DROP POLICY IF EXISTS "Los usuarios pueden subir sus propios avatares" ON storage.objects;
DROP POLICY IF EXISTS "Avatares públicamente legibles" ON storage.objects;
DROP POLICY IF EXISTS "Los usuarios pueden actualizar sus propios avatares" ON storage.objects;
DROP POLICY IF EXISTS "Los usuarios pueden eliminar sus propios avatares" ON storage.objects;

-- Crear políticas permisivas (sin auth.uid())
CREATE POLICY "Permitir subida de avatares"
ON storage.objects FOR INSERT
TO public
WITH CHECK (bucket_id = 'avatars');

CREATE POLICY "Permitir lectura de avatares"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'avatars');

CREATE POLICY "Permitir actualización de avatares"
ON storage.objects FOR UPDATE
TO public
USING (bucket_id = 'avatars')
WITH CHECK (bucket_id = 'avatars');

CREATE POLICY "Permitir eliminación de avatares"
ON storage.objects FOR DELETE
TO public
USING (bucket_id = 'avatars');
```

## Configuración de CORS (si es necesario)

Si vas a acceder desde web, asegúrate de que tu dominio esté en la lista de orígenes permitidos en Supabase.

## Estructura de archivos

Los avatares se guardarán con este patrón:
```
avatars/{firebase_uid}_{timestamp}.jpg
```

Ejemplo:
```
avatars/t8OPUfDc2GXD42jjcYDvQTO54dC3_1704567890123.jpg
```

## Notas importantes

- ✅ El bucket es **público** - las imágenes son accesibles mediante URL pública
- ✅ No requiere autenticación de Supabase para leer imágenes
- ✅ Las políticas son permisivas porque usamos Firebase Auth (no Supabase Auth)
- ⚠️ En producción, considera implementar validaciones del lado del servidor
- ⚠️ Considera agregar límites de tamaño de archivo en la configuración del bucket
