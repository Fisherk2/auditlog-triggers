#!/bin/bash

# 🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘
# SCRIPT DE AUTOMATIZACIÓN DE TESTS - AUDIT LOG TRIGGERS
# 🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘
# Propósito: Ejecutar ciclo completo de pruebas con cleanup automático
# Author: fisherk2
# Version: 3.0 - Versión CI/CD con fail-fast y cleanup garantizado
# Date: 2026-03-25
# 
# Principios Aplicados:
# - Fail-Fast (Clean Code Cap. 19): Detenerse al primer error
# - Automated Testing (Software Development Cap. 18): Tests reproducibles
# - Resource Cleanup (DevOps Best Practices): Limpieza automática INCONDICIONAL
# 🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘🮙🮘🮙🮙🮘

# Modo estricto para fail-fast (Clean Code Cap. 19)
set -euo pipefail

# ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
# CONFIGURACIÓN INICIAL
# ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■

# Colores para output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Variables de entorno
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
readonly CONTAINER_NAME="audit-log-db-example"
readonly COMPOSE_FILE="$PROJECT_DIR/docker-compose.yml"
readonly CONFIG_FILE="$PROJECT_DIR/config/database.env"

# Contadores para estadísticas
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_WARNINGS=0

# Tiempo de inicio
readonly START_TIME=$(date +%s)

# ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
# FUNCIONES DE LOGGING
# ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■

# Función de timestamp
timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# Funciones de logging con colores y timestamps (corregidas para set -euo pipefail)
log_info() {
    echo -e "${BLUE}[$(timestamp)] INFO:${NC} $1"
}

log_success() {
    echo -e "${GREEN}[$(timestamp)] SUCCESS:${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[$(timestamp)] WARNING:${NC} $1"
    # Incremento seguro con manejo de errores
    TESTS_WARNINGS=$((TESTS_WARNINGS + 1)) || true
}

log_error() {
    echo -e "${RED}[$(timestamp)] ERROR:${NC} $1"
}

log_test() {
    echo -e "${BLUE}[$(timestamp)] TEST:${NC} $1"
    # Incremento seguro con manejo de errores
    TESTS_TOTAL=$((TESTS_TOTAL + 1)) || true
}

# ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
# FUNCIÓN DE CLEANUP - CRÍTICA (DevOps Best Practices)
# ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
# Esta función se ejecuta SIEMPRE gracias a trap cleanup EXIT
# No hay forma de omitirla, incluso con Ctrl+C o errores

cleanup() {
    log_info "🧹 Iniciando cleanup del entorno..."
    
    # Determinar el tipo de limpieza basado en el resultado de los tests
    local cleanup_type="full"  # Por defecto: limpieza completa
    
    # Verificar si los tests pasaron exitosamente (usar TESTS_FAILED)
    if [[ ${TESTS_FAILED:-0} -eq 0 && ${TESTS_PASSED:-0} -gt 0 ]]; then
        cleanup_type="success"  # Tests exitosos: limpieza completa
        log_info "🎉 Tests exitosos detectados - aplicando limpieza completa..."
    elif [[ ${TESTS_FAILED:-0} -gt 0 ]]; then
        cleanup_type="failed"  # Tests fallaron: limpieza parcial
        log_info "⚠️ Tests fallaron detectados - aplicando limpieza parcial..."
    else
        cleanup_type="partial"  # Ejecución incompleta: limpieza parcial
        log_info "ℹ️ Ejecución incompleta - aplicando limpieza parcial..."
    fi
    
    # Detener y eliminar contenedores y volúmenes
    if docker-compose -f "$COMPOSE_FILE" ps -q | grep -q .; then
        log_info "🛑 Deteniendo contenedores activos..."
        docker-compose -f "$COMPOSE_FILE" down -v
        log_success "✅ Contenedores y volúmenes eliminados"
    else
        log_info "ℹ️ No hay contenedores activos para eliminar"
        # Asegurar eliminación de contenedores incluso si no están activos
        log_info "🧹 Eliminando contenedores residuales..."
        docker-compose -f "$COMPOSE_FILE" down -v 2>/dev/null || true
        log_success "✅ Contenedores residuales eliminados"
    fi
    
    # Limpieza condicional de imágenes según el tipo
    case "$cleanup_type" in
        "success")
            # Tests exitosos: eliminar imagen completamente para liberar espacio
            log_info "🗑️ Eliminando imagen completamente (tests exitosos)..."
            if docker images -q "postgres:15-alpine" | grep -q .; then
                docker rmi postgres:15-alpine 2>/dev/null || true
                log_success "✅ Imagen PostgreSQL eliminada (espacio liberado)"
            fi
            
            # Eliminar imágenes huérfanas
            log_info "🧹 Limpiando imágenes huérfanas..."
            if docker images -f "dangling=true" -q | grep -q .; then
                docker rmi $(docker images -f "dangling=true" -q) 2>/dev/null || true
                log_success "✅ Imágenes huérfanas eliminadas"
            else
                log_info "ℹ️ No hay imágenes huérfanas para eliminar"
            fi
            ;;
            
        "failed")
            # Tests fallaron: eliminar solo caché para reconstrucción rápida
            log_info "🔄 Eliminando caché de imagen (tests fallaron)..."
            if docker images -q "postgres:15-alpine" | grep -q .; then
                # Forzar reconstrucción sin descargar nuevamente
                docker builder prune -f 2>/dev/null || true
                log_success "✅ Caché de Docker eliminado (reconstrucción rápida)"
            fi
            ;;
            
        "partial")
            # Ejecución incompleta: limpieza básica
            log_info "🧹 Aplicando limpieza básica (ejecución parcial)..."
            # Solo limpiar contenedores y volúmenes, mantener imagen
            ;;
    esac
    
    log_success "✅ Cleanup completado ($cleanup_type)"
}

# ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
# CONFIGURACIÓN DE TRAP - GARANTIZA LIMPIEZA INCONDICIONAL
# ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
# trap cleanup EXIT se ejecuta:
# - Al final normal del script
# - Con exit 1, 2, etc.
# - Con Ctrl+C (SIGINT)
# - Con kill (SIGTERM)
# - Con cualquier error no manejado

trap cleanup EXIT

# ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
# FUNCIONES DE VERIFICACIÓN
# ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■

# Verificar prerequisitos
check_prerequisites() {
    log_info "🔍 Verificando prerequisitos..."
    
    # Verificar Docker
    if ! command -v docker &> /dev/null; then
        log_error "❌ Docker no está instalado"
        exit 2
    fi
    
    # Verificar Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        log_error "❌ Docker Compose no está instalado"
        exit 2
    fi
    
    # Verificar archivo de configuración
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log_error "❌ Archivo de configuración no encontrado: $CONFIG_FILE"
        log_info "💡 Copia config/database.env.example a config/database.env"
        exit 2
    fi
    
    # Verificar psql
    if ! command -v psql &> /dev/null; then
        log_error "❌ psql no está instalado"
        exit 2
    fi
    
    log_success "✅ Prerequisitos verificados"
}

# Cargar configuración
load_config() {
    log_info "📋 Cargando configuración desde $CONFIG_FILE"
    
    # Verificar que el archivo existe
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log_error "❌ Archivo de configuración no encontrado: $CONFIG_FILE"
        log_info "💡 Copia config/database.env.example a config/database.env"
        exit 2
    fi
    
    # Cargar variables de entorno con manejo de errores
    if ! bash -n "$CONFIG_FILE" 2>/dev/null; then
        log_error "❌ Error de sintaxis en archivo de configuración: $CONFIG_FILE"
        exit 2
    fi
    
    set -a
    if ! source "$CONFIG_FILE" 2>/dev/null; then
        log_error "❌ Error al cargar archivo de configuración: $CONFIG_FILE"
        exit 2
    fi
    set +a
    
    # Validar variables críticas con valores por defecto
    POSTGRES_HOST="${POSTGRES_HOST:-localhost}"
    POSTGRES_PORT="${POSTGRES_PORT:-5432}"
    POSTGRES_DB="${POSTGRES_DB:-auditlog_db_example}"
    POSTGRES_USER="${POSTGRES_USER:-auditlog_admin}"
    POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-pimpumpapas}"
    
    # Validar variables críticas con valores por defecto
    local required_vars=("POSTGRES_HOST" "POSTGRES_PORT" "POSTGRES_DB" "POSTGRES_USER" "POSTGRES_PASSWORD")
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            log_error "❌ Variable requerida no configurada: $var"
            exit 2
        fi
    done
    
    log_success "✅ Configuración cargada"
    log_info "📋 Conectando a: ${POSTGRES_USER}@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}"
}

# ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
# FUNCIÓN DE ESPERA Y HEALTH CHECK
# ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■

wait_for_postgres() {
    log_info "⏳ Esperando a que PostgreSQL inicie..."
    
    echo "🔍 DEBUG: Variables en wait_for_postgres:"
    echo "   CONTAINER_NAME = $CONTAINER_NAME"
    echo "   POSTGRES_USER = $POSTGRES_USER"
    echo "   POSTGRES_DB = $POSTGRES_DB"
    
    # Verificar que el contenedor existe y está corriendo
    echo "🔍 DEBUG: Verificando contenedor..."
    if ! docker ps --format "table {{.Names}}" | grep -q "$CONTAINER_NAME"; then
        echo "❌ ERROR: Contenedor $CONTAINER_NAME no encontrado o no corriendo"
        echo "🔍 DEBUG: Contenedores activos:"
        docker ps --format "table {{.Names}}\t{{.Status}}"
        exit 1
    fi
    echo "✅ Contenedor $CONTAINER_NAME encontrado y corriendo"
    
    # Probar pg_isready directamente
    echo "🔍 DEBUG: Probando pg_isready..."
    if docker exec "$CONTAINER_NAME" pg_isready --help &>/dev/null; then
        echo "✅ pg_isready disponible en el contenedor"
    else
        echo "❌ ERROR: pg_isready no disponible en el contenedor"
        echo "🔍 DEBUG: Probando conexión alternativa..."
        # Alternativa: intentar conexión directa
        if docker exec "$CONTAINER_NAME" psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "SELECT 1;" &>/dev/null; then
            echo "✅ Conexión directa funciona"
            log_success "✅ PostgreSQL está listo (verificación directa)"
            return 0
        else
            echo "❌ ERROR: Ni pg_isready ni conexión directa funcionan"
            exit 1
        fi
    fi
    
    local timeout=60
    local count=0
    
    echo "🔍 DEBUG: Iniciando bucle de espera..."
    while [[ $count -lt $timeout ]]; do
        echo -n "🔍 DEBUG: Intento $((count + 1))/$timeout - "
        if docker exec "$CONTAINER_NAME" pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB" 2>&1; then
            echo "✅ PostgreSQL está listo"
            log_success "✅ PostgreSQL está listo"
            return 0
        else
            echo "PostgreSQL no listo aún"
        fi
        
        echo -n "."
        sleep 1
        count=$((count + 1))
    done
    
    echo
    log_error "❌ Timeout esperando a PostgreSQL"
    exit 1
}

# ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
# PASO 1: CREAR CONTENEDOR
# ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■

create_container() {
    log_test "🐳 Creando contenedor Docker..."
    
    # Verificar variables críticas
    log_info "📋 COMPOSE_FILE = $COMPOSE_FILE"
    log_info "📋 Directorio actual = $(pwd)"
    
    # Verificar que el archivo docker-compose.yml existe
    if [[ ! -f "$COMPOSE_FILE" ]]; then
        log_error "❌ Archivo docker-compose.yml no encontrado: $COMPOSE_FILE"
        exit 1
    fi
    
    # Verificar que Docker está disponible
    if ! command -v docker &> /dev/null; then
        log_error "❌ Docker no está disponible"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        log_error "❌ Docker Compose no está disponible"
        exit 1
    fi
    
    # Reconstruir imagen y crear contenedor con captura de errores
    log_info "🔨 Reconstruyendo imagen PostgreSQL (sin caché)..."
    if docker-compose -f "$COMPOSE_FILE" build --no-cache 2>&1; then
        log_success "✅ Imagen reconstruida exitosamente"
    else
        log_error "❌ Error al reconstruir imagen"
        log_info "📋 Verificando logs de construcción..."
        docker-compose -f "$COMPOSE_FILE" build --no-cache 2>&1
        exit 1
    fi
    
    log_info "🐳 Creando contenedor Docker..."
    if docker-compose -f "$COMPOSE_FILE" up -d 2>&1; then
        log_success "✅ Contenedor creado exitosamente"
        # Incremento seguro
        TESTS_PASSED=$((TESTS_PASSED + 1)) || true
        
        # Verificar que el contenedor está corriendo
        if docker-compose -f "$COMPOSE_FILE" ps | grep -q "Up"; then
            log_success "✅ Contenedor está corriendo"
        else
            log_error "❌ Contenedor no está corriendo después de creación"
            docker-compose -f "$COMPOSE_FILE" ps
            exit 1
        fi
    else
        log_error "❌ Error al crear contenedor"
        log_info "📋 Verificando logs de Docker Compose..."
        docker-compose -f "$COMPOSE_FILE" logs --tail=20
        exit 1
    fi
    
    # Esperar a que PostgreSQL inicie
    wait_for_postgres
}

# ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
# PASO 2: VERIFICAR CONEXIÓN
# ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■

verify_connection() {
    log_test "🔌 Verificando conexión a PostgreSQL..."
    
    echo "🔍 DEBUG: Variables de conexión:"
    echo "   POSTGRES_HOST = $POSTGRES_HOST"
    echo "   POSTGRES_PORT = $POSTGRES_PORT"
    echo "   POSTGRES_USER = $POSTGRES_USER"
    echo "   POSTGRES_DB = $POSTGRES_DB"
    echo "   POSTGRES_PASSWORD = [OCULTA]"
    
    # Verificar que el contenedor está corriendo
    echo "🔍 DEBUG: Verificando estado del contenedor..."
    if docker ps --format "table {{.Names}}\t{{.Status}}" | grep -q "$CONTAINER_NAME"; then
        echo "✅ Contenedor está corriendo"
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep "$CONTAINER_NAME"
    else
        echo "❌ Contenedor no está corriendo"
        exit 1
    fi
    
    # Verificar que el puerto está mapeado
    echo "🔍 DEBUG: Verificando mapeo de puertos..."
    local port_mapping
    port_mapping=$(docker port "$CONTAINER_NAME" 5432 2>/dev/null || echo "NO_MAPEADO")
    echo "   Port mapping 5432: $port_mapping"
    
    # Intentar conexión con detalles
    echo "🔍 DEBUG: Intentando conexión psql..."
    echo "   Comando: PGPASSWORD=\"*****\" psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -d $POSTGRES_DB -c \"SELECT 1;\""
    
    # Probar conexión con output visible para debugging
    if PGPASSWORD="$POSTGRES_PASSWORD" psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "SELECT 1;" 2>&1; then
        echo "✅ Comando psql ejecutado exitosamente"
        log_success "✅ Conexión exitosa a PostgreSQL"
        TESTS_PASSED=$((TESTS_PASSED + 1)) || true
    else
        echo "❌ ERROR: Comando psql falló"
        echo "🔍 DEBUG: Probando conexión alternativa con docker exec..."
        
        # Alternativa: probar conexión desde dentro del contenedor
        if docker exec "$CONTAINER_NAME" psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "SELECT 1;" &>/dev/null; then
            echo "✅ Conexión desde dentro del contenedor funciona"
            echo "❌ ERROR: El problema es la conexión desde el host (posible problema de puerto o red)"
        else
            echo "❌ ERROR: Ni siquiera funciona desde dentro del contenedor"
        fi
        
        log_error "❌ Error de conexión a PostgreSQL"
        exit 1
    fi
}

# ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
# PASO 3: APLICAR MIGRACIONES
# ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■

