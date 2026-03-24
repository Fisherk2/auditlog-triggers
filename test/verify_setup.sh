#!/bin/bash

# 🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮙🮘🮙🮙🮘🮙🮙🮘🮙🮙🮘🮙🮙🮘🮙🮙🮘🮙🮙🮘🮙🮙🮘🮙🮙🮘🮙🮙🮘🮙🮙🮘🮙🮙🮘🮙🮙🮘🮙🮙🮘🮙🮙🮘🮙🮙🮘🮙🮙🮘🮙
# Database Setup Verification Script
# Purpose: Validación completa de configuración de base de datos
# Author: fisherk2
# Version: 1.0
# Date: 2026-03-20
# Requirements: PostgreSQL 15+, psql client, .env file con parámetros de conexión
# 🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮙🮘🮙🮙🮘🮙🮙🮘🮙🮙🮘🮙🮙🮘🮙🮙🮘🮙🮙🮘🮙🮙🮘🮙🮙🮘🮙🮙🮘🮙🮙🮘🮙🮙🮘🮙🮙🮘🮙🮙🮘🮙🮙🮘🮙🮙🮘🮙🮙🮘🮙

# ■■■■■■■■■■■■■ Configuración de colores para salida legible ■■■■■■■■■■■■■ 
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ■■■■■■■■■■■■■ Variables globales para tracking de validaciones ■■■■■■■■■■■■■ 
VALIDATION_ERRORS=0
TOTAL_TESTS=0

# ■■■■■■■■■■■■■ Función para imprimir mensajes con formato ■■■■■■■■■■■■■ 
print_message() {
    local color=$1
    local symbol=$2
    local message=$3
    echo -e "${color}${symbol} ${message}${NC}"
}

# ■■■■■■■■■■■■■ Función para validar conexión a PostgreSQL ■■■■■■■■■■■■■
# Por qué es crítica: Sin conexión, no se puede validar nada más
validate_connection() {
    print_message $BLUE "🔍" "Validando conexión a PostgreSQL..."
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    # Intentar conexión básica sin mostrar credenciales
    if PGPASSWORD="${POSTGRES_PASSWORD:-}" psql -h "${POSTGRES_HOST:-localhost}" -p "${POSTGRES_PORT:-5432}" -U "${POSTGRES_USER:-postgres}" -d postgres -c "SELECT 1;" >/dev/null 2>&1; then
        print_message $GREEN "✅" "Conexión a PostgreSQL exitosa"
        return 0
    else
        print_message $RED "❌" "Error: No se puede conectar a PostgreSQL"
        print_message $YELLOW "💡" "Verifica que PostgreSQL esté corriendo y las credenciales en config/database.env"
        VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
        return 1
    fi
}

# ■■■■■■■■■■■■■ Función para validar que la base de datos existe ■■■■■■■■■■■■■ 
# Por qué es crítica: Sin BD, no hay tablas ni datos que validar
validate_database() {
    print_message $BLUE "🔍" "Validando existencia de la base de datos..."
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    local db_name="${POSTGRES_DB:-auditlog_db_example}"
    
    # Verificar si la BD existe
    if PGPASSWORD="${POSTGRES_PASSWORD:-}" psql -h "${POSTGRES_HOST:-localhost}" -p "${POSTGRES_PORT:-5432}" -U "${POSTGRES_USER:-postgres}" -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='$db_name';" | grep -q 1; then
        print_message $GREEN "✅" "Base de datos '$db_name' existe"
        return 0
    else
        print_message $RED "❌" "Error: Base de datos '$db_name' no existe"
        print_message $YELLOW "💡" "Ejecuta: psql -f create_database.sql"
        VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
        return 1
    fi
}



