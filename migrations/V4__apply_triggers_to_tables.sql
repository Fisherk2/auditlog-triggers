-- 🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮙🮙🮙🮙🮘🮙🮘🮙🮙🮙🮘🮙🮘🮙🮙🮘🮙🮙🮘🮙🮘🮙🮙🮙🮙🮘🮙🮙🮘🮙🮙🮘🮙🮙🮙🮙🮙🮘🮙🮙🮙🮙🮙🮙🮘🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮘🮙🮙🮙🮙🮙🮙🮙🮘
-- MIGRACIÓN V4: APLICAR TRIGGERS A TABLAS DE DOMINIO (INFRAESTRUCTURA)
-- 🮙🮘🮙🮘🮙🮙🮘🮙🮙🮙🮙🮘🮙🮘🮙🮙🮙🮙🮙🮙🮘🮙🮙🮙🮙🮙🮘🮙🮙🮙🮙🮙🮙🮙🮘🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮘🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙
-- Propósito: Conectar tablas de dominio con infraestructura de auditoría
-- Arquitectura: Clean Architecture - triggers como plugins de infraestructura
-- Principio: Open/Closed - extendemos comportamiento sin modificar código existente

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
    RAISE NOTICE '   Iniciando migración V4...';
END $$;

-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- CONFIRMACIÓN MANUAL (requerido para continuar)
-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- DO $$ BEGIN RAISE EXCEPTION '🛑 VERIFICACIÓN MANUAL: Confirmar que la base de datos es correcta antes de continuar'; END $$;

BEGIN;

-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- TRIGGER PARA TABLA CUSTOMERS (OPEN/CLOSED PRINCIPLE)
-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- Extiende comportamiento de customers sin modificar la tabla
DROP TRIGGER IF EXISTS customers_audit_trigger ON customers;

CREATE TRIGGER customers_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON customers
FOR EACH ROW
EXECUTE FUNCTION audit_trigger_func();

-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- TRIGGER PARA TABLA PRODUCTS (OPEN/CLOSED PRINCIPLE)
-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- Extiende comportamiento de products sin modificar la tabla
DROP TRIGGER IF EXISTS products_audit_trigger ON products;

CREATE TRIGGER products_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON products
FOR EACH ROW
EXECUTE FUNCTION audit_trigger_func();

-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- TRIGGER PARA TABLA ORDERS (OPEN/CLOSED PRINCIPLE)
-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- Extiende comportamiento de orders sin modificar la tabla
DROP TRIGGER IF EXISTS orders_audit_trigger ON orders;

CREATE TRIGGER orders_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON orders
FOR EACH ROW
EXECUTE FUNCTION audit_trigger_func();

-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- COMENTARIOS DE DOCUMENTACIÓN
-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
COMMENT ON TRIGGER customers_audit_trigger ON customers IS 'Trigger de auditoría: extiende customers sin modificar tabla (Open/Closed Principle)';
COMMENT ON TRIGGER products_audit_trigger ON products IS 'Trigger de auditoría: extiende products sin modificar tabla (Open/Closed Principle)';
COMMENT ON TRIGGER orders_audit_trigger ON orders IS 'Trigger de auditoría: extiende orders sin modificar tabla (Open/Closed Principle)';

-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- DOCUMENTACIÓN DE DECISIONES ARQUITECTÓNICAS
-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- AFTER en lugar de BEFORE: capturamos datos después de validación y persistencia
-- FOR EACH ROW en lugar de FOR EACH STATEMENT: auditoría granular por cada fila modificada
-- Open/Closed Principle: extendemos comportamiento sin modificar tablas de dominio

COMMIT;

-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- VERIFICACIÓN POST-MIGRACIÓN
-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
DO $$
DECLARE
    trigger_count INTEGER;
BEGIN
    RAISE NOTICE '✅ Verificación de triggers de auditoría:';
    
    -- Verificar trigger customers
    IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'customers_audit_trigger' AND tgrelid = 'customers'::regclass) THEN
        RAISE NOTICE '   ✓ Trigger customers_audit_trigger creado';
    ELSE
        RAISE EXCEPTION '❌ Error: Trigger customers_audit_trigger no fue creado';
    END IF;
    
    -- Verificar trigger products
    IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'products_audit_trigger' AND tgrelid = 'products'::regclass) THEN
        RAISE NOTICE '   ✓ Trigger products_audit_trigger creado';
    ELSE
        RAISE EXCEPTION '❌ Error: Trigger products_audit_trigger no fue creado';
    END IF;
    
    -- Verificar trigger orders
    IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'orders_audit_trigger' AND tgrelid = 'orders'::regclass) THEN
        RAISE NOTICE '   ✓ Trigger orders_audit_trigger creado';
    ELSE
        RAISE EXCEPTION '❌ Error: Trigger orders_audit_trigger no fue creado';
    END IF;
    
    -- Contar total de triggers de auditoría
    SELECT COUNT(*) INTO trigger_count 
    FROM pg_trigger 
    WHERE tgname IN ('customers_audit_trigger', 'products_audit_trigger', 'orders_audit_trigger')
    AND NOT tgisinternal;
    
    IF trigger_count = 3 THEN
        RAISE NOTICE '🎉 Todos los triggers de auditoría creados exitosamente (%/3)', trigger_count;
        RAISE NOTICE '🔥 Auditoría activa para todas las tablas de dominio';
    ELSE
        RAISE EXCEPTION '❌ Error: Se esperaban 3 triggers, se encontraron %', trigger_count;
    END IF;
END $$;