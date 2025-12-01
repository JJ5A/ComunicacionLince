-- ============================================
-- FIX: Políticas RLS más permisivas
-- ============================================
-- Cambiar las políticas para que no dependan de auth.uid()

-- Eliminar políticas actuales
DROP POLICY IF EXISTS "Anyone authenticated can read profiles" ON profiles;
DROP POLICY IF EXISTS "Anyone authenticated can insert profiles" ON profiles;
DROP POLICY IF EXISTS "Anyone authenticated can update profiles" ON profiles;

-- Crear políticas que permitan todo (temporalmente para desarrollo)
CREATE POLICY "Allow all reads on profiles"
ON profiles FOR SELECT
USING (true);

CREATE POLICY "Allow all inserts on profiles"
ON profiles FOR INSERT
WITH CHECK (true);

CREATE POLICY "Allow all updates on profiles"
ON profiles FOR UPDATE
USING (true);

-- Verificar políticas
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'profiles'
ORDER BY policyname;
