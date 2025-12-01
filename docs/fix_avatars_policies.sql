-- Script para CORREGIR las políticas del bucket avatars
-- El error 403 ocurre porque las políticas actuales requieren auth.uid() de Supabase
-- pero estamos usando Firebase Auth, así que necesitamos políticas permisivas

-- PASO 1: Eliminar todas las políticas existentes
DROP POLICY IF EXISTS "Los usuarios pueden subir sus propios avatares" ON storage.objects;
DROP POLICY IF EXISTS "Avatares públicamente legibles" ON storage.objects;
DROP POLICY IF EXISTS "Los usuarios pueden actualizar sus propios avatares" ON storage.objects;
DROP POLICY IF EXISTS "Los usuarios pueden eliminar sus propios avatares" ON storage.objects;
DROP POLICY IF EXISTS "Permitir subida de avatares" ON storage.objects;
DROP POLICY IF EXISTS "Permitir lectura de avatares" ON storage.objects;
DROP POLICY IF EXISTS "Permitir actualización de avatares" ON storage.objects;
DROP POLICY IF EXISTS "Permitir eliminación de avatares" ON storage.objects;

-- PASO 2: Crear políticas permisivas (sin auth.uid())
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

-- VERIFICACIÓN: Listar todas las políticas del bucket avatars
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies 
WHERE tablename = 'objects' 
  AND (
    policyname LIKE '%avatar%' 
    OR policyname LIKE '%Permitir%'
  )
ORDER BY policyname;
