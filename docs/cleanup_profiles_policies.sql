-- ============================================
-- LIMPIAR POLÍTICAS DUPLICADAS EN PROFILES
-- ============================================

-- Eliminar todas las políticas antiguas/duplicadas
DROP POLICY IF EXISTS "Permitir actualizar propio perfil" ON profiles;
DROP POLICY IF EXISTS "Permitir crear propio perfil" ON profiles;
DROP POLICY IF EXISTS "Permitir lectura pública de perfiles" ON profiles;
DROP POLICY IF EXISTS "Profiles are readable by owner" ON profiles;
DROP POLICY IF EXISTS "Profiles are updatable by owner" ON profiles;
DROP POLICY IF EXISTS "Profiles are upsertable by owner" ON profiles;
DROP POLICY IF EXISTS "Profiles readable if related" ON profiles;

-- Las políticas que mantemos son:
-- "Anyone authenticated can read profiles"
-- "Anyone authenticated can insert profiles"  
-- "Anyone authenticated can update profiles"

-- Verificar que solo quedan 3 políticas en profiles
SELECT 
    tablename,
    policyname,
    cmd
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'profiles'
ORDER BY policyname;
