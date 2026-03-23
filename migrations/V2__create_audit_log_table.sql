-- 🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮘🮙🮘🮙🮘🮙🮙🮘
-- MIGRACIÓN V2: CREAR TABLA AUDIT_LOG (INFRAESTRUCTURA)
-- 🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮘🮙🮘🮙🮘🮙🮙🮘
-- Propósito: Crear tabla de auditoría para registrar cambios del dominio
-- Arquitectura: Clean Architecture - esta tabla es INFRAESTRUCTURA, no dominio
-- Patrón: Audit Log Pattern con JSONB para flexibilidad máxima

-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- VERIFICACIÓN DE SEGURIDAD - ESTABLECER CONTEXTO DE BASE DE DATOS
-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- Previene ejecutar migraciones en la base de datos incorrecta
DO $$
DECLARE
    current_db_name TEXT;
    expected_db_name TEXT := 'auditlog_db_example';
    current_user_name TEXT;
    expected_user_name TEXT := 'auditlog_admin';
BEGIN
    -- Obtener nombre actual de la base de datos
    SELECT current_database() INTO current_db_name;
    
    -- Obtener nombre actual del usuario
    SELECT current_user INTO current_user_name;
    
    -- Verificar base de datos
    IF current_db_name != expected_db_name THEN
        RAISE EXCEPTION '❌ SEGURIDAD: Base de datos incorrecta! 
Actual: % 
Esperado: % 
Ejecuta: \c %', 
        current_db_name, expected_db_name, expected_db_name;
    END IF;
    
    -- Verificar usuario (advertencia, no error fatal)
    IF current_user_name != expected_user_name THEN
        RAISE NOTICE '⚠️  ADVERTENCIA: Usuario no es el esperado. 
Actual: % 
Esperado: %', 
        current_user_name, expected_user_name;
    END IF;
    
    RAISE NOTICE '✅ Verificación de seguridad exitosa:';
    RAISE NOTICE '   Base de datos: %', current_db_name;
    RAISE NOTICE '   Usuario actual: %', current_user_name;
    RAISE NOTICE '   Iniciando migración V2...';
END $$;

-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- CONFIRMACIÓN MANUAL (requerido para continuar)
-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- Comentar la siguiente línea para ejecución automática en CI/CD
-- DO $$ BEGIN RAISE EXCEPTION '🛑 VERIFICACIÓN MANUAL: Confirmar que la base de datos es correcta antes de continuar'; END $$;

BEGIN;

-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- LIMPIEZA PARA DESARROLLO (solo en entorno de desarrollo)
-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- En producción, comentar estas líneas para evitar pérdida de datos
DROP TABLE IF EXISTS audit_log CASCADE;

