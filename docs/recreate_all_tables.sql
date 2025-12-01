-- ============================================
-- RECREAR TODAS LAS TABLAS DESDE CERO
-- ============================================
-- Esto eliminará TODAS las tablas y datos, y las recreará con tipos TEXT

-- 1. Desactivar RLS
DO $$ 
DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = 'public') 
    LOOP
        EXECUTE 'ALTER TABLE ' || quote_ident(r.tablename) || ' DISABLE ROW LEVEL SECURITY';
    END LOOP;
END $$;

-- 2. Eliminar TODAS las tablas existentes
DROP TABLE IF EXISTS announcement_receipts CASCADE;
DROP TABLE IF EXISTS announcements CASCADE;
DROP TABLE IF EXISTS messages CASCADE;
DROP TABLE IF EXISTS conversation_participants CASCADE;
DROP TABLE IF EXISTS conversations CASCADE;
DROP TABLE IF EXISTS contacts CASCADE;
DROP TABLE IF EXISTS profiles CASCADE;

-- 3. Crear tabla PROFILES con ID como TEXT
CREATE TABLE profiles (
    id TEXT PRIMARY KEY,
    display_name TEXT NOT NULL,
    phone_number TEXT NOT NULL UNIQUE,
    email TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('student', 'professor')),
    avatar_path TEXT,
    bio TEXT,
    specialty TEXT,
    contact_ids TEXT[] DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Crear tabla CONTACTS
CREATE TABLE contacts (
    id SERIAL PRIMARY KEY,
    owner_id TEXT NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    contact_id TEXT NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(owner_id, contact_id)
);

-- 5. Crear tabla CONVERSATIONS
CREATE TABLE conversations (
    id TEXT PRIMARY KEY,
    title TEXT,
    is_group BOOLEAN DEFAULT false,
    hide_phone_numbers BOOLEAN DEFAULT false,
    created_by TEXT REFERENCES profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. Crear tabla CONVERSATION_PARTICIPANTS
CREATE TABLE conversation_participants (
    id SERIAL PRIMARY KEY,
    conversation_id TEXT NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    profile_id TEXT NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(conversation_id, profile_id)
);

-- 7. Crear tabla MESSAGES
CREATE TABLE messages (
    id TEXT PRIMARY KEY,
    conversation_id TEXT NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    sender_id TEXT NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    body TEXT NOT NULL,
    message_type TEXT NOT NULL DEFAULT 'text',
    media_url TEXT,
    timestamp TIMESTAMPTZ DEFAULT NOW()
);

-- 8. Crear tabla ANNOUNCEMENTS
CREATE TABLE announcements (
    id TEXT PRIMARY KEY,
    author_id TEXT NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 9. Crear tabla ANNOUNCEMENT_RECEIPTS
CREATE TABLE announcement_receipts (
    id SERIAL PRIMARY KEY,
    announcement_id TEXT NOT NULL REFERENCES announcements(id) ON DELETE CASCADE,
    profile_id TEXT NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    read_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(announcement_id, profile_id)
);

-- 10. Crear índices para mejor rendimiento
CREATE INDEX idx_contacts_owner_id ON contacts(owner_id);
CREATE INDEX idx_contacts_contact_id ON contacts(contact_id);
CREATE INDEX idx_conversation_participants_conversation_id ON conversation_participants(conversation_id);
CREATE INDEX idx_conversation_participants_profile_id ON conversation_participants(profile_id);
CREATE INDEX idx_messages_conversation_id ON messages(conversation_id);
CREATE INDEX idx_messages_sender_id ON messages(sender_id);
CREATE INDEX idx_messages_timestamp ON messages(timestamp DESC);
CREATE INDEX idx_profiles_phone_number ON profiles(phone_number);
CREATE INDEX idx_announcements_author_id ON announcements(author_id);
CREATE INDEX idx_announcement_receipts_profile_id ON announcement_receipts(profile_id);

-- 11. Habilitar RLS solo en profiles
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- 12. Crear políticas RLS simples para profiles
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

-- 13. Verificar las tablas creadas
SELECT 
    table_name, 
    column_name, 
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name IN ('profiles', 'announcements', 'announcement_receipts', 'contacts', 
                     'conversations', 'conversation_participants', 'messages')
ORDER BY table_name, ordinal_position;

-- ============================================
-- LISTO! Todas las tablas recreadas con TEXT
-- ============================================
