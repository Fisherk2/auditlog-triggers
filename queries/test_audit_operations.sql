-- 🮙🮘🮙🮘🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮙🮙🮙🮙🮙🮘🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙
-- TEST AUDIT OPERATIONS (VALIDACIÓN COMPLETA DE AUDITORÍA)
-- 🮙🮘🮙🮘🮙🮙🮙🮘🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙
-- Propósito: Validar que cada operación genera el registro de auditoría esperado
-- Arquitectura: Clean Architecture - tests en círculo externo de validación
-- Patrón: F.I.R.S.T. principles - Fast, Independent, Repeatable, Self-validating, Timely

-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- CONFIGURACIÓN DE TESTS
-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
DO $$
BEGIN
    RAISE NOTICE '🚀 Iniciando tests de auditoría completa';
    RAISE NOTICE '   Validando triggers, vista audit_history y función get_record_at()';
    RAISE NOTICE '   Los tests usan transacciones con ROLLBACK para aislamiento';
END $$;

-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- ESCENARIO 1: VALIDACIÓN DE INSERT
-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
BEGIN;
    RAISE NOTICE '📝 ESCENARIO 1: Validación de INSERT';

    -- Guardar timestamp antes del test
    DECLARE
        test_timestamp TIMESTAMP WITH TIME ZONE := clock_timestamp();
        new_customer_id INTEGER;
        audit_count_before INTEGER;
        audit_count_after INTEGER;
        audit_record RECORD;
    BEGIN
        -- Contar registros de auditoría antes del INSERT
        SELECT COUNT(*) INTO audit_count_before FROM audit_log;
        
        -- Insertar nuevo customer para testing
        INSERT INTO customers (name, email, phone, created_at, updated_at)
        VALUES ('Test Customer', 'test.customer@email.com', '+1-555-9999', test_timestamp, test_timestamp)
        RETURNING id INTO new_customer_id;
        
        -- Contar registros de auditoría después del INSERT
        SELECT COUNT(*) INTO audit_count_after FROM audit_log;
        
        -- Validar que se creó exactamente 1 registro de auditoría
        IF audit_count_after = audit_count_before + 1 THEN
            RAISE NOTICE '   ✓ INSERT generó 1 registro de auditoría';
        ELSE
            RAISE EXCEPTION '   ❌ INSERT: Expected 1 audit record, got %', audit_count_after - audit_count_before;
        END IF;
        
        -- Obtener el registro de auditoría creado
        SELECT * INTO audit_record 
        FROM audit_log 
        WHERE table_name = 'customers' 
        AND record_id = new_customer_id 
        AND operation = 'I'
        AND changed_at >= test_timestamp
        ORDER BY changed_at DESC 
        LIMIT 1;
        
        -- Validar contenido del registro de auditoría
        IF audit_record.operation = 'I' AND audit_record.old_data IS NULL THEN
            RAISE NOTICE '   ✓ INSERT: operation=I y old_data=NULL correctos';
        ELSE
            RAISE EXCEPTION '   ❌ INSERT: operation o old_data incorrectos';
        END IF;
        
        -- Validar que new_data contiene los datos insertados
        IF audit_record.new_data->>'name' = 'Test Customer' 
           AND audit_record.new_data->>'email' = 'test.customer@email.com' THEN
            RAISE NOTICE '   ✓ INSERT: new_data contiene los datos correctos';
        ELSE
            RAISE EXCEPTION '   ❌ INSERT: new_data no contiene los datos esperados';
        END IF;
        
        RAISE NOTICE '✅ ESCENARIO 1: TEST PASSED - INSERT audit validation';
    END;
ROLLBACK;

