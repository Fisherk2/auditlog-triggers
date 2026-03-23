# Guía de Extensión del Sistema de Auditoría

## Overview

Esta guía explica cómo extender el sistema de auditoría para incluir nuevas tablas de dominio sin modificar el código existente, siguiendo el **Open/Closed Principle** de Clean Architecture.

**Tiempo estimado:** 5-10 minutos  
**Prerrequisitos:** Permisos de CREATE TRIGGER en la base de datos, conocimiento básico de SQL

---

## 1. Introducción y Prerrequisitos

### 1.1 ¿Para quién es esta guía?

- **Desarrolladores** que necesitan agregar auditoría a nuevas tablas
- **DBAs** que administran el sistema de auditoría
- **Arquitectos** que evalúan la escalabilidad del sistema

### 1.2 Prerrequisitos

- ✅ Acceso a la base de datos con permisos de CREATE TRIGGER
- ✅ La función `audit_trigger_func()` ya existe (verificada en [V3__create_audit_trigger_function.sql](../migrations/V3__create_audit_trigger_function.sql))
- ✅ Conocimiento básico de SQL y PostgreSQL
- ✅ La tabla de auditoría `audit_log` existe (verificada en [V2__create_audit_log_table.sql](../migrations/V2__create_audit_log_table.sql))

### 1.3 Open/Closed Principle

Este sistema implementa el **Open/Closed Principle**:
- **Abierto para extensión:** Puedes agregar nuevas tablas sin modificar código existente
- **Cerrado para modificación:** No necesitas cambiar `audit_trigger_func()` ni `audit_log`

---

## 2. Paso a Paso para Extender Auditoría

### Paso 1: Crear Nueva Tabla de Dominio (2 minutos)

Crea tu tabla siguiendo las convenciones del proyecto:

```sql
-- Ejemplo: Tabla categories
CREATE TABLE categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Crear índices si es necesario
CREATE INDEX idx_categories_name ON categories(name);
CREATE INDEX idx_categories_active ON categories(is_active);
```

**Validación:** Ejecuta `SELECT * FROM categories LIMIT 1;` para verificar la tabla existe.

### Paso 2: Verificar audit_trigger_func() (30 segundos)

Verifica que la función genérica de auditoría existe:

```sql
-- Verificar que la función existe
SELECT proname, prosrc FROM pg_proc WHERE proname = 'audit_trigger_func';

-- Debería retornar 1 fila con el nombre de la función
```

**Validación:** Si no existe, ejecuta primero [V3__create_audit_trigger_function.sql](../migrations/V3__create_audit_trigger_function.sql).

### Paso 3: Crear Trigger para Nueva Tabla (3 minutos)

Crea el trigger siguiendo el patrón de [V4__apply_triggers_to_tables.sql](../migrations/V4__apply_triggers_to_tables.sql):

```sql
-- Crear trigger para auditoría de categories
CREATE TRIGGER tg_categories_audit
AFTER INSERT OR UPDATE OR DELETE ON categories
FOR EACH ROW
EXECUTE FUNCTION audit_trigger_func();
```

**Validación:** Ejecuta `SELECT tgname, tgrelid::regclass FROM pg_trigger WHERE tgname = 'tg_categories_audit';`

### Paso 4: Validar que los Logs se Generan (2 minutos)

Inserta datos de prueba para verificar el trigger:

```sql
-- Insertar una categoría de prueba
INSERT INTO categories (name, description, is_active)
VALUES ('Electronics', 'Electronic devices and accessories', true);

-- Verificar que se generó el registro de auditoría
SELECT 
    table_name,
    record_id,
    operation,
    changed_by,
    changed_at
FROM audit_history 
WHERE table_name = 'categories'
ORDER BY changed_at DESC 
LIMIT 1;
```

**Validación:** Deberías ver un registro con operation='INSERT' para la nueva categoría.

### Paso 5: Consultar Auditoría de la Nueva Tabla (1 minuto)

Prueba las diferentes interfaces de consulta:

```sql
-- Historial completo de la tabla
SELECT * FROM audit_history WHERE table_name = 'categories';

-- Time-travel query (si tienes datos históricos)
SELECT * FROM get_record_at('categories', 1, NOW() - INTERVAL '1 hour');
```

