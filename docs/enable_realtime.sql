-- Script para habilitar Realtime en todas las tablas de Supabase
-- Ejecuta este script en el SQL Editor de tu dashboard de Supabase

-- 1. Habilitar Realtime en la tabla messages
ALTER PUBLICATION supabase_realtime ADD TABLE messages;

-- 2. Habilitar Realtime en la tabla conversations
ALTER PUBLICATION supabase_realtime ADD TABLE conversations;

-- 3. Habilitar Realtime en la tabla conversation_participants
ALTER PUBLICATION supabase_realtime ADD TABLE conversation_participants;

-- 4. Habilitar Realtime en la tabla announcements
ALTER PUBLICATION supabase_realtime ADD TABLE announcements;

-- 5. Habilitar Realtime en la tabla contacts
ALTER PUBLICATION supabase_realtime ADD TABLE contacts;

-- 6. Habilitar Realtime en la tabla profiles (por si acaso)
ALTER PUBLICATION supabase_realtime ADD TABLE profiles;

-- 7. Verificar que las tablas estén en la publicación
SELECT schemaname, tablename 
FROM pg_publication_tables 
WHERE pubname = 'supabase_realtime';
