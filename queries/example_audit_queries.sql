-- 🮙🮘🮙🮘🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮙🮙🮙🮙🮘🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙
-- EXAMPLE AUDIT QUERIES (DOCUMENTACIÓN EJECUTABLE)
-- 🮙🮘🮙🮘🮙🮙🮙🮘🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙
-- Propósito: Demostrar uso real del sistema de auditoría como especificación ejecutable
-- Arquitectura: Clean Architecture - ejemplos en capa externa de documentación
-- Patrón: Executable Specification - documentación que se puede validar

-- ================================================================================
-- SECCIÓN 1: CONSULTAS BÁSICAS DE AUDITORÍA
-- ================================================================================
-- Estas consultas demuestran el uso fundamental del sistema de auditoría
-- Son el punto de entrada para analistas y auditores nuevos

-- 1. Últimos 10 cambios en el sistema (cualquier tabla)
-- Propósito: Vista general de actividad reciente para monitoreo en tiempo real
-- Output esperado: Lista cronológica con tabla, registro, operación y timestamp
SELECT 
    table_name,
    record_id,
    operation,
    changed_by,
    changed_at,
    ROW_NUMBER() OVER (ORDER BY changed_at DESC) as recent_rank
FROM audit_history 
ORDER BY changed_at DESC 
LIMIT 10;

-- 2. Historial completo de un registro específico (customer)
-- Propósito: Trazar todos los cambios de un cliente para análisis forense
-- Output esperado: Timeline completo de cambios del customer_id = 1
SELECT 
    operation,
    changed_by,
    changed_at,
    old_data,
    new_data,
    row_sequence
FROM audit_history 
WHERE table_name = 'customers' 
AND record_id = 1
ORDER BY changed_at DESC;

-- 3. Cambios realizados por un usuario específico
-- Propósito: Investigar actividad de un usuario particular (auditoría de acceso)
-- Output esperado: Todos los cambios hechos por 'auditlog_admin'
SELECT 
    table_name,
    COUNT(*) as change_count,
    MIN(changed_at) as first_change,
    MAX(changed_at) as last_change
FROM audit_history 
WHERE changed_by = 'auditlog_admin'
GROUP BY table_name
ORDER BY change_count DESC;

-- 4. Todos los cambios en un rango de fechas
-- Propósito: Analizar actividad durante un período específico (ej: incidente de seguridad)
-- Output esperado: Cambios entre 2024-01-15 y 2024-01-20
SELECT 
    table_name,
    operation,
    COUNT(*) as changes
FROM audit_history 
WHERE changed_at BETWEEN '2024-01-15' AND '2024-01-20'
GROUP BY table_name, operation
ORDER BY changes DESC;

-- 5. Conteo de operaciones por tabla y tipo (I/U/D)
-- Propósito: Dashboard de actividad general del sistema
-- Output esperado: Resumen estadístico de operaciones por tabla
SELECT 
    table_name,
    operation,
    COUNT(*) as operation_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY table_name), 2) as percentage
FROM audit_history 
GROUP BY table_name, operation
ORDER BY table_name, operation;

-- ================================================================================
-- SECCIÓN 2: CONSULTAS CON JSONB
-- ================================================================================
-- Estas consultas demuestran el poder de JSONB para análisis detallado
-- Los operadores JSONB permiten extraer y filtrar datos específicos

-- 6. Extraer campo específico de old_data (precio anterior de producto)
-- Propósito: Ver historial de precios de un producto específico
-- Operador JSONB: ->> (extrae texto de JSONB)
-- Output esperado: Lista de precios anteriores del product_id = 1
SELECT 
    changed_at,
    old_data->>'price' as previous_price,
    new_data->>'price' as new_price,
    changed_by
FROM audit_history 
WHERE table_name = 'products' 
AND record_id = 1 
AND operation = 'U'
AND old_data->>'price' IS NOT NULL
ORDER BY changed_at DESC;

-- 7. Extraer campo específico de new_data (email nuevo de customer)
-- Propósito: Trazar cambios de email para cumplimiento de privacidad
-- Operador JSONB: -> (extrae JSONB) y ->> (extrae texto)
-- Output esperado: Historial de cambios de email del customer_id = 2
SELECT 
    changed_at,
    old_data->>'email' as old_email,
    new_data->>'email' as new_email,
    changed_by
FROM audit_history 
WHERE table_name = 'customers' 
AND record_id = 2 
AND operation = 'U'
AND new_data ? 'email'  -- Operador ? para verificar existencia de clave
ORDER BY changed_at DESC;

-- 8. Buscar cambios donde un campo específico fue modificado
-- Propósito: Encontrar todos los cambios que afectaron el stock de productos
-- Operador JSONB: @> (contiene) para verificar si el campo existe
-- Output esperado: Todos los cambios que modificaron stock_quantity
SELECT 
    record_id,
    operation,
    old_data->>'stock_quantity' as old_stock,
    new_data->>'stock_quantity' as new_stock,
    changed_at
FROM audit_history 
WHERE table_name = 'products'
AND (old_data ? 'stock_quantity' OR new_data ? 'stock_quantity')
ORDER BY changed_at DESC;

-- 9. Comparar valores antes/después en una sola consulta
-- Propósito: Calcular deltas de cambios (ej: diferencias de precio)
-- Operador JSONB: ->> para extraer valores numéricos y calcular diferencias
-- Output esperado: Cambios de precio con diferencias calculadas
SELECT 
    record_id,
    old_data->>'price'::NUMERIC as old_price,
    new_data->>'price'::NUMERIC as new_price,
    (new_data->>'price'::NUMERIC - old_data->>'price'::NUMERIC) as price_difference,
    changed_at
