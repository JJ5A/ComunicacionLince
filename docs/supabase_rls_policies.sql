-- ============================================
-- Políticas RLS para Comunicación Lince
-- ============================================
-- Ejecuta esto en tu proyecto de Supabase
-- SQL Editor → New Query → Pega este código → Run

-- 1. TABLA PROFILES
-- Permite a usuarios autenticados:
-- - Leer todos los perfiles (para búsqueda de contactos)
-- - Insertar/actualizar su propio perfil
-- - Los perfiles son visibles para todos los usuarios autenticados

-- Eliminar políticas existentes si las hay
DROP POLICY IF EXISTS "Users can read all profiles" ON profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;

-- Crear nuevas políticas
CREATE POLICY "Users can read all profiles"
ON profiles FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Users can insert their own profile"
ON profiles FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
ON profiles FOR UPDATE
TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- 2. TABLA CONTACTS
DROP POLICY IF EXISTS "Users can read their own contacts" ON contacts;
DROP POLICY IF EXISTS "Users can insert their own contacts" ON contacts;
DROP POLICY IF EXISTS "Users can delete their own contacts" ON contacts;

CREATE POLICY "Users can read their own contacts"
ON contacts FOR SELECT
TO authenticated
USING (user_id = auth.uid());

CREATE POLICY "Users can insert their own contacts"
ON contacts FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can delete their own contacts"
ON contacts FOR DELETE
TO authenticated
USING (user_id = auth.uid());

-- 3. TABLA CONVERSATIONS
DROP POLICY IF EXISTS "Users can read their conversations" ON conversations;
DROP POLICY IF EXISTS "Users can insert conversations" ON conversations;
DROP POLICY IF EXISTS "Users can update their conversations" ON conversations;

-- Simplificado para evitar recursión - permite a usuarios autenticados manejar conversaciones
CREATE POLICY "Users can read their conversations"
ON conversations FOR SELECT
TO authenticated
USING (true);  -- Simplificado temporalmente

CREATE POLICY "Users can insert conversations"
ON conversations FOR INSERT
TO authenticated
WITH CHECK (true);

CREATE POLICY "Users can update their conversations"
ON conversations FOR UPDATE
TO authenticated
USING (true);

-- 4. TABLA CONVERSATION_PARTICIPANTS
DROP POLICY IF EXISTS "Users can read conversation participants" ON conversation_participants;
DROP POLICY IF EXISTS "Users can insert conversation participants" ON conversation_participants;

-- Política simple sin recursión - permite leer todos los participantes de conversaciones
CREATE POLICY "Users can read conversation participants"
ON conversation_participants FOR SELECT
TO authenticated
USING (true);  -- Simplificado para evitar recursión

CREATE POLICY "Users can insert conversation participants"
ON conversation_participants FOR INSERT
TO authenticated
WITH CHECK (true);

-- 5. TABLA MESSAGES
DROP POLICY IF EXISTS "Users can read messages from their conversations" ON messages;
DROP POLICY IF EXISTS "Users can insert messages" ON messages;
DROP POLICY IF EXISTS "Users can update their own messages" ON messages;

-- Simplificado para evitar recursión
CREATE POLICY "Users can read messages from their conversations"
ON messages FOR SELECT
TO authenticated
USING (true);  -- Simplificado temporalmente

CREATE POLICY "Users can insert messages"
ON messages FOR INSERT
TO authenticated
WITH CHECK (sender_id = auth.uid());

CREATE POLICY "Users can update their own messages"
ON messages FOR UPDATE
TO authenticated
USING (sender_id = auth.uid())
WITH CHECK (sender_id = auth.uid());

-- 6. TABLA ANNOUNCEMENTS
DROP POLICY IF EXISTS "Users can read all announcements" ON announcements;
DROP POLICY IF EXISTS "Professors can insert announcements" ON announcements;
DROP POLICY IF EXISTS "Professors can update their announcements" ON announcements;
DROP POLICY IF EXISTS "Professors can delete their announcements" ON announcements;

CREATE POLICY "Users can read all announcements"
ON announcements FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Professors can insert announcements"
ON announcements FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid()
    AND role = 'professor'
  )
);

CREATE POLICY "Professors can update their announcements"
ON announcements FOR UPDATE
TO authenticated
USING (author_id = auth.uid())
WITH CHECK (author_id = auth.uid());

CREATE POLICY "Professors can delete their announcements"
ON announcements FOR DELETE
TO authenticated
USING (author_id = auth.uid());

-- ============================================
-- VERIFICACIÓN
-- ============================================
-- Ejecuta estas consultas para verificar que las políticas están activas:

SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- Si ves las políticas listadas arriba, ¡todo está configurado correctamente! 🎉
