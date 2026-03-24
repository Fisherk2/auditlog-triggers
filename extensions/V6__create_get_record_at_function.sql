-- 🮙🮘🮙🮘🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮙🮙🮙🮙🮙🮘🮙🮙🮙🮙🮙🮘🮙🮘🮙🮙🮘🮙🮙🮘🮙🮘🮙🮙🮙🮙🮘🮙🮙🮙🮙🮙🮘🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮘🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮘🮙🮙🮙🮙🮙🮙🮙🮘
-- EXTENSIÓN V6: CREAR FUNCIÓN GET_RECORD_AT (TIME-TRAVEL)
-- 🮙🮘🮙🮘🮙🮙🮘🮙🮙🮙🮙🮘🮙🮘🮙🮙🮙🮙🮙🮙🮘🮙🮙🮙🮙🮙🮘🮙🮙🮙🮙🮙🮙🮙🮘🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙
-- Propósito: Reconstruir estado histórico de registros en cualquier timestamp
-- Arquitectura: Clean Architecture - función como Interface Adapter
-- Patrón: Memento Pattern - restauración de estados históricos

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
    RAISE NOTICE '   Iniciando extensión V6...';
END $$;

-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- CONFIRMACIÓN MANUAL (requerido para continuar)
-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- DO $$ BEGIN RAISE EXCEPTION '🛑 VERIFICACIÓN MANUAL: Confirmar que la base de datos es correcta antes de continuar'; END $$;

BEGIN;

-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- LIMPIEZA PARA DESARROLLO (solo en entorno de desarrollo)
-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
DROP FUNCTION IF EXISTS get_record_at(VARCHAR, INTEGER, TIMESTAMP WITH TIME ZONE) CASCADE;

-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- FUNCIÓN GET_RECORD_AT (MEMENTO PATTERN)
-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- Implementa Memento Pattern: restaura estado histórico de un registro
CREATE OR REPLACE FUNCTION get_record_at(
    p_table_name VARCHAR(100),
    p_record_id INTEGER,
    p_as_of TIMESTAMP WITH TIME ZONE
)
RETURNS TABLE (
    record_data JSONB,
    found BOOLEAN,
    as_of_timestamp TIMESTAMP WITH TIME ZONE
)
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
DECLARE
    v_table_exists BOOLEAN;
    v_is_system_table BOOLEAN;
    v_last_state JSONB := NULL;
    v_record_found BOOLEAN := FALSE;
    v_effective_timestamp TIMESTAMP WITH TIME ZONE := p_as_of;
    change_record RECORD;
BEGIN
    -- Validación de seguridad: verificar que la tabla existe y no es del sistema
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_name = LOWER(p_table_name)
        AND table_schema = 'public'
    ) INTO v_table_exists;
    
    -- Validar que no sea tabla del sistema
    SELECT p_table_name IN ('pg_catalog', 'information_schema', 'audit_log', 'audit_history') 
    INTO v_is_system_table;
    
    IF NOT v_table_exists OR v_is_system_table THEN
        RAISE EXCEPTION 'Tabla inválida o no permitida: %', p_table_name;
    END IF;
    
    -- Obtener todos los cambios hasta el timestamp solicitado
    -- Usando índices: (table_name, record_id, changed_at)
    FOR change_record IN
        SELECT operation, old_data, new_data, changed_at
        FROM audit_log
        WHERE table_name = LOWER(p_table_name)
        AND record_id = p_record_id
        AND changed_at <= p_as_of
        ORDER BY changed_at ASC
    LOOP
        -- Procesar cada cambio secuencialmente
        IF change_record.operation = 'I' THEN
            -- INSERT: el registro comienza a existir
            v_last_state := change_record.new_data;
            v_record_found := TRUE;
            v_effective_timestamp := change_record.changed_at;
            
        ELSIF change_record.operation = 'U' THEN
            -- UPDATE: actualizar estado si el registro existe
            IF v_record_found THEN
                v_last_state := change_record.new_data;
                v_effective_timestamp := change_record.changed_at;
            END IF;
            
        ELSIF change_record.operation = 'D' THEN
            -- DELETE: el registro deja de existir
            IF v_record_found THEN
                v_last_state := NULL;
                v_record_found := FALSE;
                v_effective_timestamp := change_record.changed_at;
            END IF;
        END IF;
    END LOOP;
    
    -- Retornar el resultado
    RETURN QUERY SELECT 
        v_last_state AS record_data,
        v_record_found AS found,
        v_effective_timestamp AS as_of_timestamp;
    
END;
$$;

-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- COMENTARIOS DE DOCUMENTACIÓN
-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
COMMENT ON FUNCTION get_record_at(VARCHAR, INTEGER, TIMESTAMP WITH TIME ZONE) IS 'Función de time-travel: reconstruye estado histórico de un registro (Memento Pattern)';

-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- DOCUMENTACIÓN DE DECISIONES ARQUITECTÓNICAS
-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- JSONB en lugar de TABLE tipada: flexibilidad para cualquier estructura de tabla
-- Memento Pattern: restauración secuencial de estados históricos
-- Seguridad: validación de tabla y prevención de acceso a tablas del sistema

COMMIT;

-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- VERIFICACIÓN POST-EXTENSIÓN
-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
DO $$
BEGIN
    RAISE NOTICE '✅ Verificación de función get_record_at():';
    
    IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'get_record_at') THEN
        RAISE NOTICE '   ✓ Función get_record_at creada exitosamente';
        RAISE NOTICE '🎉 Función de time-travel lista para consultas históricas';
        RAISE NOTICE '💡 Ejemplo de uso:';
        RAISE NOTICE '   SELECT * FROM get_record_at(''customers'', 1, ''2024-01-15 10:30:00''::timestamp);';
        RAISE NOTICE '📋 Limitaciones conocidas:';
        RAISE NOTICE '   - No reconstruye relaciones entre tablas';
        RAISE NOTICE '   - Solo funciona para tablas con auditoría activada';
        RAISE NOTICE '   - Performance depende de volumen de datos históricos';
    ELSE
        RAISE EXCEPTION '❌ Error: La función get_record_at no fue creada';
    END IF;
END $$;