-- ============================================
-- CAMBIAR TODOS LOS UUID A TEXT - VERSIÓN COMPLETA
-- ============================================

-- 1. Desactivar RLS en todas las tablas
DO $$ 
DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = 'public') 
    LOOP
        EXECUTE 'ALTER TABLE ' || quote_ident(r.tablename) || ' DISABLE ROW LEVEL SECURITY';
    END LOOP;
END $$;

-- 2. Eliminar TODAS las políticas RLS
DO $$ 
DECLARE
    r RECORD;
BEGIN
    FOR r IN (
        SELECT schemaname, tablename, policyname
        FROM pg_policies
        WHERE schemaname = 'public'
    ) 
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON %I.%I', r.policyname, r.schemaname, r.tablename);
    END LOOP;
END $$;

-- 3. Eliminar TODAS las foreign keys
DO $$ 
DECLARE
    r RECORD;
BEGIN
    FOR r IN (
        SELECT constraint_name, table_name
        FROM information_schema.table_constraints
        WHERE constraint_type = 'FOREIGN KEY'
          AND table_schema = 'public'
    ) 
    LOOP
        EXECUTE format('ALTER TABLE %I DROP CONSTRAINT %I', r.table_name, r.constraint_name);
    END LOOP;
END $$;

-- 4. VACIAR TODAS LAS TABLAS (para poder cambiar tipos sin conflictos)
-- Usar DELETE en lugar de TRUNCATE para evitar problemas con foreign keys
DELETE FROM announcement_receipts;
DELETE FROM announcements;
DELETE FROM messages;
DELETE FROM conversation_participants;
DELETE FROM conversations;
DELETE FROM contacts;
DELETE FROM profiles;

-- 5. Cambiar TODAS las columnas UUID a TEXT usando CAST explícito
ALTER TABLE profiles ALTER COLUMN id TYPE TEXT USING id::TEXT;
ALTER TABLE announcements ALTER COLUMN id TYPE TEXT USING id::TEXT;
ALTER TABLE announcements ALTER COLUMN author_id TYPE TEXT USING author_id::TEXT;
ALTER TABLE announcement_receipts ALTER COLUMN announcement_id TYPE TEXT USING announcement_id::TEXT;
ALTER TABLE announcement_receipts ALTER COLUMN profile_id TYPE TEXT USING profile_id::TEXT;
ALTER TABLE contacts ALTER COLUMN contact_id TYPE TEXT USING contact_id::TEXT;
ALTER TABLE contacts ALTER COLUMN owner_id TYPE TEXT USING owner_id::TEXT;
ALTER TABLE conversations ALTER COLUMN id TYPE TEXT USING id::TEXT;
ALTER TABLE conversation_participants ALTER COLUMN conversation_id TYPE TEXT USING conversation_id::TEXT;
ALTER TABLE conversation_participants ALTER COLUMN profile_id TYPE TEXT USING profile_id::TEXT;
ALTER TABLE messages ALTER COLUMN id TYPE TEXT USING id::TEXT;
ALTER TABLE messages ALTER COLUMN conversation_id TYPE TEXT USING conversation_id::TEXT;
ALTER TABLE messages ALTER COLUMN sender_id TYPE TEXT USING sender_id::TEXT;

-- 6. Recrear las foreign keys necesarias
ALTER TABLE announcements ADD CONSTRAINT announcements_author_id_fkey 
    FOREIGN KEY (author_id) REFERENCES profiles(id) ON DELETE CASCADE;

ALTER TABLE announcement_receipts ADD CONSTRAINT announcement_receipts_announcement_id_fkey 
    FOREIGN KEY (announcement_id) REFERENCES announcements(id) ON DELETE CASCADE;
ALTER TABLE announcement_receipts ADD CONSTRAINT announcement_receipts_profile_id_fkey 
    FOREIGN KEY (profile_id) REFERENCES profiles(id) ON DELETE CASCADE;

ALTER TABLE contacts ADD CONSTRAINT contacts_contact_id_fkey 
    FOREIGN KEY (contact_id) REFERENCES profiles(id) ON DELETE CASCADE;
ALTER TABLE contacts ADD CONSTRAINT contacts_owner_id_fkey 
    FOREIGN KEY (owner_id) REFERENCES profiles(id) ON DELETE CASCADE;

ALTER TABLE conversation_participants ADD CONSTRAINT conversation_participants_conversation_id_fkey 
    FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE;
ALTER TABLE conversation_participants ADD CONSTRAINT conversation_participants_profile_id_fkey 
    FOREIGN KEY (profile_id) REFERENCES profiles(id) ON DELETE CASCADE;

ALTER TABLE messages ADD CONSTRAINT messages_conversation_id_fkey 
    FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE;
ALTER TABLE messages ADD CONSTRAINT messages_sender_id_fkey 
    FOREIGN KEY (sender_id) REFERENCES profiles(id) ON DELETE CASCADE;

-- 7. Reactivar RLS solo en profiles y recrear políticas simples
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Recrear solo las 3 políticas simples en profiles
CREATE POLICY "Anyone authenticated can read profiles"
ON profiles FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Anyone authenticated can insert profiles"
ON profiles FOR INSERT
TO authenticated
WITH CHECK (true);

CREATE POLICY "Anyone authenticated can update profiles"
ON profiles FOR UPDATE
TO authenticated
USING (true);

-- 8. Verificar que todo es TEXT ahora
SELECT 
    table_name, 
    column_name, 
    data_type 
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND column_name LIKE '%id%'
  AND table_name IN ('profiles', 'announcements', 'announcement_receipts', 'contacts', 
                     'conversations', 'conversation_participants', 'messages')
ORDER BY table_name, column_name;