**Validación:** Las consultas deben retornar datos de auditoría para la nueva tabla.

---

## 3. Script de Ejemplo Completo

```sql
-- ====================================================================
-- SCRIPT COMPLETO: Extender auditoría a tabla categories
-- ====================================================================

-- Iniciar transacción para seguridad
BEGIN;

-- Paso 1: Crear tabla de dominio
CREATE TABLE categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Crear índices de rendimiento
CREATE INDEX idx_categories_name ON categories(name);
CREATE INDEX idx_categories_active ON categories(is_active);

-- Paso 2: Verificar que audit_trigger_func existe
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'audit_trigger_func') THEN
        RAISE EXCEPTION '❌ audit_trigger_func() no existe. Ejecuta V3__create_audit_trigger_function.sql primero';
    END IF;
    RAISE NOTICE '✅ audit_trigger_func() verificada';
END $$;

-- Paso 3: Crear trigger de auditoría
DROP TRIGGER IF EXISTS tg_categories_audit ON categories;
CREATE TRIGGER tg_categories_audit
AFTER INSERT OR UPDATE OR DELETE ON categories
FOR EACH ROW
EXECUTE FUNCTION audit_trigger_func();

-- Paso 4: Insertar datos de prueba
INSERT INTO categories (name, description, is_active)
VALUES 
    ('Electronics', 'Electronic devices and accessories', true),
    ('Books', 'Physical and digital books', true),
    ('Clothing', 'Apparel and fashion items', true);

-- Paso 5: Validar que la auditoría funciona
DO $$
DECLARE
    audit_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO audit_count 
    FROM audit_history 
    WHERE table_name = 'categories';
    
    IF audit_count = 3 THEN
        RAISE NOTICE '✅ Auditoría funcionando correctamente: % registros creados', audit_count;
    ELSE
        RAISE EXCEPTION '❌ Error en auditoría: Expected 3, got %', audit_count;
    END IF;
END $$;

-- Confirmar transacción
COMMIT;

-- ====================================================================
-- CONSULTAS DE VALIDACIÓN POST-EXTENSIÓN
-- ====================================================================

-- Ver historial de categories
SELECT 
    operation,
    changed_by,
    changed_at,
    new_data->>'name' as category_name
FROM audit_history 
WHERE table_name = 'categories'
ORDER BY changed_at DESC;

-- Probar time-travel
SELECT * FROM get_record_at('categories', 1, NOW());

-- Verificar trigger está activo
SELECT 
    tgname as trigger_name,
    tgrelid::regclass as table_name,
    tgfoid::regproc as function_name
FROM pg_trigger 
WHERE tgname = 'tg_categories_audit';
```

---

## 4. Validación y Troubleshooting

### 4.1 Cómo Verificar que el Trigger Está Funcionando

```sql
-- Consulta 1: Verificar trigger existe
SELECT tgname, tgrelid::regclass FROM pg_trigger 
WHERE tgname = 'tg_categories_audit';

-- Consulta 2: Verificar logs se generan
SELECT COUNT(*) as audit_count 
FROM audit_history 
WHERE table_name = 'categories';

-- Consulta 3: Verificar última operación
SELECT operation, changed_at, new_data 
FROM audit_history 
WHERE table_name = 'categories' 
ORDER BY changed_at DESC 
LIMIT 1;
```

### 4.2 Errores Comunes y Soluciones

| Error | Causa | Solución |
|-------|-------|----------|
| `function audit_trigger_func() does not exist` | No se ejecutó V3 | Ejecuta [V3__create_audit_trigger_function.sql](../migrations/V3__create_audit_trigger_function.sql) |
| `permission denied for trigger` | Permisos insuficientes | Solicita permisos de CREATE TRIGGER |
| `no rows in audit_history` | Trigger no creado o mal configurado | Verifica nombre del trigger y tabla |
| `column "table_name" does not exist` | Vista audit_history no existe | Ejecuta [V5__create_audit_history_view.sql](../extensions/V5__create_audit_history_view.sql) |

### 4.3 Consultas de Diagnóstico