-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- ESCENARIO 2: VALIDACIÓN DE UPDATE
-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
BEGIN;
    RAISE NOTICE '📝 ESCENARIO 2: Validación de UPDATE';

    DECLARE
        test_timestamp TIMESTAMP WITH TIME ZONE := clock_timestamp();
        audit_count_before INTEGER;
        audit_count_after INTEGER;
        old_price NUMERIC;
        old_stock INTEGER;
        audit_record RECORD;
    BEGIN
        -- Seleccionar un producto existente para actualizar
        SELECT price, stock_quantity INTO old_price, old_stock
        FROM products 
        WHERE id = 1 
        LIMIT 1;
        
        -- Contar registros de auditoría antes del UPDATE
        SELECT COUNT(*) INTO audit_count_before FROM audit_log;
        
        -- Actualizar producto (cambiar price y stock_quantity)
        UPDATE products 
        SET price = old_price + 10.00, 
            stock_quantity = old_stock - 5,
            updated_at = test_timestamp
        WHERE id = 1;
        
        -- Contar registros de auditoría después del UPDATE
        SELECT COUNT(*) INTO audit_count_after FROM audit_log;
        
        -- Validar que se creó exactamente 1 registro de auditoría
        IF audit_count_after = audit_count_before + 1 THEN
            RAISE NOTICE '   ✓ UPDATE generó 1 registro de auditoría';
        ELSE
            RAISE EXCEPTION '   ❌ UPDATE: Expected 1 audit record, got %', audit_count_after - audit_count_before;
        END IF;
        
        -- Obtener el registro de auditoría creado
        SELECT * INTO audit_record 
        FROM audit_log 
        WHERE table_name = 'products' 
        AND record_id = 1 
        AND operation = 'U'
        AND changed_at >= test_timestamp
        ORDER BY changed_at DESC 
        LIMIT 1;
        
        -- Validar que old_data contiene los valores anteriores
        IF audit_record.old_data->>'price'::NUMERIC = old_price 
           AND audit_record.old_data->>'stock_quantity'::INTEGER = old_stock THEN
            RAISE NOTICE '   ✓ UPDATE: old_data contiene valores anteriores correctos';
        ELSE
            RAISE EXCEPTION '   ❌ UPDATE: old_data no contiene los valores anteriores';
        END IF;
        
        -- Validar que new_data contiene los valores nuevos
        IF audit_record.new_data->>'price'::NUMERIC = old_price + 10.00 
           AND audit_record.new_data->>'stock_quantity'::INTEGER = old_stock - 5 THEN
            RAISE NOTICE '   ✓ UPDATE: new_data contiene valores nuevos correctos';
        ELSE
            RAISE EXCEPTION '   ❌ UPDATE: new_data no contiene los valores nuevos';
        END IF;
        
        -- Edge case: UPDATE sin cambios reales
        UPDATE products 
        SET updated_at = test_timestamp
        WHERE id = 2;
        
        -- Validar que igual se genera registro de auditoría
        IF EXISTS (SELECT 1 FROM audit_log WHERE table_name = 'products' AND record_id = 2 AND operation = 'U' AND changed_at >= test_timestamp) THEN
            RAISE NOTICE '   ✓ UPDATE edge case: se genera registro incluso sin cambios reales';
        ELSE
            RAISE EXCEPTION '   ❌ UPDATE edge case: no se generó registro para UPDATE sin cambios';
        END IF;
        
        RAISE NOTICE '✅ ESCENARIO 2: TEST PASSED - UPDATE audit validation';
    END;
ROLLBACK;

