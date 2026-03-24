# JSONB Cheatsheet - PostgreSQL para Sistema de Auditoría

Guía de referencia rápida de operadores y consultas JSONB para PostgreSQL, enfocada en el sistema de auditoría con `audit_log` y campos `old_data`/`new_data`.

---

## 📋 Tabla de Referencia Rápida

| Operador | Descripción | Ejemplo | Uso Típico |
|----------|------------|---------|-------------|
| `->` | Extraer campo como JSONB | `new_data->'price'` | Anidado o further processing |
| `->>` | Extraer campo como TEXT | `new_data->>'price'` | Comparaciones, WHERE clauses |
| `#>` | Extraer path JSONB | `new_data#>'{product,price}'` | Campos anidados profundos |
| `#>>` | Extraer path TEXT | `new_data#>>'{product,price}'` | Comparaciones anidadas |
| `?` | Existe clave | `new_data ? 'price'` | Verificar existencia de campo |
| `?|` | Existe alguna clave | `new_data ?| array['price','name']` | Múltiples campos posibles |
| `?&` | Existen todas las claves | `new_data ?& array['price','name']` | Validación de schema |
| `@>` | Contiene JSONB | `new_data @> '{"price": 100}'` | Buscar valor específico |
| `<@` | Está contenido en JSONB | `'{"price": 100}' <@ new_data` | Validar sub-documento |
| `||` | Concatenar JSONB | `old_data || new_data` | Combinar documentos |
| `-` | Eliminar clave | `new_data - 'price'` | Remover campo |
| `#-` | Eliminar path | `new_data #- '{product,price}'` | Remover campo anidado |

---

## 🎯 Introducción a JSONB

### ¿Qué es JSONB?

**JSONB** (JSON Binary) es el tipo de dato nativo de PostgreSQL para almacenar datos JSON en formato binario optimizado.

**Ventajas vs JSON:**
- **Storage más eficiente**: ~20-30% más compacto
- **Índices GIN**: Permite indexación de contenido JSON
- **Operadores optimizados**: Más rápidos que JSON text
- **Validación automática**: Solo JSON válido puede almacenarse

### ¿Por qué JSONB en Auditoría?

**Clean Architecture Cap. 22**: "The Database Is a Detail" - JSONB permite que la infraestructura de auditoría sea independiente del schema de dominio.

**Beneficios para audit_log:**
- **Universalidad**: Un schema almacena CUALQUIER estructura de datos
- **Flexibilidad**: Agregar columnas a tablas no requiere cambios en audit_log
- **Versionamiento completo**: Almacena estado completo del registro
- **Consultas potentes**: Operadores JSONB permiten búsquedas complejas

**Referencia del Schema:**
```sql
-- migrations/V2__create_audit_log_table.sql
CREATE TABLE audit_log (
    audit_id SERIAL PRIMARY KEY,
    table_name VARCHAR(50) NOT NULL,
    record_id BIGINT NOT NULL,
    operation CHAR(1) NOT NULL CHECK (operation IN ('I', 'U', 'D')),
    old_data JSONB,
    new_data JSONB,
    changed_by VARCHAR(100) NOT NULL,
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

---

## ⚡ Operadores JSONB Básicos

### 1. Operador `->` (Extraer como JSONB)

**Descripción**: Extrae campo como tipo JSONB, permitiendo further processing

```sql
-- Extraer precio como JSONB (útil para operaciones anidadas)
SELECT 
    audit_id,
    new_data->'price' as price_jsonb,
    (new_data->'price')::NUMERIC as price_numeric
FROM audit_history 
WHERE table_name = 'products' 
AND operation = 'U';
```

**Output esperado:**
```
 audit_id | price_jsonb | price_numeric
----------+-------------+---------------
        1 | "100.50"    | 100.50
        2 | "150.75"    | 150.75
```

**Caso de uso**: Extraer datos para further JSONB operations

---

### 2. Operador `->>` (Extraer como TEXT)

**Descripción**: Extrae campo como tipo TEXT, ideal para comparaciones

```sql
-- Encontrar cambios de precio específicos
SELECT 
    audit_id,
    old_data->>'price'::NUMERIC as old_price,
    new_data->>'price'::NUMERIC as new_price,
    changed_at
FROM audit_history 
WHERE table_name = 'products' 
AND operation = 'U'
AND old_data->>'price'::NUMERIC != new_data->>'price'::NUMERIC;
```

**Output esperado:**
```
 audit_id | old_price | new_price | changed_at
----------+-----------+-----------+---------------------------
        1 |     100.50 |    150.75 | 2024-01-15 14:30:22.123
```

**Caso de uso**: Comparaciones, WHERE clauses, ORDER BY

---

### 3. Operador `#>` (Extraer Path como JSONB)

