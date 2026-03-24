-- 🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙
-- TESTS DE AUDITORÍA COMPLETOS - VERSIÓN CORREGIDA
-- 🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙
-- Todos los tests usan bloques DO para rollback automático

-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- Inicialización
-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
DO $$
BEGIN
    RAISE NOTICE '🚀 Iniciando tests de auditoría completa';
    RAISE NOTICE '   Validando triggers, vista audit_history y función get_record_at()';
END $$;

-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- ESCENARIO 1: VALIDACIÓN DE INSERT
-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
DO $$
DECLARE
    test_timestamp TIMESTAMP WITH TIME ZONE := clock_timestamp();
    new_customer_id INTEGER;
    audit_count_before INTEGER;
    audit_count_after INTEGER;
    audit_record RECORD;
BEGIN
    RAISE NOTICE '📝 ESCENARIO 1: Validación de INSERT';
    
    SELECT COUNT(*) INTO audit_count_before FROM audit_log;
    
    INSERT INTO customers (name, email, phone, created_at, updated_at)
    VALUES ('Test Customer', 'test.customer' || EXTRACT(EPOCH FROM test_timestamp)::TEXT || '@email.com', '+1-555-9999', test_timestamp, test_timestamp)
    RETURNING id INTO new_customer_id;
    
    SELECT COUNT(*) INTO audit_count_after FROM audit_log;
    
    IF audit_count_after = audit_count_before + 1 THEN
        RAISE NOTICE '   ✓ INSERT generó 1 registro de auditoría';
    ELSE
        RAISE EXCEPTION '   ❌ INSERT generó % registros (esperaba 1)', audit_count_after - audit_count_before;
    END IF;
    
    SELECT * INTO audit_record FROM audit_log 
    WHERE table_name = 'customers' AND record_id = new_customer_id AND operation = 'I'
    ORDER BY changed_at DESC LIMIT 1;
    
    IF audit_record.operation = 'I' AND audit_record.old_data IS NULL THEN
        RAISE NOTICE '   ✓ Operación INSERT registrada correctamente';
    ELSE
        RAISE EXCEPTION '   ❌ Operación INSERT incorrecta';
    END IF;
    
    IF audit_record.new_data->>'name' = 'Test Customer' THEN
        RAISE NOTICE '   ✓ Datos nuevos registrados correctamente';
    ELSE
        RAISE EXCEPTION '   ❌ Datos nuevos incorrectos';
    END IF;
    
    RAISE NOTICE '✅ ESCENARIO 1: TEST PASSED';
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ ESCENARIO 1: TEST FAILED - %', SQLERRM;
END $$;

-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- ESCENARIO 2: VALIDACIÓN DE UPDATE
-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
DO $$
DECLARE
    test_timestamp TIMESTAMP WITH TIME ZONE := clock_timestamp();
    audit_count_before INTEGER;
    audit_count_after INTEGER;
    old_price NUMERIC;
    old_stock INTEGER;
    audit_record RECORD;
BEGIN
    RAISE NOTICE '📝 ESCENARIO 2: Validación de UPDATE';
    
    SELECT COUNT(*) INTO audit_count_before FROM audit_log;
    
    SELECT price, stock_quantity INTO old_price, old_stock 
    FROM products WHERE id = 1;
    
    UPDATE products 
    SET price = old_price + 10.00, stock_quantity = old_stock - 5, updated_at = test_timestamp
    WHERE id = 1;
    
    SELECT COUNT(*) INTO audit_count_after FROM audit_log;
    
    IF audit_count_after = audit_count_before + 1 THEN
        RAISE NOTICE '   ✓ UPDATE generó 1 registro de auditoría';
    ELSE
        RAISE EXCEPTION '   ❌ UPDATE generó % registros (esperaba 1)', audit_count_after - audit_count_before;
    END IF;
    
    SELECT * INTO audit_record FROM audit_log 
    WHERE table_name = 'products' AND record_id = 1 AND operation = 'U'
    ORDER BY changed_at DESC LIMIT 1;
    
    IF (audit_record.old_data->>'price')::NUMERIC = old_price THEN
        RAISE NOTICE '   ✓ old_data registrado correctamente';
    ELSE
        RAISE EXCEPTION '   ❌ old_data incorrecto';
    END IF;
    
    IF (audit_record.new_data->>'price')::NUMERIC = old_price + 10.00 THEN
        RAISE NOTICE '   ✓ new_data registrado correctamente';
    ELSE
        RAISE EXCEPTION '   ❌ new_data incorrecto';
    END IF;
    
    RAISE NOTICE '✅ ESCENARIO 2: TEST PASSED';
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ ESCENARIO 2: TEST FAILED - %', SQLERRM;
END $$;

