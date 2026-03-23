-- 🮙🮘🮙🮘🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮙🮙🮙🮙🮙🮘🮙🮙🮙🮙🮙🮘🮙🮘🮙🮙🮘🮙🮙🮘🮙🮘🮙🮙🮙🮙🮘🮙🮙🮙🮙🮙🮘🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮘🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮘🮙🮙🮙🮙🮙🮙🮙🮘
-- EXTENSIÓN V5: CREAR VISTA AUDIT_HISTORY (INTERFACE ADAPTER)
-- 🮙🮘🮙🮘🮙🮙🮘🮙🮙🮙🮙🮘🮙🮘🮙🮙🮙🮙🮙🮙🮘🮙🮙🮙🮙🮙🮘🮙🮙🮙🮙🮙🮙🮙🮘🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙
-- Propósito: Proporcionar interfaz simplificada para consultar historial de auditoría
-- Arquitectura: Clean Architecture - vista como Interface Adapter
-- Patrón: Facade Pattern - interfaz unificada para datos complejos

-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- VERIFICACIÓN DE SEGURIDAD - ESTABLECER CONTEXTO DE BASE DE DATOS
-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
DO $$
DECLARE
    current_db_name TEXT;
    expected_db_name TEXT := 'auditlog_db_example';
    current_user_name TEXT;
    expected_user_name TEXT := 'auditlog_admin';
BEGIN
    SELECT current_database() INTO current_db_name;
    SELECT current_user INTO current_user_name;
    
    IF current_db_name != expected_db_name THEN
        RAISE EXCEPTION '❌ SEGURIDAD: Base de datos incorrecta! Actual: % Esperado: % Ejecuta: \c %', 
            current_db_name, expected_db_name, expected_db_name;
    END IF;
    
    IF current_user_name != expected_user_name THEN
        RAISE NOTICE '⚠️  ADVERTENCIA: Usuario no es el esperado. Actual: % Esperado: %', 
            current_user_name, expected_user_name;
    END IF;
    
    RAISE NOTICE '✅ Verificación de seguridad exitosa:';
    RAISE NOTICE '   Base de datos: %', current_db_name;
    RAISE NOTICE '   Usuario actual: %', current_user_name;
    RAISE NOTICE '   Iniciando extensión V5...';
END $$;

-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- CONFIRMACIÓN MANUAL (requerido para continuar)
-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- DO $$ BEGIN RAISE EXCEPTION '🛑 VERIFICACIÓN MANUAL: Confirmar que la base de datos es correcta antes de continuar'; END $$;

BEGIN;

-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- LIMPIEZA PARA DESARROLLO (solo en entorno de desarrollo)
-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
DROP VIEW IF EXISTS audit_history CASCADE;

-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- VISTA AUDIT_HISTORY (FACADE PATTERN)
-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- Interfaz simplificada para consultar historial de auditoría cronológicamente
CREATE OR REPLACE VIEW audit_history AS
SELECT 
    -- Identificación del registro de auditoría
    al.id AS audit_id,
    
    -- Información del registro modificado
    al.table_name,
    al.record_id,
    
    -- Operación legible para humanos
    CASE al.operation
        WHEN 'I' THEN 'INSERT'
        WHEN 'U' THEN 'UPDATE'
        WHEN 'D' THEN 'DELETE'
        ELSE 'UNKNOWN'
    END AS operation,
    
    -- Estados del registro (JSONB para flexibilidad)
    al.old_data,
    al.new_data,
    
    -- Metadatos del cambio
    al.changed_by,
    al.changed_at,
    
    -- Secuencia por registro para identificar versión específica
    ROW_NUMBER() OVER (
        PARTITION BY al.table_name, al.record_id 
        ORDER BY al.changed_at DESC
    ) AS row_sequence
    
FROM audit_log al
ORDER BY al.changed_at DESC;

-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- COMENTARIOS DE DOCUMENTACIÓN
-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
COMMENT ON VIEW audit_history IS 'Vista de historial de auditoría: interfaz simplificada para consultas cronológicas (Facade Pattern)';
COMMENT ON COLUMN audit_history.audit_id IS 'Identificador único del registro de auditoría';
COMMENT ON COLUMN audit_history.table_name IS 'Nombre de la tabla del dominio que fue modificada';
COMMENT ON COLUMN audit_history.record_id IS 'ID del registro específico que sufrió el cambio';
COMMENT ON COLUMN audit_history.operation IS 'Tipo de operación legible: INSERT/UPDATE/DELETE';
COMMENT ON COLUMN audit_history.old_data IS 'Estado anterior del registro en formato JSONB';
COMMENT ON COLUMN audit_history.new_data IS 'Estado nuevo del registro en formato JSONB';
COMMENT ON COLUMN audit_history.changed_by IS 'Usuario de PostgreSQL que realizó el cambio';
COMMENT ON COLUMN audit_history.changed_at IS 'Fecha y hora exacta del cambio (orden cronológico)';
COMMENT ON COLUMN audit_history.row_sequence IS 'Número de secuencia por registro (1=más reciente, útil para time-travel)';

-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- DOCUMENTACIÓN DE DECISIONES ARQUITECTÓNICAS
-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- Vista en lugar de tabla materializada: siempre actualizada vs rendimiento
-- ROW_NUMBER() para identificar versión específica de cada registro
-- Facade Pattern: interfaz unificada que oculta complejidad de audit_log

COMMIT;

-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- VERIFICACIÓN POST-EXTENSIÓN
-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
DO $$
BEGIN
    RAISE NOTICE '✅ Verificación de vista audit_history:';
    
    IF EXISTS (SELECT 1 FROM information_schema.views WHERE table_name = 'audit_history') THEN
        RAISE NOTICE '   ✓ Vista audit_history creada exitosamente';
        
        -- Verificar columnas de la vista
        DECLARE
            column_count INTEGER;
        BEGIN
            SELECT COUNT(*) INTO column_count 
            FROM information_schema.columns 
            WHERE table_name = 'audit_history';
            
            IF column_count = 9 THEN
                RAISE NOTICE '   ✓ Vista tiene 9 columnas esperadas';
                RAISE NOTICE '🎉 Vista de historial lista para consultas de auditoría';
                RAISE NOTICE '💡 Ejemplo de uso: SELECT * FROM audit_history WHERE table_name = ''customers'' AND record_id = 1;';
            ELSE
                RAISE EXCEPTION '❌ Error: Se esperaban 9 columnas, se encontraron %', column_count;
            END IF;
        END;
        
    ELSE
        RAISE EXCEPTION '❌ Error: La vista audit_history no fue creada';
    END IF;
END $$;