**Descripción**: Extrae campo anidado usando path notation como JSONB

```sql
-- Si tuviéramos estructura anidada: {"product": {"price": 100}}
SELECT 
    audit_id,
    new_data#>'{product,price}' as nested_price
FROM audit_history 
WHERE table_name = 'products';
```

**Output esperado:**
```
 audit_id | nested_price
----------+-------------
        1 | "100.50"
```

**Caso de uso**: Campos anidados profundos, estructuras complejas

---

### 4. Operador `?` (Existe Clave)

**Descripción**: Verifica si una clave existe en el JSONB

```sql
-- Encontrar registros que tienen campo 'price'
SELECT 
    audit_id,
    table_name,
    operation
FROM audit_history 
WHERE new_data ? 'price';
```

**Output esperado:**
```
 audit_id | table_name | operation
----------+------------+-----------
        1 | products   | U
        2 | products   | I
```

**Caso de uso**: Validar existencia de campos, schema evolution

---

### 5. Operador `@>` (Contiene JSONB)

**Descripción**: Verifica si el JSONB contiene el documento especificado

```sql
-- Encontrar cambios donde el precio es exactamente 100.50
SELECT 
    audit_id,
    changed_at
FROM audit_history 
WHERE new_data @> '{"price": 100.50}';
```

**Output esperado:**
```
 audit_id | changed_at
----------+---------------------------
        1 | 2024-01-15 14:30:22.123
```

**Caso de uso**: Búsquedas exactas de valores específicos

---

### 6. Operador `?|` (Existe Alguna Clave)

**Descripción**: Verifica si existe ALGUNA de las claves especificadas

```sql
-- Encontrar registros con cambios en precio O nombre
SELECT 
    audit_id,
    table_name
FROM audit_history 
WHERE new_data ?| array['price', 'name'];
```

**Output esperado:**
```
 audit_id | table_name
----------+------------
        1 | products
        2 | customers
```

**Caso de uso**: Búsquedas flexibles, múltiples campos posibles

---

## 🔍 Consultas Comunes de Auditoría

### 1. Extraer Campo Específico de old_data/new_data

```sql
-- Extraer nombres de clientes cambiados
SELECT 
    audit_id,
    old_data->>'customer_name' as old_name,
    new_data->>'customer_name' as new_name,
    changed_at
FROM audit_history 
WHERE table_name = 'customers' 
AND operation = 'U'
AND old_data->>'customer_name' != new_data->>'customer_name';
```

**Output esperado:**
```
 audit_id | old_name | new_name | changed_at
----------+----------+----------+---------------------------
        1 | John Doe | Jane Doe | 2024-01-15 14:30:22.123
```

---

### 2. Comparar Valores Antes/Después

```sql
-- Cambios de precio con porcentaje de variación
SELECT 
    audit_id,
    old_data->>'price'::NUMERIC as old_price,
    new_data->>'price'::NUMERIC as new_price,
    ROUND(
        ((new_data->>'price'::NUMERIC - old_data->>'price'::NUMERIC) / 
         old_data->>'price'::NUMERIC) * 100, 2
    ) as percent_change,
    changed_at
FROM audit_history 
WHERE table_name = 'products' 
AND operation = 'U'
AND old_data->>'price'::NUMERIC != new_data->>'price'::NUMERIC;
```

**Output esperado:**
```
 audit_id | old_price | new_price | percent_change | changed_at
----------+-----------+-----------+---------------+---------------------------
        1 |    100.50 |    150.75 |         50.00 | 2024-01-15 14:30:22.123
```

---

### 3. Filtrar por Existencia de Campo

```sql
-- Productos que ganaron campo 'description'
SELECT 
    audit_id,
    operation,
    CASE 
        WHEN old_data ? 'description' AND new_data ? 'description' THEN 'Updated'
        WHEN NOT old_data ? 'description' AND new_data ? 'description' THEN 'Added'
        WHEN old_data ? 'description' AND NOT new_data ? 'description' THEN 'Removed'
    END as description_change
FROM audit_history 
WHERE table_name = 'products'
AND (old_data ? 'description' OR new_data ? 'description');
```

**Output esperado:**
```
 audit_id | operation | description_change
----------+-----------+-------------------
        1 | U         | Updated
        2 | I         | Added
```

---

### 4. Filtrar por Valor Dentro de JSONB

```sql
-- Cambios donde el nuevo precio es mayor a 100
SELECT 
    audit_id,
    new_data->>'product_name' as product_name,
    new_data->>'price'::NUMERIC as new_price
FROM audit_history 
WHERE table_name = 'products'
AND new_data->>'price'::NUMERIC > 100;
```