apply_migrations() {
    log_info "📦 Aplicando migraciones..."
    
    # Migraciones principales (V1__ a V4__)
    local migrations=(
        "migrations/V1__create_ecommerce_schema.sql"
        "migrations/V2__create_audit_log_table.sql"
        "migrations/V3__create_audit_trigger_function.sql"
        "migrations/V4__apply_triggers_to_tables.sql"
    )
    
    for migration in "${migrations[@]}"; do
        log_test "📝 Aplicando migración: $migration"
        
        if PGPASSWORD="$POSTGRES_PASSWORD" psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f "$PROJECT_DIR/$migration"; then
            log_success "✅ Migración aplicada: $migration"
            ((TESTS_PASSED++))
        else
            log_error "❌ Error en migración: $migration"
            exit 1
        fi
    done
    
    # Extensiones (V5__ y V6__)
    local extensions=(
        "extensions/V5__create_audit_history_view.sql"
        "extensions/V6__create_get_record_at_function.sql"
    )
    
    for extension in "${extensions[@]}"; do
        log_test "🔧 Aplicando extensión: $extension"
        
        if PGPASSWORD="$POSTGRES_PASSWORD" psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f "$PROJECT_DIR/$extension"; then
            log_success "✅ Extensión aplicada: $extension"
            ((TESTS_PASSED++))
        else
            log_error "❌ Error en extensión: $extension"
            exit 1
        fi
    done
    
    # Seed de datos de prueba
    log_test "🌱 Cargando datos de prueba (seed)..."
    if PGPASSWORD="$POSTGRES_PASSWORD" psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f "$PROJECT_DIR/seeds/seed_ecommerce_data.sql"; then
        log_success "✅ Datos de prueba cargados"
        ((TESTS_PASSED++))
    else
        log_error "❌ Error al cargar datos de prueba"
        exit 1
    fi
}

# ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
# PASO 4: VERIFICAR SETUP DE BD
# ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■

verify_setup() {
    log_test "🔍 Verificando configuración completa de la base de datos..."
    
    if bash "$SCRIPT_DIR/verify_setup.sh"; then
        log_success "✅ Verificación de setup completada"
        ((TESTS_PASSED++))
    else
        log_error "❌ Error en verificación de setup"
        exit 1
    fi
}

# ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
# PASO 5: EJECUTAR TESTS DE AUDITORÍA
# ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■

run_audit_tests() {
    #echo "🔍 DEBUG: INICIO DE run_audit_tests"
    log_test "🧪 Ejecutando tests de auditoría..."
    
    # Ejecutar tests y capturar resultados
    local test_file="$PROJECT_DIR/queries/test_audit_operations.sql"
    local test_output
    local exit_code=0
    
    #echo "🔍 DEBUG: Verificando archivo de tests..."
    # Verificar que el archivo existe
    if [[ ! -f "$test_file" ]]; then
        #echo "❌ ERROR: Archivo de tests no encontrado: $test_file"
        exit 1
    fi
    #echo "✅ Archivo de tests encontrado: $test_file"
    
    #echo "🔍 DEBUG: Ejecutando tests (con output visible)..."
    # Ejecutar tests sin filtrar para ver qué está pasando
    if PGPASSWORD="$POSTGRES_PASSWORD" psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f "$test_file" >/dev/null 2>&1; then
        #echo "🔍 DEBUG: psql (silencioso) ejecutado exitosamente"
        exit_code=0
    else
        #echo "🔍 DEBUG: psql (silencioso) falló"
        exit_code=1
    fi
    
    #echo "🔍 DEBUG: Capturando output completo..."
    # Capturar output completo para análisis
    test_output=$(PGPASSWORD="$POSTGRES_PASSWORD" psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f "$test_file" 2>&1)
    
    #echo "🔍 DEBUG: Output capturado, longitud: $(echo "$test_output" | wc -l) líneas"
    #echo "🔍 DEBUG: Primeras 5 líneas del output:"
    #echo "$test_output" | head -5
    #echo "🔍 DEBUG: Últimas 5 líneas del output:"
    #echo "$test_output" | tail -5
    
    #echo "🔍 DEBUG: Analizando resultados..."
    # Analizar resultados
    local pass_count
    local fail_count
    
    #echo "🔍 DEBUG: Buscando PASS en output..."
    pass_count_raw=$(echo "$test_output" | grep -c "PASS" || echo "0")
    pass_count=$(echo "$pass_count_raw" | tr -d '\n\r' | xargs)
    #echo "🔍 DEBUG: pass_count = '$pass_count'"
    
    #echo "🔍 DEBUG: Buscando FAIL en output..."
    fail_count_raw=$(echo "$test_output" | grep -c "FAIL" || echo "0")
    fail_count=$(echo "$fail_count_raw" | tr -d '\n\r' | xargs)
    #echo "🔍 DEBUG: fail_count = '$fail_count'"
    
    echo "🔍 DEBUG: Evaluando condición: exit_code=$exit_code, fail_count=$fail_count"
    if [[ $exit_code -eq 0 && $fail_count -eq 0 ]]; then
        echo "🔍 DEBUG: Condición cumplida - tests pasaron"
        log_success "✅ Tests de auditoría: $pass_count PASARON, $fail_count FALLARON"
        
        # Mostrar resumen de los tests (sin filtrar agresivo)
        echo
        echo "📋 Resumen de Tests de Auditoría:"
        echo "$test_output" | grep -E "(✅|PASSED|PASS)" | head -10
        echo
        echo "🔍 Para ver los registros de auditoría:"
        echo "   SELECT * FROM audit_history ORDER BY changed_at DESC LIMIT 10;"
        
        TESTS_PASSED=$((TESTS_PASSED + 1)) || true
        echo "🔍 DEBUG: TESTS_PASSED incrementado"
    else
        echo "🔍 DEBUG: Condición fallida - tests fallaron"
        log_error "❌ Tests de auditoría fallaron: $pass_count PASARON, $fail_count FALLARON"
        
        # Mostrar resumen de los errores
        echo
        echo "📋 Errores encontrados:"
        echo "$test_output" | grep -E "(❌|FAILED|FAIL)" | head -5
        echo
        echo "🔍 Para depurar, revisa los registros de auditoría:"
        echo "   SELECT * FROM audit_history ORDER BY changed_at DESC LIMIT 10;"
        
        TESTS_FAILED=$((TESTS_FAILED + 1)) || true
        echo "🔍 DEBUG: TESTS_FAILED incrementado, saliendo con exit 1"
        exit 1
    fi
    
    #echo "🔍 DEBUG: FIN DE run_audit_tests"
}

# ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
# PASO 6: EJECUTAR EJEMPLOS DE CONSULTAS
# ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■

run_example_queries() {
    log_test "📋 Ejecutando ejemplos de consultas..."
    
    # Ejecutar ejemplos y capturar output
    local query_output
    query_output=$(PGPASSWORD="$POSTGRES_PASSWORD" psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f "$PROJECT_DIR/queries/example_audit_queries.sql" 2>&1)
    local exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        log_success "✅ Ejemplos de consultas ejecutados correctamente"
        ((TESTS_PASSED++))
    else
        log_warning "⚠️ Ejemplos de consultas con advertencias"
        echo "$query_output" | tail -10
        # No es bloqueante, solo warning
    fi
}

# ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
# PASO 7: RESUMEN FINAL
# ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■

show_summary() {
    local end_time=$(date +%s)
    local duration=$((end_time - START_TIME))
    
    echo
    echo "============================================================================"
    log_info "📊 RESUMEN FINAL DE TESTS"
    echo "============================================================================"
    log_info "⏱️ Tiempo total de ejecución: ${duration}s"
    log_info "📈 Total de tests ejecutados: $TESTS_TOTAL"
    log_success "✅ Tests pasados: $TESTS_PASSED"
    
    if [[ $TESTS_FAILED -gt 0 ]]; then
        log_error "❌ Tests fallidos: $TESTS_FAILED"
    fi
    
    if [[ $TESTS_WARNINGS -gt 0 ]]; then
        log_warning "⚠️ Advertencias: $TESTS_WARNINGS"
    fi
    
    echo "============================================================================"
    
    # Exit code basado en resultados
    if [[ $TESTS_FAILED -eq 0 ]]; then
        log_success "🎉 TODOS LOS TESTS PASARON - SISTEMA FUNCIONAL"
        exit 0
    else
        log_error "💥 HAY TESTS FALLIDOS - REVISAR EL SISTEMA"
        exit 1
    fi
}

# ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
# FUNCIÓN PRINCIPAL - ORQUESTACIÓN
# ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■

main() {
    echo "============================================================================"
    log_info "🚀 INICIANDO CICLO COMPLETO DE TESTS - AUDIT LOG TRIGGERS"
    echo "============================================================================"
    
    # Ejecutar pasos en orden
    check_prerequisites
    load_config
    create_container
    verify_connection
    apply_migrations
    verify_setup
    run_audit_tests
    run_example_queries
    show_summary
}

# ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
# EJECUCIÓN
# ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■

# Ejecutar función principal
log_info "🚀 Iniciando ejecución principal..."
main "$@"