FROM audit_history 
WHERE table_name = 'products' 
AND operation = 'U'
AND old_data->>'price'::NUMERIC != new_data->>'price'::NUMERIC
ORDER BY ABS(new_data->>'price'::NUMERIC - old_data->>'price'::NUMERIC) DESC;

-- 10. Filtrar por contenido dentro de JSONB (productos con precio > 100)
-- Propósito: Encontrar cambios en productos de alto valor
-- Operador JSONB: ->> para extraer y filtrar por valor numérico
-- Output esperado: Cambios en productos con precio mayor a 100
SELECT 
    record_id,
    operation,
    new_data->>'name' as product_name,
    new_data->>'price' as price,
    changed_at
FROM audit_history 
WHERE table_name = 'products'
AND new_data->>'price'::NUMERIC > 100
ORDER BY changed_at DESC;

-- ================================================================================
-- SECCIÓN 3: CONSULTAS DE TIME-TRAVEL
-- ================================================================================
-- Estas consultas demuestran la capacidad de reconstrucción histórica
-- Usan la función get_record_at() para consultar estados pasados

-- 11. Usar get_record_at() para ver estado histórico de producto
-- Propósito: Ver cómo era un producto en una fecha específica
-- Output esperado: Estado del product_id = 1 el 2024-01-15
SELECT * FROM get_record_at(
    'products', 
    1, 
    '2024-01-15 12:00:00-06:00'::timestamp
);

-- 12. Comparar estado actual vs estado histórico
-- Propósito: Analizar evolución de un registro en el tiempo
-- Output esperado: Comparación lado a lado de estados
WITH historical AS (
    SELECT * FROM get_record_at('products', 1, '2024-01-15 12:00:00-06:00'::timestamp)
),
current AS (
    SELECT to_jsonb(p) as current_data FROM products p WHERE id = 1
)
SELECT 
    historical.record_data as historical_state,
    current.current_data as current_state,
    historical.found as existed_back_then
FROM historical, current;

-- 13. Reconstruir estado de orden en fecha específica
-- Propósito: Ver detalles completos de una orden en momento de entrega
-- Output esperado: Estado completo de la orden en fecha específica
SELECT 
    record_data->>'total_amount' as order_total,
    record_data->>'status' as order_status,
    record_data->>'customer_id' as customer,
    as_of_timestamp
FROM get_record_at('orders', 1, '2024-01-12 10:00:00-06:00'::timestamp);

-- ================================================================================
-- SECCIÓN 4: CONSULTAS ANALÍTICAS
-- ================================================================================
-- Estas consultas demuestran análisis avanzados para business intelligence
-- Combinan agregación con datos de auditoría para insights

-- 14. Dashboard: cambios por día en última semana
-- Propósito: Tendencia de actividad diaria para monitoreo
-- Output esperado: Serie temporal de actividad por día
SELECT 
    DATE(changed_at) as change_date,
    COUNT(*) as total_changes,
    COUNT(DISTINCT table_name) as tables_affected,
    COUNT(DISTINCT changed_by) as active_users
FROM audit_history 
WHERE changed_at >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY DATE(changed_at)
ORDER BY change_date DESC;

-- 15. Top 5 registros más modificados
-- Propósito: Identificar registros con mayor actividad (potencialmente problemáticos)
-- Output esperado: Ranking de los registros más cambiantes
SELECT 
    table_name,
    record_id,
    COUNT(*) as modification_count,
    MIN(changed_at) as first_modified,
    MAX(changed_at) as last_modified,
    STRING_AGG(DISTINCT operation, ', ') as operations_performed
FROM audit_history 
GROUP BY table_name, record_id
ORDER BY modification_count DESC
LIMIT 5;

-- ================================================================================
-- SECCIÓN 5: CONSULTAS DE DIAGNÓSTICO
-- ================================================================================
-- Estas consultas ayudan a diagnosticar problemas en el sistema

-- 16. Detectar posibles errores (DELETEs masivos)
-- Propósito: Identificar operaciones inusualmente destructivas
-- Output esperado: Alertas de eliminaciones masivas
SELECT 
    changed_by,
    table_name,
    COUNT(*) as delete_count,
    MIN(changed_at) as first_delete,
    MAX(changed_at) as last_delete
FROM audit_history 
WHERE operation = 'DELETE'
GROUP BY changed_by, table_name
HAVING COUNT(*) > 1
ORDER BY delete_count DESC;

-- 17. Verificar integridad de secuencias
-- Propósito: Detectar posibles gaps en secuencias de IDs
-- Output esperado: Análisis de continuidad de cambios por registro
WITH sequence_analysis AS (
    SELECT 
        table_name,
        record_id,
        COUNT(*) as change_count,
        MIN(row_sequence) as min_sequence,
        MAX(row_sequence) as max_sequence
    FROM audit_history 
    GROUP BY table_name, record_id
    HAVING COUNT(*) != (MAX(row_sequence) - MIN(row_sequence) + 1)
)
SELECT 
    table_name,
    record_id,
    change_count,
    max_sequence - min_sequence + 1 as expected_sequence_length,
    change_count - (max_sequence - min_sequence + 1) as sequence_gap
FROM sequence_analysis
ORDER BY sequence_gap DESC;