**Output esperado:**
```
 audit_id | product_name | new_price
----------+--------------+-----------
        1 | Laptop Pro   |   150.75
```

---

### 5. Búsquedas Anidadas en JSON

```sql
-- Buscar en arrays (si tuviéramos tags array)
SELECT 
    audit_id,
    new_data->>'product_name' as product_name,
    new_data->'tags' as tags_array
FROM audit_history 
WHERE table_name = 'products'
AND new_data->'tags' @> '["electronics", "premium"]'::jsonb;
```

**Output esperado:**
```
 audit_id | product_name | tags_array
----------+--------------+------------
        1 | Laptop Pro   | ["electronics", "premium"]
```

---

### 6. Agregaciones sobre Campos JSONB

```sql
-- Estadísticas de precios por producto
SELECT 
    MAX(new_data->>'price'::NUMERIC) as max_price,
    MIN(new_data->>'price'::NUMERIC) as min_price,
    AVG(new_data->>'price'::NUMERIC) as avg_price,
    COUNT(*) as total_changes
FROM audit_history 
WHERE table_name = 'products'
AND operation IN ('I', 'U')
AND new_data ? 'price';
```

**Output esperado:**
```
 max_price | min_price | avg_price | total_changes
-----------+-----------+-----------+---------------
    150.75 |     99.99 |   125.37  |            15
```

---

### 7. JOINs con Datos JSONB

```sql
-- Unir cambios de auditoría con datos actuales de productos
SELECT 
    ah.audit_id,
    ah.changed_at,
    ah.new_data->>'price'::NUMERIC as audit_price,
    p.price as current_price,
    p.product_name
FROM audit_history ah
JOIN products p ON p.product_id = ah.record_id
WHERE ah.table_name = 'products'
AND ah.operation = 'U'
AND ah.new_data->>'price'::NUMERIC != p.price;
```

**Output esperado:**
```
 audit_id | changed_at          | audit_price | current_price | product_name
----------+---------------------+-------------+---------------+--------------
        1 | 2024-01-15 14:30:22 |      150.75 |       199.99  | Laptop Pro
```

---

### 8. Time-Travel con get_record_at() + JSONB

```sql
-- Combinar time-travel con extracción JSONB
SELECT 
    get_record_at('products', 1, '2024-01-15 12:00:00-06:00'::timestamp) 
    ->> 'price'::NUMERIC as historical_price,
    get_record_at('products', 1, '2024-01-15 16:00:00-06:00'::timestamp) 
    ->> 'price'::NUMERIC as later_price;
```

**Output esperado:**
```
 historical_price | later_price
------------------+-------------
           100.50 |      150.75
```

---

## 🚀 Índices y Performance

### 1. Crear Índice GIN en Columna JSONB

```sql
-- Índice GIN para búsquedas generales
CREATE INDEX CONCURRENTLY idx_audit_log_new_data_gin 
ON audit_log USING GIN (new_data);

-- Índice GIN para búsquedas de claves específicas
CREATE INDEX CONCURRENTLY idx_audit_log_new_data_price 
ON audit_log USING GIN ((new_data->'price'));

-- Índice B-tree para valores extraídos
CREATE INDEX CONCURRENTLY idx_audit_log_new_data_price_btree 
ON audit_log USING BTREE ((new_data->>'price'::NUMERIC));
```

**Cuándo usar cada tipo:**
- **GIN**: Para operadores `@>`, `?`, `?|`, `?&`
- **GIN con path**: Para búsquedas específicas de campo
- **BTREE**: Para comparaciones, rangos, ORDER BY

---

### 2. Validar Performance con EXPLAIN ANALYZE

```sql
-- Verificar que el índice se usa
EXPLAIN ANALYZE
SELECT audit_id, changed_at
FROM audit_history 
WHERE new_data @> '{"price": 100.50}';

-- Output esperado:
-- Index Scan using idx_audit_log_new_data_gin on audit_history  (cost=...)
```

---

### 3. Advertencias de Performance

**Cuando NO indexar JSONB:**
- **Volúmenes pequeños** (<10,000 registros): Scan secuencial puede ser más rápido
- **Updates frecuentes**: Índices GIN tienen overhead en escritura
- **Queries muy específicas**: BTREE sobre valor extraído puede ser mejor

**Best practices:**
- **Monitorear uso**: `pg_stat_user_indexes` para ver qué índices se usan
- **Testear con datos reales**: Performance varía con distribución de datos
- **Considerar partial indexes**: Para subsets específicos de datos

---

## ⚠️ Errores Comunes y Soluciones

### 1. Error de Tipo (texto vs JSONB)

**Error:**
```sql
-- ERROR: operator does not exist: text ->> text
SELECT 'price' ->> 'value' FROM audit_log;
```

