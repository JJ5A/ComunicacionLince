-- Script para crear el bucket de avatares en Supabase Storage
-- Ejecutar en Supabase SQL Editor

-- Insertar el bucket si no existe
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

-- POLÍTICAS PERMISIVAS (sin auth.uid() porque usamos Firebase Auth, no Supabase Auth)

-- Política para permitir que cualquiera suba avatares
CREATE POLICY "Permitir subida de avatares"
ON storage.objects FOR INSERT
TO public
WITH CHECK (bucket_id = 'avatars');

-- Política para permitir que cualquiera lea avatares (bucket público)
CREATE POLICY "Permitir lectura de avatares"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'avatars');

-- Política para permitir que cualquiera actualice avatares
CREATE POLICY "Permitir actualización de avatares"
ON storage.objects FOR UPDATE
TO public
USING (bucket_id = 'avatars')
WITH CHECK (bucket_id = 'avatars');

-- Política para permitir que cualquiera elimine avatares
CREATE POLICY "Permitir eliminación de avatares"
ON storage.objects FOR DELETE
TO public
USING (bucket_id = 'avatars');
