-- Script para habilitar RLS permisivo en tablas de conversaciones
-- Como usamos Firebase Auth (no Supabase Auth), las políticas deben ser permisivas

-- ============================================
-- CONVERSATIONS
-- ============================================

-- Habilitar RLS en conversations
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;

-- Políticas permisivas para conversations
CREATE POLICY "Permitir lectura de conversaciones"
ON conversations FOR SELECT
TO public
USING (true);

CREATE POLICY "Permitir creación de conversaciones"
ON conversations FOR INSERT
TO public
WITH CHECK (true);

CREATE POLICY "Permitir actualización de conversaciones"
ON conversations FOR UPDATE
TO public
USING (true)
WITH CHECK (true);

CREATE POLICY "Permitir eliminación de conversaciones"
ON conversations FOR DELETE
TO public
USING (true);

-- ============================================
-- CONVERSATION_PARTICIPANTS
-- ============================================

-- Habilitar RLS en conversation_participants
ALTER TABLE conversation_participants ENABLE ROW LEVEL SECURITY;

-- Políticas permisivas para conversation_participants
CREATE POLICY "Permitir lectura de participantes"
ON conversation_participants FOR SELECT
TO public
USING (true);

CREATE POLICY "Permitir agregar participantes"
ON conversation_participants FOR INSERT
TO public
WITH CHECK (true);

CREATE POLICY "Permitir actualización de participantes"
ON conversation_participants FOR UPDATE
TO public
USING (true)
WITH CHECK (true);

CREATE POLICY "Permitir eliminación de participantes"
ON conversation_participants FOR DELETE
TO public
USING (true);

-- ============================================
-- MESSAGES
-- ============================================

-- Habilitar RLS en messages
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- Políticas permisivas para messages
CREATE POLICY "Permitir lectura de mensajes"
ON messages FOR SELECT
TO public
USING (true);

CREATE POLICY "Permitir envío de mensajes"
ON messages FOR INSERT
TO public
WITH CHECK (true);

CREATE POLICY "Permitir actualización de mensajes"
ON messages FOR UPDATE
TO public
USING (true)
WITH CHECK (true);

CREATE POLICY "Permitir eliminación de mensajes"
ON messages FOR DELETE
TO public
USING (true);

-- ============================================
-- CONTACTS
-- ============================================

-- Habilitar RLS en contacts
ALTER TABLE contacts ENABLE ROW LEVEL SECURITY;

-- Políticas permisivas para contacts
CREATE POLICY "Permitir lectura de contactos"
ON contacts FOR SELECT
TO public
USING (true);

CREATE POLICY "Permitir agregar contactos"
ON contacts FOR INSERT
TO public
WITH CHECK (true);

CREATE POLICY "Permitir actualización de contactos"
ON contacts FOR UPDATE
TO public
USING (true)
WITH CHECK (true);

CREATE POLICY "Permitir eliminación de contactos"
ON contacts FOR DELETE
TO public
USING (true);

-- ============================================
-- ANNOUNCEMENTS
-- ============================================

-- Habilitar RLS en announcements
ALTER TABLE announcements ENABLE ROW LEVEL SECURITY;

-- Políticas permisivas para announcements
CREATE POLICY "Permitir lectura de anuncios"
ON announcements FOR SELECT
TO public
USING (true);

CREATE POLICY "Permitir creación de anuncios"
ON announcements FOR INSERT
TO public
WITH CHECK (true);

CREATE POLICY "Permitir actualización de anuncios"
ON announcements FOR UPDATE
TO public
USING (true)
WITH CHECK (true);

CREATE POLICY "Permitir eliminación de anuncios"
ON announcements FOR DELETE
TO public
USING (true);

-- ============================================
-- ANNOUNCEMENT_RECEIPTS
-- ============================================

-- Habilitar RLS en announcement_receipts
ALTER TABLE announcement_receipts ENABLE ROW LEVEL SECURITY;

-- Políticas permisivas para announcement_receipts
CREATE POLICY "Permitir lectura de recibos"
ON announcement_receipts FOR SELECT
TO public
USING (true);

CREATE POLICY "Permitir creación de recibos"
ON announcement_receipts FOR INSERT
TO public
WITH CHECK (true);

CREATE POLICY "Permitir actualización de recibos"
ON announcement_receipts FOR UPDATE
TO public
USING (true)
WITH CHECK (true);

CREATE POLICY "Permitir eliminación de recibos"
ON announcement_receipts FOR DELETE
TO public
USING (true);

-- ============================================
-- VERIFICACIÓN
-- ============================================

-- Listar todas las políticas creadas
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;