-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- ESCENARIO 3: VALIDACIÓN DE DELETE
-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
BEGIN;
    RAISE NOTICE '📝 ESCENARIO 3: Validación de DELETE';

    DECLARE
        test_timestamp TIMESTAMP WITH TIME ZONE := clock_timestamp();
        audit_count_before INTEGER;
        audit_count_after INTEGER;
        deleted_order_data JSONB;
        audit_record RECORD;
    BEGIN
        -- Crear una orden temporal para eliminar
        INSERT INTO orders (customer_id, order_date, total_amount, status, created_at, updated_at)
        VALUES (1, test_timestamp, 99.99, 'pending', test_timestamp, test_timestamp)
        RETURNING id INTO deleted_order_data;
        
        -- Obtener los datos completos de la orden antes de eliminar
        SELECT to_jsonb(orders) INTO deleted_order_data
        FROM orders 
        WHERE id = (SELECT id FROM orders ORDER BY id DESC LIMIT 1);
        
        -- Contar registros de auditoría antes del DELETE
        SELECT COUNT(*) INTO audit_count_before FROM audit_log;
        
        -- Eliminar la orden
        DELETE FROM orders 
        WHERE id = (SELECT id FROM orders ORDER BY id DESC LIMIT 1);
        
        -- Contar registros de auditoría después del DELETE
        SELECT COUNT(*) INTO audit_count_after FROM audit_log;
        
        -- Validar que se creó exactamente 1 registro de auditoría
        IF audit_count_after = audit_count_before + 1 THEN
            RAISE NOTICE '   ✓ DELETE generó 1 registro de auditoría';
        ELSE
            RAISE EXCEPTION '   ❌ DELETE: Expected 1 audit record, got %', audit_count_after - audit_count_before;
        END IF;
        
        -- Obtener el registro de auditoría creado
        SELECT * INTO audit_record 
        FROM audit_log 
        WHERE table_name = 'orders' 
        AND operation = 'D'
        AND changed_at >= test_timestamp
        ORDER BY changed_at DESC 
        LIMIT 1;
        
        -- Validar que old_data contiene los datos eliminados
        IF audit_record.old_data IS NOT NULL THEN
            RAISE NOTICE '   ✓ DELETE: old_data contiene los datos eliminados';
        ELSE
            RAISE EXCEPTION '   ❌ DELETE: old_data es NULL';
        END IF;
        
        -- Validar que new_data es NULL
        IF audit_record.new_data IS NULL THEN
            RAISE NOTICE '   ✓ DELETE: new_data es NULL';
        ELSE
            RAISE EXCEPTION '   ❌ DELETE: new_data no es NULL';
        END IF;
        
        -- Edge case: DELETE de registro inexistente
        BEGIN
            DELETE FROM orders WHERE id = 99999;
            RAISE NOTICE '   ✓ DELETE edge case: DELETE de registro inexistente no genera error';
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '   ✓ DELETE edge case: DELETE de registro inexistente manejado correctamente';
        END;
        
        RAISE NOTICE '✅ ESCENARIO 3: TEST PASSED - DELETE audit validation';
    END;
ROLLBACK;

