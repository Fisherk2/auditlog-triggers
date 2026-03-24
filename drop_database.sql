-- 🮙🮘🮙🮘🮙🮙🮘🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮘🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙
-- LIMPIEZA COMPLETA DEL SISTEMA DE AUDITORÍA
-- Purpose: Elimina base de datos, usuario y todos los componentes del sistema
-- Author: fisherk2
-- Version: 2.0 - Versión completa con limpieza de componentes
-- Date: 2026-03-24
-- DANGER LEVEL: CRITICAL - OPERACIÓN DESTRUCTIVA COMPLETA
-- 🮙🮘🮙🮘🮙🮙🮘🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮘🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙

-- ⚠️⚠️⚠️ ADVERTENCIA: ESTE SCRIPT ELIMINARÁ TODOS LOS DATOS Y COMPONENTES ⚠️⚠️⚠️
-- ⚠️⚠️⚠️ ADVERTENCIA: ESTA OPERACIÓN ES IRREVERSIBLE ⚠️⚠️⚠️
-- ⚠️⚠️⚠️ ADVERTENCIA: NUNCA EJECUTAR EN PRODUCCIÓN SIN APROBACIÓN ⚠️⚠️⚠️

--◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤
-- FASE 1: VERIFICACIÓN Y PREPARACIÓN
--◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤

DO $$
BEGIN
    -- Verificar si la base de datos existe
    IF EXISTS (SELECT 1 FROM pg_database WHERE datname = 'auditlog_db_example') THEN
        RAISE NOTICE '🗑️ Base de datos encontrada: auditlog_db_example';
        RAISE NOTICE '� Terminando conexiones activas...';
        
        -- Terminar todas las conexiones activas a la base de datos
        PERFORM pg_terminate_backend(pid) 
        FROM pg_stat_activity 
        WHERE datname = 'auditlog_db_example' 
        AND pid <> pg_backend_pid();
        
        -- Esperar un momento para que las conexiones se terminen
        PERFORM pg_sleep(1);
        
        RAISE NOTICE '🗑️ Eliminando base de datos: auditlog_db_example';
    ELSE
        RAISE NOTICE 'ℹ️ La base de datos auditlog_db_example no existe';
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '⚠️ Error en preparación: %', SQLERRM;
END $$;

--◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤
-- FASE 2: ELIMINACIÓN DE BASE DE DATOS
--◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤

DROP DATABASE IF EXISTS auditlog_db_example;

--◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤
-- FASE 3: ELIMINACIÓN DE USUARIO
--◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤

DO $$
BEGIN
    -- Eliminar usuario de la base de datos
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'auditlog_admin') THEN
        RAISE NOTICE '🗑️ Eliminando usuario: auditlog_admin';
        EXECUTE 'DROP USER IF EXISTS auditlog_admin';
    ELSE
        RAISE NOTICE 'ℹ️ El usuario auditlog_admin no existe';
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '⚠️ Error al eliminar usuario: %', SQLERRM;
END $$;

--◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤
-- FASE 4: VERIFICACIÓN FINAL
--◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '🎉 LIMPIEZA COMPLETA FINALIZADA';
    RAISE NOTICE '==========================================';
    
    -- Verificar base de datos
    IF NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = 'auditlog_db_example') THEN
        RAISE NOTICE '✅ Base de datos: auditlog_db_example - ELIMINADA';
    ELSE
        RAISE NOTICE '❌ Base de datos: auditlog_db_example - AÚN EXISTE';
    END IF;
    
    -- Verificar usuario
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'auditlog_admin') THEN
        RAISE NOTICE '✅ Usuario: auditlog_admin - ELIMINADO';
    ELSE
        RAISE NOTICE '❌ Usuario: auditlog_admin - AÚN EXISTE';
    END IF;
    
    RAISE NOTICE '==========================================';
    RAISE NOTICE '🔄 Para reinstalar, ejecuta: ./test/run_tests.sh';
    RAISE NOTICE '';
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error en verificación final: %', SQLERRM;
END $$;

--◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤
-- INSTRUCCIONES DE USO
--◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤

--▁▂▃▄▅▆▇███████ CÓMO EJECUTAR ESTE SCRIPT ███████▇▆▅▄▃▂▁

-- 1. Verificar que estás en el entorno correcto (development/testing)
-- 2. Ejecutar: psql -U postgres -d postgres -f drop_database.sql
-- 3. Verificar que todo fue eliminado: \l y \du

-- ⚠️⚠️⚠️ RECORDATORIO FINAL: ESTE SCRIPT ES DESTRUCTIVO COMPLETO ⚠️⚠️⚠️
-- ⚠️⚠️⚠️ NO EJECUTAR EN PRODUCCIÓN SIN SUPERVISIÓN ⚠️⚠️⚠️