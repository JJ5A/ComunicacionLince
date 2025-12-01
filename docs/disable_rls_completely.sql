-- ============================================
-- SOLUCIÓN URGENTE: DESACTIVAR RLS COMPLETAMENTE
-- ============================================
-- Este script desactiva RLS en las tablas problemáticas
-- Ejecuta esto en Supabase SQL Editor AHORA

-- 1. DESACTIVAR RLS EN TODAS LAS TABLAS PROBLEMÁTICAS
ALTER TABLE IF EXISTS conversation_participants DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS conversations DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS messages DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS contacts DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS announcements DISABLE ROW LEVEL SECURITY;

-- 2. ELIMINAR TODAS LAS POLÍTICAS
DO $$ 
DECLARE
    pol RECORD;
BEGIN
    -- Eliminar políticas de conversation_participants
    FOR pol IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE tablename = 'conversation_participants'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON conversation_participants', pol.policyname);
    END LOOP;
    
    -- Eliminar políticas de conversations
    FOR pol IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE tablename = 'conversations'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON conversations', pol.policyname);
    END LOOP;
    
    -- Eliminar políticas de messages
    FOR pol IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE tablename = 'messages'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON messages', pol.policyname);
    END LOOP;
    
    -- Eliminar políticas de contacts
    FOR pol IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE tablename = 'contacts'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON contacts', pol.policyname);
    END LOOP;
    
    -- Eliminar políticas de announcements
    FOR pol IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE tablename = 'announcements'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON announcements', pol.policyname);
    END LOOP;
END $$;

-- 3. MANTENER RLS SOLO EN PROFILES (la tabla crítica para registro)
ALTER TABLE IF EXISTS profiles ENABLE ROW LEVEL SECURITY;

-- Asegurar que las políticas de profiles sean simples
DROP POLICY IF EXISTS "Users can read all profiles" ON profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;

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

-- 4. VERIFICAR QUE NO QUEDEN POLÍTICAS RECURSIVAS
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

-- ============================================
-- LISTO! Ahora NO hay políticas recursivas
-- ============================================
-- Intenta registrar el usuario de nuevo