```sql
-- Diagnóstico completo del sistema
DO $$
BEGIN
    RAISE NOTICE '🔍 Diagnóstico del Sistema de Auditoría';
    
    -- Verificar tabla audit_log
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'audit_log') THEN
        RAISE NOTICE '✅ Tabla audit_log existe';
    ELSE
        RAISE NOTICE '❌ Tabla audit_log no existe';
    END IF;
    
    -- Verificar función audit_trigger_func
    IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'audit_trigger_func') THEN
        RAISE NOTICE '✅ Función audit_trigger_func() existe';
    ELSE
        RAISE NOTICE '❌ Función audit_trigger_func() no existe';
    END IF;
    
    -- Verificar triggers activos
    DECLARE
        trigger_count INTEGER;
    BEGIN
        SELECT COUNT(*) INTO trigger_count 
        FROM pg_trigger 
        WHERE tgfoid::regproc = 'audit_trigger_func';
        
        RAISE NOTICE '📊 Triggers de auditoría activos: %', trigger_count;
    END;
    
    -- Verificar vista audit_history
    IF EXISTS (SELECT 1 FROM information_schema.views WHERE table_name = 'audit_history') THEN
        RAISE NOTICE '✅ Vista audit_history existe';
    ELSE
        RAISE NOTICE '❌ Vista audit_history no existe';
    END IF;
    
END $$;
```

---

## 5. Limitaciones y Consideraciones

### 5.1 Tablas que NO Deben Auditarse

- **Tablas de sistema:** `pg_catalog`, `information_schema`
- **Tablas de auditoría:** `audit_log`, `audit_history` (evitar recursión infinita)
- **Tablas temporales:** Tablas con datos muy volátiles
- **Tablas de logs:** Tablas que ya son logs (ej: `application_logs`)

### 5.2 Consideraciones de Performance

```sql
-- Para tablas con alto volumen (>1000 ops/hora), considera:
-- 1. Particionamiento de audit_log por fecha
-- 2. Archivo periódico de logs antiguos
-- 3. Índices adicionales específicos

-- Ejemplo de particionamiento (avanzado)
CREATE TABLE audit_log_y2024m01 PARTITION OF audit_log
FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');
```

### 5.3 Cuándo Considerar Optimizaciones

- **Volumen > 10,000 operaciones/día:** Considerar particionamiento
- **Retención > 1 año:** Implementar archivado automático
- **Consultas lentas:** Agregar índices específicos por tabla

---

## 6. Referencias Cruzadas

- **[V3__create_audit_trigger_function.sql](../migrations/V3__create_audit_trigger_function.sql)**: Función genérica de auditoría (no modificar)
- **[V4__apply_triggers_to_tables.sql](../migrations/V4__apply_triggers_to_tables.sql)**: Patrón de triggers existente
- **[V5__create_audit_history_view.sql](../extensions/V5__create_audit_history_view.sql)**: Vista de consultas (compatible automáticamente)
- **[V6__create_get_record_at_function.sql](../extensions/V6__create_get_record_at_function.sql)**: Time-travel (compatible automáticamente)
- **[naming_conventions.md](naming_conventions.md)**: Convenciones de nombres

---

## 7. Resumen del Proceso

1. ✅ **Crear tabla** con convenciones estándar
2. ✅ **Verificar función** audit_trigger_func() existe
3. ✅ **Crear trigger** siguiendo patrón existente
4. ✅ **Validar** con datos de prueba
5. ✅ **Consultar** usando interfaces existentes

**Resultado:** Nueva tabla completamente integrada al sistema de auditoría sin modificar código existente.

---

## 8. Next Steps

Después de extender la auditoría:

1. **Monitorea performance** de la nueva tabla
2. **Agrega tests** específicos para la nueva tabla
3. **Documenta** cualquier caso especial
4. **Considera archivado** si el volumen es alto

---

## 9. Soporte

Si encuentras problemas:

1. Ejecuta el diagnóstico completo (Sección 4.3)
2. Revisa la tabla de errores comunes (Sección 4.2)
3. Verifica los prerrequisitos (Sección 1.2)
4. Consulta los archivos de referencia (Sección 6)