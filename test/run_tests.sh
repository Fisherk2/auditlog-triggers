# Crear usuario con su respectiva contraseña para la base de datos
psql -U postgres -h localhost -d postgres -c "CREATE USER auditlog_admin WITH PASSWORD 'pimpumpapas';"

# Verificar la existencia del usuario en la base de datos
psql -U postgres -h localhost -d postgres -c "SELECT * FROM pg_roles WHERE rolname='auditlog_admin';"

# Generar la base de datos (como usuario postgres para tener permisos de tablespace)
psql -U postgres -h localhost -d postgres -f create_database.sql

# Aplicar migraciones en orden
psql -U auditlog_admin -h localhost -d auditlog_db_example -f migrations/V1__create_ecommerce_schema.sql
psql -U auditlog_admin -h localhost -d auditlog_db_example -f migrations/V2__create_audit_log_table.sql
psql -U auditlog_admin -h localhost -d auditlog_db_example -f migrations/V3__create_audit_trigger_function.sql
psql -U auditlog_admin -h localhost -d auditlog_db_example -f migrations/V4__apply_triggers_to_tables.sql

# Aplicar extensiones en orden
psql -U auditlog_admin -h localhost -d auditlog_db_example -f extensions/V5__create_audit_history_view.sql
psql -U auditlog_admin -h localhost -d auditlog_db_example -f extensions/V6__create_get_record_at_function.sql

# Poblar datos de prueba
psql -U auditlog_admin -h localhost -d auditlog_db_example -f seeds/seed_ecommerce_data.sql

# Ejecutar script de verificacion de configuracion de la base de datos
bash test/verify_setup.sh

# Ejecutar script de prueba de operaciones de auditoria
psql -U auditlog_admin -h localhost -d auditlog_db_example -f queries/test_audit_operations.sql

# Ejecutar script de consultas de ejemplo para auditoria
psql -U auditlog_admin -h localhost -d auditlog_db_example -f queries/example_audit_queries.sql

# Eliminar base de datos
psql -U postgres -h localhost -d postgres -f drop_database.sql

# Eliminar usuario de la base de datos
psql -U postgres -h localhost -d postgres -c "DROP USER IF EXISTS auditlog_admin;"