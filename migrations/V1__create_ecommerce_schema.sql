-- 🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘
-- MIGRACIÓN V1: CREAR ESQUEMA E-COMMERCE DOMINIO
-- 🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘
-- Propósito: Crear las tablas principales del dominio de negocio
-- Arquitectura: Clean Architecture - estas tablas representan el núcleo del dominio
-- Nota: La auditoría se agregará como capa externa en migraciones posteriores

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
    RAISE NOTICE '   Iniciando migración V1...';
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
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS customers CASCADE;

-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- TABLA 1: CUSTOMERS (Entidad principal del dominio)
-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- Representa a los clientes del sistema - entidad central del negocio
CREATE TABLE IF NOT EXISTS customers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    phone VARCHAR(20) NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Índices para rendimiento en consultas frecuentes
CREATE INDEX IF NOT EXISTS idx_customers_email ON customers(email);
CREATE INDEX IF NOT EXISTS idx_customers_name ON customers(name);

-- Comentarios de documentación del dominio
COMMENT ON TABLE customers IS 'Entidad principal: Clientes del sistema e-commerce';
COMMENT ON COLUMN customers.id IS 'Identificador único auto-incremental del cliente';
COMMENT ON COLUMN customers.name IS 'Nombre completo del cliente (requerido)';
COMMENT ON COLUMN customers.email IS 'Email único del cliente (usado para login/comunicación)';
COMMENT ON COLUMN customers.phone IS 'Teléfono opcional del cliente';
COMMENT ON COLUMN customers.created_at IS 'Fecha de creación del registro (dato de negocio)';
COMMENT ON COLUMN customers.updated_at IS 'Última fecha de modificación (dato de negocio)';

-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- TABLA 2: PRODUCTS (Catálogo de productos)
-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- Representa los productos disponibles para venta - inventario del negocio
CREATE TABLE IF NOT EXISTS products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    description TEXT NULL,
    price DECIMAL(10,2) NOT NULL CHECK (price >= 0),
    stock_quantity INTEGER NOT NULL DEFAULT 0 CHECK (stock_quantity >= 0),
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Índices para búsquedas de productos y filtrado
CREATE INDEX IF NOT EXISTS idx_products_name ON products(name);
CREATE INDEX IF NOT EXISTS idx_products_is_active ON products(is_active);
CREATE INDEX IF NOT EXISTS idx_products_price ON products(price);

-- Comentarios de documentación del dominio
COMMENT ON TABLE products IS 'Catálogo de productos del sistema e-commerce';
COMMENT ON COLUMN products.id IS 'Identificador único auto-incremental del producto';
COMMENT ON COLUMN products.name IS 'Nombre descriptivo del producto (requerido)';
COMMENT ON COLUMN products.description IS 'Descripción detallada opcional del producto';
COMMENT ON COLUMN products.price IS 'Precio unitario del producto (no puede ser negativo)';
COMMENT ON COLUMN products.stock_quantity IS 'Cantidad disponible en inventario (no puede ser negativo)';
COMMENT ON COLUMN products.is_active IS 'Indica si el producto está disponible para venta';
COMMENT ON COLUMN products.created_at IS 'Fecha de creación del producto (dato de negocio)';
COMMENT ON COLUMN products.updated_at IS 'Última fecha de modificación del producto (dato de negocio)';

-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- TABLA 3: ORDERS (Órdenes de compra)
-- ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
-- Representa las transacciones de compra - corazón del negocio e-commerce
CREATE TABLE IF NOT EXISTS orders (
    id SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL,
    order_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    total_amount DECIMAL(10,2) NOT NULL CHECK (total_amount >= 0),
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Foreign key con restricción de integridad referencial
    CONSTRAINT fk_orders_customer 
        FOREIGN KEY (customer_id) 
        REFERENCES customers(id) 
        ON DELETE RESTRICT
);

-- Índices para consultas de órdenes y reporting
CREATE INDEX IF NOT EXISTS idx_orders_customer_id ON orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_order_date ON orders(order_date);
CREATE INDEX IF NOT EXISTS idx_orders_total_amount ON orders(total_amount);

-- Comentarios de documentación del dominio
COMMENT ON TABLE orders IS 'Órdenes de compra del sistema e-commerce';
COMMENT ON COLUMN orders.id IS 'Identificador único auto-incremental de la orden';
COMMENT ON COLUMN orders.customer_id IS 'Referencia al cliente que realizó la orden';
COMMENT ON COLUMN orders.order_date IS 'Fecha en que se realizó la orden (dato de negocio)';
COMMENT ON COLUMN orders.total_amount IS 'Monto total de la orden (no puede ser negativo)';
COMMENT ON COLUMN orders.status IS 'Estado actual de la orden (pending, confirmed, shipped, delivered, cancelled)';
COMMENT ON COLUMN orders.created_at IS 'Fecha de creación del registro (dato de negocio)';
COMMENT ON COLUMN orders.updated_at IS 'Última fecha de modificación del registro (dato de negocio)';
COMMENT ON CONSTRAINT fk_orders_customer IS 'Protege integridad: no permite eliminar clientes con órdenes asociadas';

COMMIT;

-- ▁▂▃▄▅▆▇███████ Verificación post-migración ███████▇▆▅▄▃▂▁
-- Confirmar que las tablas fueron creadas correctamente
DO $$
BEGIN
    RAISE NOTICE '✅ Verificación de esquema e-commerce:';
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'customers') THEN
        RAISE NOTICE '   ✓ Tabla customers creada exitosamente';
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'products') THEN
        RAISE NOTICE '   ✓ Tabla products creada exitosamente';
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'orders') THEN
        RAISE NOTICE '   ✓ Tabla orders creada exitosamente';
    END IF;
    
    RAISE NOTICE '🎉 Esquema e-commerce listo para auditoría (migraciones V2-V4)';
END $$;