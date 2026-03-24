-- 🮙🮘🮙🮘🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮙🮙🮙🮘🮙🮘🮙🮙🮙🮘🮙🮘🮙🮙🮘🮙🮙🮘🮙🮘🮙🮙🮙🮙🮘🮙🮙🮘🮙🮙🮘🮙🮙🮙🮙🮙🮘🮙🮙🮙🮙🮙🮙🮘🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮘🮙🮙🮙🮙🮙🮙🮙🮘
-- MIGRACIÓN V3: CREAR FUNCIÓN AUDIT_TRIGGER_FUNC (INFRAESTRUCTURA)
-- 🮙🮘🮙🮘🮙🮙🮘🮙🮙🮙🮙🮘🮙🮙🮙🮙🮙🮙🮙🮙🮘🮙🮙🮙🮙🮙🮘🮙🮙🮙🮙🮙🮙🮙🮘🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮘🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙
-- Propósito: Crear función genérica de auditoría para todas las tablas
-- Arquitectura: Clean Architecture - esta función es INFRAESTRUCTURA pura
-- Patrón: Strategy Pattern - TG_OP determina comportamiento específico

-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
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
    RAISE NOTICE '   Iniciando migración V3...';
END $$;

-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- CONFIRMACIÓN MANUAL (requerido para continuar)
-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- DO $$ BEGIN RAISE EXCEPTION '🛑 VERIFICACIÓN MANUAL: Confirmar que la base de datos es correcta antes de continuar'; END $$;

BEGIN;

-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- LIMPIEZA PARA DESARROLLO (solo en entorno de desarrollo)
-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
DROP FUNCTION IF EXISTS audit_trigger_func() CASCADE;

-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- FUNCIÓN AUDIT_TRIGGER_FUNC (STRATEGY PATTERN)
-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- Implementa Strategy Pattern: TG_OP determina la estrategia de auditoría
CREATE OR REPLACE FUNCTION audit_trigger_func()
RETURNS TRIGGER
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
DECLARE
    v_operation CHAR(1);
    v_old_data JSONB;
    v_new_data JSONB;
    v_record_id INTEGER;
    v_table_name TEXT;
BEGIN
    -- Extraer nombre de tabla automáticamente
    v_table_name := TG_TABLE_NAME;
    
    -- Strategy Pattern: comportamiento según operación
    IF TG_OP = 'INSERT' THEN
        -- Estrategia INSERT: solo hay estado nuevo
        v_operation := 'I';
        v_old_data := NULL;
        v_new_data := to_jsonb(NEW);
        v_record_id := NEW.id;
        
    ELSIF TG_OP = 'UPDATE' THEN
        -- Estrategia UPDATE: registrar solo si hay cambios reales
        IF OLD IS DISTINCT FROM NEW THEN
            v_operation := 'U';
            v_old_data := to_jsonb(OLD);
            v_new_data := to_jsonb(NEW);
            v_record_id := NEW.id;
        ELSE
            -- Sin cambios, no registrar en auditoría
            RETURN NEW;
        END IF;
        
    ELSIF TG_OP = 'DELETE' THEN
        -- Estrategia DELETE: solo hay estado anterior
        v_operation := 'D';
        v_old_data := to_jsonb(OLD);
        v_new_data := NULL;
        v_record_id := OLD.id;
        
    ELSE
        -- Operación no soportada, no hacer nada
        RETURN COALESCE(NEW, OLD);
    END IF;
    
    -- Insertar registro de auditoría con manejo de errores
    BEGIN
        INSERT INTO audit_log (
            table_name,
            record_id,
            operation,
            old_data,
            new_data,
            changed_by,
            changed_at
        ) VALUES (
            v_table_name,
            v_record_id,
            v_operation,
            v_old_data,
            v_new_data,
            current_user,
            CURRENT_TIMESTAMP
        );
        
    EXCEPTION
        WHEN OTHERS THEN
            -- Log del error sin romper la transacción original
            RAISE NOTICE '⚠️  Error en auditoría: %', SQLERRM;
            -- Continuar con la operación original
    END;
    
    -- Return según operación para no interferir con CRUD
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
    
END;
$$;

-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- COMENTARIOS DE DOCUMENTACIÓN
-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
COMMENT ON FUNCTION audit_trigger_func() IS 'Función genérica de auditoría: implementa Strategy Pattern para INSERT/UPDATE/DELETE (Clean Architecture - Infraestructura)';

-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- DOCUMENTACIÓN DE DECISIONES ARQUITECTÓNICAS
-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- SECURITY DEFINER: necesario para escribir en audit_log incluso si el usuario no tiene permisos directos
-- Strategy Pattern: TG_OP determina comportamiento específico sin múltiples funciones
-- Manejo de errores: excepciones en auditoría no rompen transacciones de negocio

COMMIT;

-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- VERIFICACIÓN POST-MIGRACIÓN
-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
DO $$
BEGIN
    RAISE NOTICE '✅ Verificación de función audit_trigger_func():';
    
    IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'audit_trigger_func') THEN
        RAISE NOTICE '   ✓ Función audit_trigger_func creada exitosamente';
        RAISE NOTICE '🎉 Función de auditoría lista para triggers (migración V4)';
    ELSE
        RAISE EXCEPTION '❌ Error: La función audit_trigger_func no fue creada';
    END IF;
END $$;