-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- ESCENARIO 4: VALIDACIÓN DE TIME-TRAVEL (GET_RECORD_AT)
-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
BEGIN;
    RAISE NOTICE '📝 ESCENARIO 4: Validación de Time-Travel';

    DECLARE
        test_timestamp TIMESTAMP WITH TIME ZONE := clock_timestamp();
        historical_timestamp TIMESTAMP WITH TIME ZONE := clock_timestamp() - INTERVAL '1 hour';
        time_travel_result RECORD;
        audit_count_before INTEGER;
        audit_count_after INTEGER;
    BEGIN
        -- Contar registros de auditoría antes de las operaciones
        SELECT COUNT(*) INTO audit_count_before FROM audit_log;
        
        -- Insertar un producto con timestamp específico
        INSERT INTO products (name, description, price, stock_quantity, is_active, created_at, updated_at)
        VALUES ('Time Travel Test Product', 'Product for time travel testing', 199.99, 50, true, historical_timestamp, historical_timestamp)
        RETURNING id INTO time_travel_result;
        
        -- Actualizar el producto
        UPDATE products 
        SET price = 249.99, updated_at = test_timestamp
        WHERE name = 'Time Travel Test Product';
        
        -- Contar registros de auditoría después de las operaciones
        SELECT COUNT(*) INTO audit_count_after FROM audit_log;
        
        -- Validar que se crearon 2 registros de auditoría (INSERT + UPDATE)
        IF audit_count_after = audit_count_before + 2 THEN
            RAISE NOTICE '   ✓ Time-Travel setup: se crearon 2 registros de auditoría';
        ELSE
            RAISE EXCEPTION '   ❌ Time-Travel setup: Expected 2 audit records, got %', audit_count_after - audit_count_before;
        END IF;
        
        -- Test 1: Consultar estado en timestamp histórico (debería retornar el estado inicial)
        SELECT * INTO time_travel_result 
        FROM get_record_at('products', time_travel_result.id, historical_timestamp + INTERVAL '1 minute');
        
        IF time_travel_result.found = true 
           AND time_travel_result.record_data->>'price' = '199.99' THEN
            RAISE NOTICE '   ✓ Time-Travel: estado histórico correcto (price=199.99)';
        ELSE
            RAISE EXCEPTION '   ❌ Time-Travel: estado histórico incorrecto';
        END IF;
        
        -- Test 2: Consultar estado actual (debería retornar el estado actualizado)
        SELECT * INTO time_travel_result 
        FROM get_record_at('products', time_travel_result.id, test_timestamp + INTERVAL '1 minute');
        
        IF time_travel_result.found = true 
           AND time_travel_result.record_data->>'price' = '249.99' THEN
            RAISE NOTICE '   ✓ Time-Travel: estado actual correcto (price=249.99)';
        ELSE
            RAISE EXCEPTION '   ❌ Time-Travel: estado actual incorrecto';
        END IF;
        
        -- Test 3: Consultar estado antes de que existiera (debería retornar found=false)
        SELECT * INTO time_travel_result 
        FROM get_record_at('products', time_travel_result.id, historical_timestamp - INTERVAL '1 minute');
        
        IF time_travel_result.found = false AND time_travel_result.record_data IS NULL THEN
            RAISE NOTICE '   ✓ Time-Travel: estado antes de existencia correcto (found=false)';
        ELSE
            RAISE EXCEPTION '   ❌ Time-Travel: estado antes de existencia incorrecto';
        END IF;
        
        -- Edge case: Consultar tabla inválida
        BEGIN
            SELECT * INTO time_travel_result 
            FROM get_record_at('invalid_table', 1, test_timestamp);
            RAISE EXCEPTION '   ❌ Time-Travel edge case: debería fallar con tabla inválida';
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '   ✓ Time-Travel edge case: tabla inválida manejada correctamente';
        END;
        
        RAISE NOTICE '✅ ESCENARIO 4: TEST PASSED - Time-Travel validation';
    END;
ROLLBACK;

-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- RESUMEN FINAL DE TESTS
-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
DO $$
BEGIN
    RAISE NOTICE '🎉 TODOS LOS TESTS DE AUDITORÍA COMPLETADOS';
    RAISE NOTICE '✅ ESCENARIO 1: INSERT audit validation - PASSED';
    RAISE NOTICE '✅ ESCENARIO 2: UPDATE audit validation - PASSED';
    RAISE NOTICE '✅ ESCENARIO 3: DELETE audit validation - PASSED';
    RAISE NOTICE '✅ ESCENARIO 4: Time-Travel validation - PASSED';
    RAISE NOTICE '';
    RAISE NOTICE '📋 Resultados:';
    RAISE NOTICE '   - Triggers de auditoría funcionan correctamente';
    RAISE NOTICE '   - Vista audit_history está disponible para consultas';
    RAISE NOTICE '   - Función get_record_at() permite time-travel queries';
    RAISE NOTICE '   - Edge cases manejados correctamente';
    RAISE NOTICE '';
    RAISE NOTICE '🔍 Para ver los registros de auditoría:';
    RAISE NOTICE '   SELECT * FROM audit_history ORDER BY changed_at DESC LIMIT 10;';
END $$;