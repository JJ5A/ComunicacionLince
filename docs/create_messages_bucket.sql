-- Script para crear bucket de mensajes en Supabase Storage
-- Ejecuta este script en el SQL Editor de tu dashboard de Supabase

-- 1. Crear bucket público para mensajes
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'messages',
  'messages',
  true,
  52428800, -- 50MB
  ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'video/mp4', 'video/quicktime']
)
ON CONFLICT (id) DO NOTHING;

-- 2. Crear política para permitir INSERT (cualquier usuario autenticado puede subir)
CREATE POLICY "Usuarios pueden subir archivos a messages"
ON storage.objects FOR INSERT
TO public
WITH CHECK (bucket_id = 'messages');

-- 3. Crear política para permitir SELECT (cualquier usuario puede ver archivos públicos)
CREATE POLICY "Archivos de messages son públicos"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'messages');

-- 4. Crear política para permitir DELETE (solo el dueño puede eliminar)
CREATE POLICY "Usuarios pueden eliminar sus propios archivos de messages"
ON storage.objects FOR DELETE
TO public
USING (bucket_id = 'messages' AND (storage.foldername(name))[1] = 'users' AND (storage.foldername(name))[2] = auth.uid()::text);

-- 5. Verificar que el bucket fue creado
SELECT * FROM storage.buckets WHERE id = 'messages';
