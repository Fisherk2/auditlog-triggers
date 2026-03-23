-- 🮙🮘🮙🮘🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮙🮙🮙🮙🮙🮘🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙
-- SEED ECOMMERCE DATA (DATOS DE PRUEBA PARA AUDITORÍA)
-- 🮙🮘🮙🮘🮙🮙🮙🮘🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙🮙
-- Propósito: Poblar tablas de dominio con datos realistas para testing
-- Arquitectura: Clean Architecture - seeds son infraestructura de testing
-- Patrón: Test Data Pattern - datos diseñados para validar auditoría

BEGIN;

-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- LIMPIEZA Y RESET DE SECUENCIAS (IDEMPOTENCIA)
-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- TRUNCATE + RESTART IDENTITY permite re-ejecución limpia del seed
TRUNCATE TABLE orders, products, customers RESTART IDENTITY CASCADE;

-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- INSERTAR CUSTOMERS (5 REGISTROS)
-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- Datos variados para testing de auditoría con diferentes formatos
INSERT INTO customers (name, email, phone, created_at, updated_at) VALUES
('Juan Carlos Rodríguez', 'juan.rodriguez@email.com', '+1-555-0101', '2024-01-01 09:00:00-06:00', '2024-01-01 09:00:00-06:00'),
('Maria García López', 'maria.garcia@email.com', '+1-555-0102', '2024-01-02 10:30:00-06:00', '2024-01-02 10:30:00-06:00'),
('John Smith', 'john.smith@email.com', '+1-555-0103', '2024-01-03 14:15:00-06:00', '2024-01-03 14:15:00-06:00'),
('Ana Martínez Silva', 'ana.martinez@email.com', NULL, '2024-01-04 16:45:00-06:00', '2024-01-04 16:45:00-06:00'),
('Robert Johnson', 'robert.johnson@email.com', '+1-555-0104', '2024-01-05 11:20:00-06:00', '2024-01-05 11:20:00-06:00');

-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- INSERTAR PRODUCTS (10 REGISTROS)
-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- Productos realistas con diferentes rangos de precio y stock
INSERT INTO products (name, description, price, stock_quantity, is_active, created_at, updated_at) VALUES
('Laptop Pro 15"', 'High-performance laptop with 16GB RAM and 512GB SSD', 1299.99, 25, true, '2024-01-01 08:00:00-06:00', '2024-01-01 08:00:00-06:00'),
('Wireless Mouse', 'Ergonomic wireless mouse with precision tracking', 29.99, 150, true, '2024-01-01 08:15:00-06:00', '2024-01-01 08:15:00-06:00'),
('Mechanical Keyboard', 'RGB mechanical keyboard with blue switches', 89.99, 45, true, '2024-01-01 08:30:00-06:00', '2024-01-01 08:30:00-06:00'),
('USB-C Hub', '7-in-1 USB-C hub with HDMI and SD card reader', 49.99, 0, false, '2024-01-01 09:00:00-06:00', '2024-01-01 09:00:00-06:00'),
('Monitor 27" 4K', '27-inch 4K monitor with HDR support', 349.99, 12, true, '2024-01-01 09:30:00-06:00', '2024-01-01 09:30:00-06:00'),
('Webcam HD', '1080p HD webcam with noise cancellation', 79.99, 75, true, '2024-01-01 10:00:00-06:00', '2024-01-01 10:00:00-06:00'),
('Desk Lamp LED', 'Adjustable LED desk lamp with USB charging', 35.50, 200, true, '2024-01-01 10:15:00-06:00', '2024-01-01 10:15:00-06:00'),
('External SSD 1TB', 'Portable external SSD 1TB USB 3.0', 159.99, 8, true, '2024-01-01 10:30:00-06:00', '2024-01-01 10:30:00-06:00'),
('Phone Stand', 'Adjustable phone stand for desk use', 15.99, 300, true, '2024-01-01 11:00:00-06:00', '2024-01-01 11:00:00-06:00'),
('Cable Organizer', NULL, 12.99, 500, true, '2024-01-01 11:15:00-06:00', '2024-01-01 11:15:00-06:00');

-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- INSERTAR ORDERS (8 REGISTROS)
-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- Órdenes con diferentes estados y fechas para testing de auditoría
INSERT INTO orders (customer_id, order_date, total_amount, status, created_at, updated_at) VALUES
(1, '2024-01-10 14:30:00-06:00', 1429.97, 'delivered', '2024-01-10 14:30:00-06:00', '2024-01-10 14:30:00-06:00'),
(2, '2024-01-12 09:15:00-06:00', 89.99, 'shipped', '2024-01-12 09:15:00-06:00', '2024-01-12 09:15:00-06:00'),
(3, '2024-01-15 16:45:00-06:00', 39.98, 'pending', '2024-01-15 16:45:00-06:00', '2024-01-15 16:45:00-06:00'),
(1, '2024-01-18 11:20:00-06:00', 159.99, 'confirmed', '2024-01-18 11:20:00-06:00', '2024-01-18 11:20:00-06:00'),
(4, '2024-01-20 13:10:00-06:00', 349.99, 'cancelled', '2024-01-20 13:10:00-06:00', '2024-01-20 13:10:00-06:00'),
(5, '2024-01-22 10:00:00-06:00', 95.98, 'delivered', '2024-01-22 10:00:00-06:00', '2024-01-22 10:00:00-06:00'),
(2, '2024-01-25 15:30:00-06:00', 51.48, 'shipped', '2024-01-25 15:30:00-06:00', '2024-01-25 15:30:00-06:00'),
(3, '2024-01-28 09:45:00-06:00', 1299.99, 'pending', '2024-01-28 09:45:00-06:00', '2024-01-28 09:45:00-06:00');

COMMIT;

-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- VERIFICACIÓN POST-SEED
-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
DO $$
DECLARE
    customer_count INTEGER;
    product_count INTEGER;
    order_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO customer_count FROM customers;
    SELECT COUNT(*) INTO product_count FROM products;
    SELECT COUNT(*) INTO order_count FROM orders;
    
    RAISE NOTICE '✅ Verificación de datos seed:';
    RAISE NOTICE '   ✓ Customers: % (esperado: 5)', customer_count;
    RAISE NOTICE '   ✓ Products: % (esperado: 10)', product_count;
    RAISE NOTICE '   ✓ Orders: % (esperado: 8)', order_count;
    
    IF customer_count = 5 AND product_count = 10 AND order_count = 8 THEN
        RAISE NOTICE '🎉 Datos de prueba listos para validar auditoría';
        RAISE NOTICE '💡 Los triggers han capturado estos cambios en audit_log';
    ELSE
        RAISE EXCEPTION '❌ Error: Conteo incorrecto de registros';
    END IF;
END $$;