# ■■■■■■■■■■■■■ Función para validar que las tablas del dominio existen ■■■■■■■■■■■■■ 
# Por qué es crítica: Sin tablas de dominio, no hay nada que auditar
validate_domain_tables() {
    print_message $BLUE "🔍" "Validando tablas de dominio (customers, products, orders)..."
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    local db_name="${POSTGRES_DB:-auditlog_db_example}"
    local tables=("customers" "products" "orders")
    local missing_tables=()
    
    for table in "${tables[@]}"; do
        if PGPASSWORD="${POSTGRES_PASSWORD:-}" psql -h "${POSTGRES_HOST:-localhost}" -p "${POSTGRES_PORT:-5432}" -U "${POSTGRES_USER:-postgres}" -d "$db_name" -tAc "SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='$table';" | grep -q 1; then
            print_message $GREEN "✅" "Tabla '$table' existe"
        else
            print_message $RED "❌" "Tabla '$table' NO existe"
            missing_tables+=("$table")
        fi
    done
    
    if [ ${#missing_tables[@]} -eq 0 ]; then
        return 0
    else
        print_message $YELLOW "💡" "Ejecuta: psql -d $db_name -f migrations/V1__create_ecommerce_schema.sql"
        VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
        return 1
    fi
}

# ■■■■■■■■■■■■■ Función para validar que la tabla audit_log existe ■■■■■■■■■■■■■ 
# Por qué es crítica: Sin audit_log, no se puede registrar auditoría
validate_audit_log_table() {
    print_message $BLUE "🔍" "Validando tabla audit_log..."
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    local db_name="${POSTGRES_DB:-auditlog_db_example}"
    
    if PGPASSWORD="${POSTGRES_PASSWORD:-}" psql -h "${POSTGRES_HOST:-localhost}" -p "${POSTGRES_PORT:-5432}" -U "${POSTGRES_USER:-postgres}" -d "$db_name" -tAc "SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='audit_log';" | grep -q 1; then
        print_message $GREEN "✅" "Tabla audit_log existe"
        
        # Validar estructura básica
        local columns=("id" "table_name" "record_id" "operation" "old_data" "new_data" "changed_by" "changed_at")
        for col in "${columns[@]}"; do
            if PGPASSWORD="${POSTGRES_PASSWORD:-}" psql -h "${POSTGRES_HOST:-localhost}" -p "${POSTGRES_PORT:-5432}" -U "${POSTGRES_USER:-postgres}" -d "$db_name" -tAc "SELECT 1 FROM information_schema.columns WHERE table_name='audit_log' AND column_name='$col';" | grep -q 1; then
                print_message $GREEN "✅" "Columna audit_log.$col existe"
            else
                print_message $RED "❌" "Columna audit_log.$col NO existe"
                VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
            fi
        done
        return 0
    else
        print_message $RED "❌" "Tabla audit_log NO existe"
        print_message $YELLOW "💡" "Ejecuta: psql -d $db_name -f migrations/V2__create_audit_log_table.sql"
        VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
        return 1
    fi
}

# ■■■■■■■■■■■■■ Función para validar que los triggers existen ■■■■■■■■■■■■■ 
# Por qué es crítica: Sin triggers, no se genera auditoría automáticamente
validate_triggers() {
    print_message $BLUE "🔍" "Validando triggers de auditoría..."
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    local db_name="${POSTGRES_DB:-auditlog_db_example}"
    local tables=("customers" "products" "orders")
    local missing_triggers=()
    
    for table in "${tables[@]}"; do
        if PGPASSWORD="${POSTGRES_PASSWORD:-}" psql -h "${POSTGRES_HOST:-localhost}" -p "${POSTGRES_PORT:-5432}" -U "${POSTGRES_USER:-postgres}" -d "$db_name" -tAc "SELECT 1 FROM pg_trigger WHERE tgname='${table}_audit_trigger';" | grep -q 1; then
            print_message $GREEN "✅" "Trigger para tabla '$table' existe"
        else
            print_message $RED "❌" "Trigger para tabla '$table' NO existe"
            missing_triggers+=("$table")
        fi
    done
    
    if [ ${#missing_triggers[@]} -eq 0 ]; then
        return 0
    else
        print_message $YELLOW "💡" "Ejecuta: psql -d $db_name -f migrations/V4__apply_triggers_to_tables.sql"
        VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
        return 1
    fi
}

# ■■■■■■■■■■■■■ Función para validar que la función audit_trigger_func existe ■■■■■■■■■■■■■ 
# Por qué es crítica: Sin la función, los triggers no funcionan
validate_audit_function() {
    print_message $BLUE "🔍" "Validando función audit_trigger_func..."
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    local db_name="${POSTGRES_DB:-auditlog_db_example}"
    
    if PGPASSWORD="${POSTGRES_PASSWORD:-}" psql -h "${POSTGRES_HOST:-localhost}" -p "${POSTGRES_PORT:-5432}" -U "${POSTGRES_USER:-postgres}" -d "$db_name" -tAc "SELECT 1 FROM pg_proc WHERE proname='audit_trigger_func';" | grep -q 1; then
        print_message $GREEN "✅" "Función audit_trigger_func existe"
        return 0
    else
        print_message $RED "❌" "Función audit_trigger_func NO existe"
        print_message $YELLOW "💡" "Ejecuta: psql -d $db_name -f migrations/V3__create_audit_trigger_function.sql"
        VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
        return 1
    fi
}

# ■■■■■■■■■■■■■ Función para validar que las extensiones existen ■■■■■■■■■■■■■ 
# Por qué es crítica: Extensiones proporcionan funcionalidades avanzadas
validate_extensions() {
    print_message $BLUE "🔍" "Validando extensiones (vista audit_history, función get_record_at)..."
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    local db_name="${POSTGRES_DB:-auditlog_db_example}"
    
    # Validar vista audit_history
    if PGPASSWORD="${POSTGRES_PASSWORD:-}" psql -h "${POSTGRES_HOST:-localhost}" -p "${POSTGRES_PORT:-5432}" -U "${POSTGRES_USER:-postgres}" -d "$db_name" -tAc "SELECT 1 FROM information_schema.views WHERE table_name='audit_history';" | grep -q 1; then
        print_message $GREEN "✅" "Vista audit_history existe"
    else
        print_message $RED "❌" "Vista audit_history NO existe"
        print_message $YELLOW "💡" "Ejecuta: psql -d $db_name -f extensions/V5__create_audit_history_view.sql"
        VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
    fi
    
    # Validar función get_record_at
    if PGPASSWORD="${POSTGRES_PASSWORD:-}" psql -h "${POSTGRES_HOST:-localhost}" -p "${POSTGRES_PORT:-5432}" -U "${POSTGRES_USER:-postgres}" -d "$db_name" -tAc "SELECT 1 FROM pg_proc WHERE proname='get_record_at';" | grep -q 1; then
        print_message $GREEN "✅" "Función get_record_at existe"
    else
        print_message $RED "❌" "Función get_record_at NO existe"
        print_message $YELLOW "💡" "Ejecuta: psql -d $db_name -f extensions/V6__create_get_record_at_function.sql"
        VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
    fi
}

# ■■■■■■■■■■■■■ Función para validar que hay datos seed en las tablas ■■■■■■■■■■■■■ 
# Por qué es crítica: Sin datos, no se puede probar la auditoría
validate_seed_data() {
    print_message $BLUE "🔍" "Validando datos seed en tablas de dominio..."
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    local db_name="${POSTGRES_DB:-auditlog_db_example}"
    local tables=("customers" "products" "orders")
    local empty_tables=()
    
    for table in "${tables[@]}"; do
        local count=$(PGPASSWORD="${POSTGRES_PASSWORD:-}" psql -h "${POSTGRES_HOST:-localhost}" -p "${POSTGRES_PORT:-5432}" -U "${POSTGRES_USER:-postgres}" -d "$db_name" -tAc "SELECT COUNT(*) FROM $table;")
        if [ "$count" -gt 0 ]; then
            print_message $GREEN "✅" "Tabla '$table' tiene $count registros"
        else
            print_message $RED "❌" "Tabla '$table' está vacía"
            empty_tables+=("$table")
        fi
    done
    
    if [ ${#empty_tables[@]} -eq 0 ]; then
        return 0
    else
        print_message $YELLOW "💡" "Ejecuta: psql -d $db_name -f seeds/seed_ecommerce_data.sql"
        VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
        return 1
    fi
}

# ■■■■■■■■■■■■■ Función para validar configuración de entorno ■■■■■■■■■■■■■ 
# Por qué es crítica: Variables incorrectas causan fallos de conexión
validate_env_config() {
    print_message $BLUE "🔍" "Validando configuración de entorno..."
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    # Validar variables críticas
    local required_vars=("POSTGRES_HOST" "POSTGRES_PORT" "POSTGRES_DB" "POSTGRES_USER" "POSTGRES_PASSWORD")
    local missing_vars=()
    
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            print_message $RED "❌" "Variable $var no está definida"
            missing_vars+=("$var")
        else
            print_message $GREEN "✅" "Variable $var está definida"
        fi
    done
    
    if [ ${#missing_vars[@]} -eq 0 ]; then
        # Validar valores razonables
        if [[ "${POSTGRES_PORT}" =~ ^[0-9]+$ ]] && [ "${POSTGRES_PORT}" -ge 1 ] && [ "${POSTGRES_PORT}" -le 65535 ]; then
            print_message $GREEN "✅" "Puerto PostgreSQL válido: ${POSTGRES_PORT}"
            return 0
        else
            print_message $RED "❌" "Puerto PostgreSQL inválido: ${POSTGRES_PORT}"
            VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
            return 1
        fi
    else
        print_message $YELLOW "💡" "Crea .env desde config/database.env.example"
        VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
        return 1
    fi
}

# ■■■■■■■■■■■■■ Función para cargar variables de entorno desde .env ■■■■■■■■■■■■■ 
# Por qué es crítica: Sin configuración, el script no puede conectarse
load_env_file() {
    print_message $BLUE "🔍" "Cargando configuración desde .env..."
    
    if [ -f "config/database.env" ]; then
        # Cargar variables de entorno (ignorar líneas con # y vacías)
        export $(grep -v '^#' config/database.env | grep -v '^$' | xargs)
        print_message $GREEN "✅" "Archivo config/database.env cargado"
    else
        print_message $YELLOW "⚠️" "Archivo config/database.env no encontrado, usando valores por defecto"
        print_message $YELLOW "💡" "Crea config/database.env desde config/database.env.example"
    fi
}

# ■■■■■■■■■■■■■ Función principal de validación ■■■■■■■■■■■■■ 
main() {
    print_message $BLUE "🚀" "Iniciando validación completa de configuración de base de datos"
    echo ""
    
    # Cargar configuración
    load_env_file
    
    # Validar configuración de entorno
    validate_env_config
    echo ""
    
    # Validar conexión a PostgreSQL
    validate_connection
    echo ""
    
    # Validar existencia de la base de datos
    validate_database
    echo ""
    
    # Validar tablas de dominio
    validate_domain_tables
    echo ""
    
    # Validar tabla audit_log
    validate_audit_log_table
    echo ""
    
    # Validar función de auditoría
    validate_audit_function
    echo ""
    
    # Validar triggers
    validate_triggers
    echo ""
    
    # Validar extensiones
    validate_extensions
    echo ""
    
    # Validar datos seed
    validate_seed_data
    echo ""
    
    # Resumen final
    print_message $BLUE "📊" "Resumen de validación:"
    print_message $BLUE "📊" "Total de pruebas: $TOTAL_TESTS"
    print_message $BLUE "📊" "Errores encontrados: $VALIDATION_ERRORS"
    
    if [ $VALIDATION_ERRORS -eq 0 ]; then
        print_message $GREEN "🎉" "¡Todas las validaciones pasaron exitosamente!"
        print_message $GREEN "🎉" "El sistema de auditoría está listo para usar."
        echo ""
        print_message $BLUE "💡" "Próximos pasos:"
        print_message $BLUE "💡" "1. Ejecuta: psql -d ${POSTGRES_DB:-auditlog_db_example} -f queries/test_audit_operations.sql"
        print_message $BLUE "💡" "2. Revisa: queries/example_audit_queries.sql para ejemplos de uso"
        exit 0
    else
        print_message $RED "❌" "Se encontraron $VALIDATION_ERRORS errores que deben ser corregidos"
        print_message $YELLOW "💡" "Revisa los mensajes de error arriba y ejecuta los comandos sugeridos"
        exit 1
    fi
}

# ■■■■■■■■■■■■■ Ejecutar función principal si el script se ejecuta directamente ■■■■■■■■■■■■■ 
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi