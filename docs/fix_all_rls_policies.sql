-- Script COMPLETO para arreglar RLS en TODAS las tablas
-- Cambia de "TO authenticated" a "TO public" con USING(true)
-- Esto es necesario porque usamos Firebase Auth, no Supabase Auth

-- ============================================
-- PASO 1: Eliminar políticas antiguas de profiles
-- ============================================

DROP POLICY IF EXISTS "Anyone authenticated can read profiles" ON profiles;
DROP POLICY IF EXISTS "Anyone authenticated can insert profiles" ON profiles;
DROP POLICY IF EXISTS "Anyone authenticated can update profiles" ON profiles;

-- ============================================
-- PASO 2: Crear políticas permisivas para profiles
-- ============================================

CREATE POLICY "Permitir lectura de perfiles"
ON profiles FOR SELECT
TO public
USING (true);

CREATE POLICY "Permitir creación de perfiles"
ON profiles FOR INSERT
TO public
WITH CHECK (true);

CREATE POLICY "Permitir actualización de perfiles"
ON profiles FOR UPDATE
TO public
USING (true)
WITH CHECK (true);

CREATE POLICY "Permitir eliminación de perfiles"
ON profiles FOR DELETE
TO public
USING (true);

-- ============================================
-- PASO 3: Habilitar RLS y crear políticas para conversations
-- ============================================

ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Permitir lectura de conversaciones" ON conversations;
DROP POLICY IF EXISTS "Permitir creación de conversaciones" ON conversations;
DROP POLICY IF EXISTS "Permitir actualización de conversaciones" ON conversations;
DROP POLICY IF EXISTS "Permitir eliminación de conversaciones" ON conversations;

CREATE POLICY "Permitir lectura de conversaciones"
ON conversations FOR SELECT TO public USING (true);

CREATE POLICY "Permitir creación de conversaciones"
ON conversations FOR INSERT TO public WITH CHECK (true);

CREATE POLICY "Permitir actualización de conversaciones"
ON conversations FOR UPDATE TO public USING (true) WITH CHECK (true);

CREATE POLICY "Permitir eliminación de conversaciones"
ON conversations FOR DELETE TO public USING (true);

-- ============================================
-- PASO 4: Habilitar RLS y crear políticas para conversation_participants
-- ============================================

ALTER TABLE conversation_participants ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Permitir lectura de participantes" ON conversation_participants;
DROP POLICY IF EXISTS "Permitir agregar participantes" ON conversation_participants;
DROP POLICY IF EXISTS "Permitir actualización de participantes" ON conversation_participants;
DROP POLICY IF EXISTS "Permitir eliminación de participantes" ON conversation_participants;

CREATE POLICY "Permitir lectura de participantes"
ON conversation_participants FOR SELECT TO public USING (true);

CREATE POLICY "Permitir agregar participantes"
ON conversation_participants FOR INSERT TO public WITH CHECK (true);

CREATE POLICY "Permitir actualización de participantes"
ON conversation_participants FOR UPDATE TO public USING (true) WITH CHECK (true);

CREATE POLICY "Permitir eliminación de participantes"
ON conversation_participants FOR DELETE TO public USING (true);

-- ============================================
-- PASO 5: Habilitar RLS y crear políticas para messages
-- ============================================

ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Permitir lectura de mensajes" ON messages;
DROP POLICY IF EXISTS "Permitir envío de mensajes" ON messages;
DROP POLICY IF EXISTS "Permitir actualización de mensajes" ON messages;
DROP POLICY IF EXISTS "Permitir eliminación de mensajes" ON messages;

CREATE POLICY "Permitir lectura de mensajes"
ON messages FOR SELECT TO public USING (true);

CREATE POLICY "Permitir envío de mensajes"
ON messages FOR INSERT TO public WITH CHECK (true);

CREATE POLICY "Permitir actualización de mensajes"
ON messages FOR UPDATE TO public USING (true) WITH CHECK (true);

CREATE POLICY "Permitir eliminación de mensajes"
ON messages FOR DELETE TO public USING (true);

-- ============================================
-- PASO 6: Habilitar RLS y crear políticas para contacts
-- ============================================

ALTER TABLE contacts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Permitir lectura de contactos" ON contacts;
DROP POLICY IF EXISTS "Permitir agregar contactos" ON contacts;
DROP POLICY IF EXISTS "Permitir actualización de contactos" ON contacts;
DROP POLICY IF EXISTS "Permitir eliminación de contactos" ON contacts;

CREATE POLICY "Permitir lectura de contactos"
ON contacts FOR SELECT TO public USING (true);

CREATE POLICY "Permitir agregar contactos"
ON contacts FOR INSERT TO public WITH CHECK (true);

CREATE POLICY "Permitir actualización de contactos"
ON contacts FOR UPDATE TO public USING (true) WITH CHECK (true);

CREATE POLICY "Permitir eliminación de contactos"
ON contacts FOR DELETE TO public USING (true);

-- ============================================
-- PASO 7: Habilitar RLS y crear políticas para announcements
-- ============================================

ALTER TABLE announcements ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Permitir lectura de anuncios" ON announcements;
DROP POLICY IF EXISTS "Permitir creación de anuncios" ON announcements;
DROP POLICY IF EXISTS "Permitir actualización de anuncios" ON announcements;
DROP POLICY IF EXISTS "Permitir eliminación de anuncios" ON announcements;

CREATE POLICY "Permitir lectura de anuncios"
ON announcements FOR SELECT TO public USING (true);

CREATE POLICY "Permitir creación de anuncios"
ON announcements FOR INSERT TO public WITH CHECK (true);

CREATE POLICY "Permitir actualización de anuncios"
ON announcements FOR UPDATE TO public USING (true) WITH CHECK (true);

CREATE POLICY "Permitir eliminación de anuncios"
ON announcements FOR DELETE TO public USING (true);

-- ============================================
-- PASO 8: Habilitar RLS y crear políticas para announcement_receipts
-- ============================================

ALTER TABLE announcement_receipts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Permitir lectura de recibos" ON announcement_receipts;
DROP POLICY IF EXISTS "Permitir creación de recibos" ON announcement_receipts;
DROP POLICY IF EXISTS "Permitir actualización de recibos" ON announcement_receipts;
DROP POLICY IF EXISTS "Permitir eliminación de recibos" ON announcement_receipts;

CREATE POLICY "Permitir lectura de recibos"
ON announcement_receipts FOR SELECT TO public USING (true);

CREATE POLICY "Permitir creación de recibos"
ON announcement_receipts FOR INSERT TO public WITH CHECK (true);

CREATE POLICY "Permitir actualización de recibos"
ON announcement_receipts FOR UPDATE TO public USING (true) WITH CHECK (true);

CREATE POLICY "Permitir eliminación de recibos"
ON announcement_receipts FOR DELETE TO public USING (true);

-- ============================================
-- VERIFICACIÓN FINAL
-- ============================================

-- Verificar que RLS está habilitado en todas las tablas
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY tablename;

-- Listar todas las políticas
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
WHERE schemaname = 'public'
ORDER BY tablename, policyname;