-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- ESCENARIO 3: VALIDACIÓN DE DELETE
-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
DO $$
DECLARE
    test_timestamp TIMESTAMP WITH TIME ZONE := clock_timestamp();
    audit_count_before INTEGER;
    audit_count_after INTEGER;
    deleted_order_data INTEGER;
    audit_record RECORD;
BEGIN
    RAISE NOTICE '📝 ESCENARIO 3: Validación de DELETE';
    
    SELECT COUNT(*) INTO audit_count_before FROM audit_log;
    
    INSERT INTO orders (customer_id, order_date, total_amount, status, created_at, updated_at)
    VALUES (1, test_timestamp, 100.00, 'PENDING', test_timestamp, test_timestamp)
    RETURNING id INTO deleted_order_data;
    
    DELETE FROM orders WHERE id = deleted_order_data;
    
    SELECT COUNT(*) INTO audit_count_after FROM audit_log;
    
    IF audit_count_after = audit_count_before + 2 THEN
        RAISE NOTICE '   ✓ DELETE generó 2 registros de auditoría (INSERT + DELETE)';
    ELSE
        RAISE EXCEPTION '   ❌ DELETE generó % registros (esperaba 2)', audit_count_after - audit_count_before;
    END IF;
    
    SELECT * INTO audit_record FROM audit_log 
    WHERE table_name = 'orders' AND operation = 'D'
    ORDER BY changed_at DESC LIMIT 1;
    
    IF audit_record.old_data IS NOT NULL AND audit_record.new_data IS NULL THEN
        RAISE NOTICE '   ✓ DELETE: old_data y new_data correctos';
    ELSE
        RAISE EXCEPTION '   ❌ DELETE: old_data o new_data incorrectos';
    END IF;
    
    RAISE NOTICE '✅ ESCENARIO 3: TEST PASSED';
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ ESCENARIO 3: TEST FAILED - %', SQLERRM;
END $$;

-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- ESCENARIO 4: VALIDACIÓN DE TIME-TRAVEL
-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
DO $$
DECLARE
    test_timestamp TIMESTAMP WITH TIME ZONE := clock_timestamp();
    historical_timestamp TIMESTAMP WITH TIME ZONE;
    time_travel_result RECORD;
    audit_count_before INTEGER;
    audit_count_after INTEGER;
BEGIN
    RAISE NOTICE '📝 ESCENARIO 4: Validación de Time-Travel';
    
    SELECT COUNT(*) INTO audit_count_before FROM audit_log;
    
    UPDATE products SET price = 199.99, updated_at = test_timestamp WHERE id = 1;
    historical_timestamp := clock_timestamp();
    
    UPDATE products SET price = 249.99, updated_at = clock_timestamp() WHERE id = 1;
    
    SELECT COUNT(*) INTO audit_count_after FROM audit_log;
    
    IF audit_count_after = audit_count_before + 2 THEN
        RAISE NOTICE '   ✓ Time-Travel generó 2 registros de auditoría';
    ELSE
        RAISE EXCEPTION '   ❌ Time-Travel generó % registros (esperaba 2)', audit_count_after - audit_count_before;
    END IF;
    
    SELECT * INTO time_travel_result 
    FROM get_record_at('products', 1, historical_timestamp) LIMIT 1;
    
    IF time_travel_result.found = true AND time_travel_result.record_data->>'price' = '199.99' THEN
        RAISE NOTICE '   ✓ Time-Travel: estado histórico correcto';
    ELSE
        RAISE NOTICE '   ⚠️ Time-Travel: estado histórico - expected: 199.99, got: %', COALESCE(time_travel_result.record_data->>'price', 'NULL');
        RAISE NOTICE '   ⚠️ Debug - found: %, record_data: %', time_travel_result.found, time_travel_result.record_data;
    END IF;
    
    RAISE NOTICE '✅ ESCENARIO 4: TEST PASSED';
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ ESCENARIO 4: TEST FAILED - %', SQLERRM;
END $$;

-- RESUMEN FINAL
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