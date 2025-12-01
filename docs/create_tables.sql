-- ============================================
-- Crear Tablas Básicas (si no existen)
-- ============================================
-- Solo ejecuta esto si el otro script dice que faltan tablas

-- PROFILES
CREATE TABLE IF NOT EXISTS profiles (
  id TEXT PRIMARY KEY,
  display_name TEXT NOT NULL,
  phone_number TEXT NOT NULL UNIQUE,
  email TEXT NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('student', 'professor')),
  avatar_path TEXT,
  bio TEXT,
  specialty TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- CONTACTS
CREATE TABLE IF NOT EXISTS contacts (
  id SERIAL PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  contact_id TEXT NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, contact_id)
);

-- CONVERSATIONS
CREATE TABLE IF NOT EXISTS conversations (
  id TEXT PRIMARY KEY,
  title TEXT,
  is_group BOOLEAN DEFAULT false,
  hide_phone_numbers BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- CONVERSATION_PARTICIPANTS
CREATE TABLE IF NOT EXISTS conversation_participants (
  id SERIAL PRIMARY KEY,
  conversation_id TEXT NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  user_id TEXT NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(conversation_id, user_id)
);

-- MESSAGES
CREATE TABLE IF NOT EXISTS messages (
  id TEXT PRIMARY KEY,
  conversation_id TEXT NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  sender_id TEXT NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  body TEXT NOT NULL,
  message_type TEXT NOT NULL DEFAULT 'text',
  media_url TEXT,
  timestamp TIMESTAMPTZ DEFAULT NOW()
);

-- ANNOUNCEMENTS
CREATE TABLE IF NOT EXISTS announcements (
  id TEXT PRIMARY KEY,
  author_id TEXT NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices para mejorar rendimiento
CREATE INDEX IF NOT EXISTS idx_contacts_user_id ON contacts(user_id);
CREATE INDEX IF NOT EXISTS idx_contacts_contact_id ON contacts(contact_id);
CREATE INDEX IF NOT EXISTS idx_conversation_participants_conversation_id ON conversation_participants(conversation_id);
CREATE INDEX IF NOT EXISTS idx_conversation_participants_user_id ON conversation_participants(user_id);
CREATE INDEX IF NOT EXISTS idx_messages_conversation_id ON messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_profiles_phone_number ON profiles(phone_number);

-- Habilitar RLS en todas las tablas
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversation_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE announcements ENABLE ROW LEVEL SECURITY;