-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- TABLA AUDIT_LOG (INFRAESTRUCTURA DE AUDITORÍA)
-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- Almacena el historial completo de cambios en tablas de dominio
-- NOTA: No hay foreign keys a tablas de dominio (decisión arquitectónica intencional)
CREATE TABLE IF NOT EXISTS audit_log (
    id SERIAL PRIMARY KEY,
    table_name VARCHAR(100) NOT NULL,
    record_id INTEGER NOT NULL,
    operation CHAR(1) NOT NULL CHECK (operation IN ('I', 'U', 'D')),
    old_data JSONB NULL,
    new_data JSONB NULL,
    changed_by VARCHAR(100) NOT NULL DEFAULT current_user,
    changed_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- ÍNDICES ESTRATÉGICOS PARA AUDITORÍA
-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- Índice para búsquedas por registro específico (más común)
CREATE INDEX IF NOT EXISTS idx_audit_log_table_record ON audit_log(table_name, record_id);

-- Índice para consultas cronológicas (timeline de cambios)
CREATE INDEX IF NOT EXISTS idx_audit_log_changed_at ON audit_log(changed_at);

-- Índices GIN para consultas JSONB (búsqueda por contenido)
CREATE INDEX IF NOT EXISTS idx_audit_log_old_data_gin ON audit_log USING GIN(old_data);
CREATE INDEX IF NOT EXISTS idx_audit_log_new_data_gin ON audit_log USING GIN(new_data);

-- Índice compuesto para audit_history (consulta completa por registro)
CREATE INDEX IF NOT EXISTS idx_audit_log_table_record_time ON audit_log(table_name, record_id, changed_at);

-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- COMENTARIOS DE DOCUMENTACIÓN
-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
COMMENT ON TABLE audit_log IS 'Tabla de auditoría: registra todos los cambios en tablas de dominio (Clean Architecture - Infraestructura)';

COMMENT ON COLUMN audit_log.id IS 'Identificador único auto-incremental del registro de auditoría';
COMMENT ON COLUMN audit_log.table_name IS 'Nombre de la tabla del dominio que fue modificada (customers, products, orders)';
COMMENT ON COLUMN audit_log.record_id IS 'ID del registro específico que sufrió el cambio';
COMMENT ON COLUMN audit_log.operation IS 'Tipo de operación: I=Insert, U=Update, D=Delete';
COMMENT ON COLUMN audit_log.old_data IS 'Estado anterior del registro en formato JSONB (NULL para INSERT)';
COMMENT ON COLUMN audit_log.new_data IS 'Estado nuevo del registro en formato JSONB (NULL para DELETE)';
COMMENT ON COLUMN audit_log.changed_by IS 'Usuario de PostgreSQL que realizó el cambio';
COMMENT ON COLUMN audit_log.changed_at IS 'Fecha y hora exacta del cambio (con timezone)';

-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- DOCUMENTACIÓN DE DECISIONES ARQUITECTÓNICAS
-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- Explicación por qué no hay foreign keys a tablas de dominio:
-- 1. Clean Architecture: el dominio no debe depender de infraestructura
-- 2. Independencia: permite eliminar tablas de dominio sin afectar auditoría histórica
-- 3. Flexibilidad: soporta escenarios donde registros fueron eliminados
-- 4. Performance: evita overhead de validación de FK en cada operación de auditoría

COMMIT;

-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- VERIFICACIÓN POST-MIGRACIÓN
-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- Confirmar que la tabla de auditoría fue creada correctamente
DO $$
BEGIN
    RAISE NOTICE '✅ Verificación de tabla audit_log:';
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'audit_log') THEN
        RAISE NOTICE '   ✓ Tabla audit_log creada exitosamente';
        
        -- Verificar índices creados
        IF EXISTS (SELECT 1 FROM pg_indexes WHERE tablename = 'audit_log' AND indexname = 'idx_audit_log_table_record') THEN
            RAISE NOTICE '   ✓ Índice table_name+record_id creado';
        END IF;
        
        IF EXISTS (SELECT 1 FROM pg_indexes WHERE tablename = 'audit_log' AND indexname = 'idx_audit_log_changed_at') THEN
            RAISE NOTICE '   ✓ Índice changed_at creado';
        END IF;
        
        IF EXISTS (SELECT 1 FROM pg_indexes WHERE tablename = 'audit_log' AND indexname = 'idx_audit_log_old_data_gin') THEN
            RAISE NOTICE '   ✓ Índice GIN old_data creado';
        END IF;
        
        IF EXISTS (SELECT 1 FROM pg_indexes WHERE tablename = 'audit_log' AND indexname = 'idx_audit_log_new_data_gin') THEN
            RAISE NOTICE '   ✓ Índice GIN new_data creado';
        END IF;
        
        IF EXISTS (SELECT 1 FROM pg_indexes WHERE tablename = 'audit_log' AND indexname = 'idx_audit_log_table_record_time') THEN
            RAISE NOTICE '   ✓ Índice compuesto table_name+record_id+changed_at creado';
        END IF;
        
        RAISE NOTICE '🎉 Tabla de auditoría lista para triggers (migraciones V3-V4)';
    ELSE
        RAISE EXCEPTION '❌ Error: La tabla audit_log no fue creada';
    END IF;
END $$;