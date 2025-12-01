-- ============================================
-- FIX: Cambiar tipo de ID de UUID a TEXT
-- ============================================
-- Firebase Auth usa IDs string, no UUIDs

-- 1. Primero desactivar RLS en TODAS las tablas
DO $$ 
DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = 'public') 
    LOOP
        EXECUTE 'ALTER TABLE ' || quote_ident(r.tablename) || ' DISABLE ROW LEVEL SECURITY';
    END LOOP;
END $$;

-- 2. Eliminar TODAS las foreign key constraints que referencian profiles(id)
DO $$ 
DECLARE
    r RECORD;
BEGIN
    FOR r IN (
        SELECT 
            tc.table_name, 
            tc.constraint_name,
            kcu.column_name,
            ccu.table_name AS foreign_table_name,
            ccu.column_name AS foreign_column_name
        FROM information_schema.table_constraints AS tc 
        JOIN information_schema.key_column_usage AS kcu
          ON tc.constraint_name = kcu.constraint_name
          AND tc.table_schema = kcu.table_schema
        JOIN information_schema.constraint_column_usage AS ccu
          ON ccu.constraint_name = tc.constraint_name
          AND ccu.table_schema = tc.table_schema
        WHERE tc.constraint_type = 'FOREIGN KEY' 
          AND tc.table_schema = 'public'
          AND ccu.table_name = 'profiles'
          AND ccu.column_name = 'id'
    ) 
    LOOP
        EXECUTE format('ALTER TABLE %I DROP CONSTRAINT IF EXISTS %I', r.table_name, r.constraint_name);
    END LOOP;
END $$;

-- 3. Cambiar profiles.id a TEXT
ALTER TABLE profiles ALTER COLUMN id TYPE TEXT;

-- 4. Cambiar TODAS las columnas que son foreign keys a profiles(id)
DO $$ 
DECLARE
    r RECORD;
BEGIN
    FOR r IN (
        SELECT DISTINCT
            kcu.table_name,
            kcu.column_name
        FROM information_schema.key_column_usage AS kcu
        JOIN information_schema.constraint_column_usage AS ccu
          ON ccu.constraint_name = kcu.constraint_name
          AND ccu.table_schema = kcu.table_schema
        WHERE kcu.table_schema = 'public'
          AND ccu.table_name = 'profiles'
          AND ccu.column_name = 'id'
    ) 
    LOOP
        BEGIN
            EXECUTE format('ALTER TABLE %I ALTER COLUMN %I TYPE TEXT', r.table_name, r.column_name);
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'No se pudo cambiar %.% - puede que ya sea TEXT', r.table_name, r.column_name;
        END;
    END LOOP;
END $$;

-- 5. Recrear TODAS las foreign key constraints
DO $$ 
DECLARE
    r RECORD;
BEGIN
    FOR r IN (
        SELECT 
            tc.table_name, 
            tc.constraint_name,
            kcu.column_name,
            ccu.table_name AS foreign_table_name,
            ccu.column_name AS foreign_column_name
        FROM information_schema.table_constraints AS tc 
        JOIN information_schema.key_column_usage AS kcu
          ON tc.constraint_name = kcu.constraint_name
          AND tc.table_schema = kcu.table_schema
        JOIN information_schema.constraint_column_usage AS ccu
          ON ccu.constraint_name = tc.constraint_name
          AND ccu.table_schema = tc.table_schema
        WHERE tc.constraint_type = 'FOREIGN KEY' 
          AND tc.table_schema = 'public'
          AND ccu.table_name = 'profiles'
          AND ccu.column_name = 'id'
    ) 
    LOOP
        BEGIN
            EXECUTE format(
                'ALTER TABLE %I ADD CONSTRAINT %I FOREIGN KEY (%I) REFERENCES %I(%I) ON DELETE CASCADE',
                r.table_name,
                r.constraint_name,
                r.column_name,
                r.foreign_table_name,
                r.foreign_column_name
            );
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Constraint % ya existe o no se pudo recrear', r.constraint_name;
        END;
    END LOOP;
END $$;

-- 5. Recrear TODAS las foreign key constraints
DO $$ 
DECLARE
    r RECORD;
BEGIN
    FOR r IN (
        SELECT 
            tc.table_name, 
            tc.constraint_name,
            kcu.column_name,
            ccu.table_name AS foreign_table_name,
            ccu.column_name AS foreign_column_name
        FROM information_schema.table_constraints AS tc 
        JOIN information_schema.key_column_usage AS kcu
          ON tc.constraint_name = kcu.constraint_name
          AND tc.table_schema = kcu.table_schema
        JOIN information_schema.constraint_column_usage AS ccu
          ON ccu.constraint_name = tc.constraint_name
          AND ccu.table_schema = tc.table_schema
        WHERE tc.constraint_type = 'FOREIGN KEY' 
          AND tc.table_schema = 'public'
          AND ccu.table_name = 'profiles'
          AND ccu.column_name = 'id'
    ) 
    LOOP
        BEGIN
            EXECUTE format(
                'ALTER TABLE %I ADD CONSTRAINT %I FOREIGN KEY (%I) REFERENCES %I(%I) ON DELETE CASCADE',
                r.table_name,
                r.constraint_name,
                r.column_name,
                r.foreign_table_name,
                r.foreign_column_name
            );
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Constraint % ya existe o no se pudo recrear', r.constraint_name;
        END;
    END LOOP;
END $$;

-- 6. Reactivar RLS solo en profiles
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- 7. Verificar los tipos de columna
SELECT 
    table_name, 
    column_name, 
    data_type 
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND column_name LIKE '%id%'
  AND table_name IN (
    SELECT table_name 
    FROM information_schema.tables 
    WHERE table_schema = 'public' 
      AND table_type = 'BASE TABLE'
  )
ORDER BY table_name, column_name;
