-- Script para agregar columna created_by a conversations si no existe

-- Verificar si la columna existe
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
          AND table_name = 'conversations' 
          AND column_name = 'created_by'
    ) THEN
        -- Agregar la columna created_by
        ALTER TABLE conversations 
        ADD COLUMN created_by TEXT REFERENCES profiles(id) ON DELETE SET NULL;
        
        RAISE NOTICE 'Columna created_by agregada exitosamente';
    ELSE
        RAISE NOTICE 'Columna created_by ya existe';
    END IF;
END $$;

-- Verificar la estructura de la tabla conversations
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'conversations'
ORDER BY ordinal_position;
