-- ============================================
-- FIX URGENTE: Eliminar Recursión Infinita
-- ============================================
-- Ejecuta esto AHORA en Supabase SQL Editor para arreglar el error

-- 1. DESACTIVAR RLS TEMPORALMENTE (para poder trabajar)
ALTER TABLE conversation_participants DISABLE ROW LEVEL SECURITY;
ALTER TABLE conversations DISABLE ROW LEVEL SECURITY;
ALTER TABLE messages DISABLE ROW LEVEL SECURITY;

-- 2. ELIMINAR TODAS LAS POLÍTICAS PROBLEMÁTICAS
DROP POLICY IF EXISTS "Users can read conversation participants" ON conversation_participants;
DROP POLICY IF EXISTS "Users can insert conversation participants" ON conversation_participants;
DROP POLICY IF EXISTS "Users can read their conversations" ON conversations;
DROP POLICY IF EXISTS "Users can insert conversations" ON conversations;
DROP POLICY IF EXISTS "Users can update their conversations" ON conversations;
DROP POLICY IF EXISTS "Users can read messages from their conversations" ON messages;
DROP POLICY IF EXISTS "Users can insert messages" ON messages;
DROP POLICY IF EXISTS "Users can update their own messages" ON messages;

-- 3. CREAR POLÍTICAS SIMPLES SIN RECURSIÓN
-- CONVERSATION_PARTICIPANTS - sin recursión
CREATE POLICY "Anyone authenticated can read participants"
ON conversation_participants FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Anyone authenticated can add participants"
ON conversation_participants FOR INSERT
TO authenticated
WITH CHECK (true);

-- CONVERSATIONS - sin recursión
CREATE POLICY "Anyone authenticated can read conversations"
ON conversations FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Anyone authenticated can create conversations"
ON conversations FOR INSERT
TO authenticated
WITH CHECK (true);

CREATE POLICY "Anyone authenticated can update conversations"
ON conversations FOR UPDATE
TO authenticated
USING (true);

-- MESSAGES - sin recursión
CREATE POLICY "Anyone authenticated can read messages"
ON messages FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Users can only send messages as themselves"
ON messages FOR INSERT
TO authenticated
WITH CHECK (sender_id = auth.uid());

CREATE POLICY "Users can update their own messages"
ON messages FOR UPDATE
TO authenticated
USING (sender_id = auth.uid());

-- 4. REACTIVAR RLS
ALTER TABLE conversation_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- ============================================
-- LISTO! Ahora intenta registrar un usuario de nuevo
-- ============================================
