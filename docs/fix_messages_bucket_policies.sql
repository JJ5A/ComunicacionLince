-- Script para corregir políticas del bucket messages
-- Ejecuta esto en el SQL Editor de Supabase

-- 1. Eliminar políticas existentes
DROP POLICY IF EXISTS "Usuarios pueden subir archivos a messages" ON storage.objects;
DROP POLICY IF EXISTS "Archivos de messages son públicos" ON storage.objects;
DROP POLICY IF EXISTS "Usuarios pueden eliminar sus propios archivos de messages" ON storage.objects;

-- 2. Crear políticas más permisivas

-- Permitir a todos los usuarios autenticados subir archivos
CREATE POLICY "Cualquiera puede subir a messages"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'messages');

-- TAMBIÉN crear política pública para INSERT (por si Firebase Auth no se detecta como authenticated)
CREATE POLICY "Publico puede subir a messages"
ON storage.objects FOR INSERT
TO public
WITH CHECK (bucket_id = 'messages');

-- Permitir a TODOS (incluso anónimos) ver archivos del bucket messages
CREATE POLICY "Todos pueden ver archivos de messages"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'messages');

-- Permitir a todos los usuarios autenticados actualizar archivos
CREATE POLICY "Usuarios autenticados pueden actualizar messages"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'messages');

-- Permitir a todos los usuarios autenticados eliminar archivos
CREATE POLICY "Usuarios autenticados pueden eliminar de messages"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'messages');

-- 3. Verificar que el bucket es público
UPDATE storage.buckets 
SET public = true 
WHERE id = 'messages';

-- 4. Verificar políticas creadas
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies 
WHERE tablename = 'objects' AND policyname LIKE '%messages%';