**Solución:**
```sql
-- Asegurar que la columna es JSONB
SELECT new_data->>'price' FROM audit_history;
```

---

### 2. Campos NULL en JSONB

**Problema:** Campos inexistentes vs NULL

```sql
-- Distinguir entre campo que no existe vs campo con valor NULL
SELECT 
    audit_id,
    CASE 
        WHEN new_data ? 'price' THEN 
            CASE 
                WHEN new_data->>'price' IS NULL THEN 'NULL'
                ELSE 'NOT NULL'
            END
        ELSE 'MISSING'
    END as price_status
FROM audit_history;
```

**Output esperado:**
```
 audit_id | price_status
----------+-------------
        1 | NOT NULL
        2 | NULL
        3 | MISSING
```

---

### 3. Performance con Grandes Volúmenes

**Problema:** Queries lentas con millones de registros

**Solución:**
```sql
-- 1. Índices específicos
CREATE INDEX CONCURRENTLY idx_audit_log_table_price 
ON audit_history (table_name, (new_data->>'price'::NUMERIC));

-- 2. Partial indexes
CREATE INDEX CONCURRENTLY idx_audit_log_products_price 
ON audit_history ((new_data->>'price'::NUMERIC))
WHERE table_name = 'products' AND new_data ? 'price';

-- 3. Partitioning (para volúmenes muy grandes)
CREATE TABLE audit_history_2024 PARTITION OF audit_history
FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');
```

---

### 4. Codificación de Caracteres Especiales

**Problema:** JSON con caracteres especiales

```sql
-- Manejar caracteres especiales correctamente
SELECT 
    new_data->>'description' as description,
    jsonb_typeof(new_data->'description') as data_type
FROM audit_history 
WHERE new_data ? 'description';

-- Limpiar y normalizar texto
SELECT 
    TRIM(BOTH FROM new_data->>'description') as clean_description,
    REGEXP_REPLACE(new_data->>'description', '[^\w\s]', '', 'g') as alphanumeric_only
FROM audit_history;
```

---

### 5. Consultas que No Usan Índices

**Problema:** Queries lentos que no usan índices GIN

**Diagnóstico:**
```sql
-- Verificar plan de ejecución
EXPLAIN (ANALYZE, BUFFERS) 
SELECT audit_id 
FROM audit_history 
WHERE new_data->>'price'::NUMERIC > 100;

-- Verificar uso de índices
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch
FROM pg_stat_user_indexes 
WHERE tablename = 'audit_history';
```

**Solución:**
```sql
-- Usar operadores compatibles con GIN
-- En lugar de:
WHERE new_data->>'price'::NUMERIC > 100

-- Usar:
WHERE new_data @> '{"price": 100}'
-- O crear índice BTREE sobre el valor extraído
```

---

## 📚 Referencias Adicionales

### Documentación del Proyecto

- **[migrations/V2__create_audit_log_table.sql](../migrations/V2__create_audit_log_table.sql)**: Schema de audit_log
- **[queries/example_audit_queries.sql](../queries/example_audit_queries.sql)**: Más ejemplos JSONB
- **[docs/ERD.md](ERD.md)**: Modelo de datos completo
- **[naming_conventions.md](../naming_conventions.md)**: Convenciones de nombres

### Recursos Externos

- **PostgreSQL JSONB Documentation**: https://www.postgresql.org/docs/current/jsonb.html
- **PostgreSQL Functions and Operators**: https://www.postgresql.org/docs/current/functions-json.html
- **GIN Index Documentation**: https://www.postgresql.org/docs/current/gin.html

---

## 🎯 Resumen Rápido

**Para empezar con JSONB en el sistema de auditoría:**

1. **Extraer datos**: `new_data->>'field_name'::TYPE`
2. **Verificar existencia**: `new_data ? 'field_name'`
3. **Búsquedas exactas**: `new_data @> '{"field": "value"}'`
4. **Índices GIN**: Para operadores @>, ?, ?|, ?&
5. **Índices BTREE**: Para valores extraídos y rangos
6. **Performance**: Monitorear con EXPLAIN ANALYZE

---

**Clean Architecture Cap. 22**: JSONB permite que la infraestructura de auditoría sea independiente del schema de dominio, manteniendo opciones abiertas para futuros cambios.

**Systems Analysis Cap. 10**: Esta cheatsheet reduce el tiempo de onboarding de nuevos desarrolladores al proporcionar ejemplos ejecutables y referencia rápida.

**Software Development Cap. 17**: Documentación versionada con el código, evitando conocimiento perdido y facilitando transferencia de conocimiento.

---

*Guía creada para el sistema de auditoría PostgreSQL Audit Log Triggers - JSONB edition* 🚀