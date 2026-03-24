# Registro de Decisiones Arquitectónicas - AuditLog Triggers con Temporalidad

---
metadata:
  tipo_documento: Architecture Decision Record (ADR)
  dominio: Ingeniería de Datos y Arquitectura de Software
  estado: Activo
  fecha_creacion: 2026-03-23
  fecha_actualizacion: 2026-03-23
  autor: fisherk2
  revisores: fisherk2
  stakeholders: [Desarrolladores, DBAs, Arquitectos, Equipo de Producto]
  version_proyecto: 1.0.0

---

## Introducción

Este documento registra las decisiones arquitectónicas clave tomadas durante el diseño e implementación del sistema de datos del proyecto. Cada decisión está documentada siguiendo el formato estándar ADR (Architecture Decision Record) para asegurar trazabilidad, consistencia y facilitar la toma de decisiones futuras.

**Propósito del documento:**
- Mantener un registro histórico de decisiones arquitectónicas
- Proporcionar contexto a nuevos miembros del equipo
- Facilitar la evaluación de decisiones existentes
- Evitar redescubrimiento de alternativas ya evaluadas

**Cómo usar este documento:**
1. Para nuevas decisiones: Copiar el formato ADR y completar cada sección
2. Para decisiones existentes: Revisar el contexto antes de proponer cambios
3. Para auditorías: Usar como referencia de decisiones pasadas

---

*Este documento sigue el patrón Architecture Decision Record (ADR) para mantener trazabilidad de decisiones arquitectónicas y facilitar transferencia de conocimiento.*
  tags: [adr, arquitectura, datos, decision, documentación]
  version: 1.0
  relacionado_con: 

## Historial de Cambios

| Versión | Fecha | Cambios | Autor | Estado |
|---------|-------|---------|-------|---------|
| 1.0.0 | 2026-03-23 | Creación inicial del documento con 6 ADRs principales | fisherk2 | Activo |

---

## Tabla de Contenido

- [Registro de Decisiones Arquitectónicas - AuditLog Triggers con Temporalidad](#registro-de-decisiones-arquitectónicas---auditlog-triggers-con-temporalidad)
  - [Introducción](#introducción)
  - [Historial de Cambios](#historial-de-cambios)
  - [Tabla de Contenido](#tabla-de-contenido)
  - [ADR-001: Usar Triggers AFTER en lugar de BEFORE para Auditoría](#adr-001-usar-triggers-after-en-lugar-de-before-para-auditoría)
  - [ADR-002: Usar JSONB para old\_data/new\_data en lugar de Columnas Fijas](#adr-002-usar-jsonb-para-old_datanew_data-en-lugar-de-columnas-fijas)
  - [ADR-003: No usar Foreign Keys de audit\_log a Tablas de Dominio](#adr-003-no-usar-foreign-keys-de-audit_log-a-tablas-de-dominio)
  - [ADR-004: Implementar Función Genérica audit\_trigger\_func() en lugar de Triggers Específicos](#adr-004-implementar-función-genérica-audit_trigger_func-en-lugar-de-triggers-específicos)
  - [ADR-005: Usar postgres:15-alpine en docker-compose en lugar de latest o debian](#adr-005-usar-postgres15-alpine-en-docker-compose-en-lugar-de-latest-o-debian)
  - [ADR-006: Mapear Puerto 5433:5432 en lugar de usar Puerto Dinámico](#adr-006-mapear-puerto-54335432-en-lugar-de-usar-puerto-dinámico)
  - [Referencias Bibliográficas](#referencias-bibliográficas)
  - [Proceso de Mantenimiento](#proceso-de-mantenimiento)
  - [Mantenimiento del Documento](#mantenimiento-del-documento)

---

## ADR-001: Usar Triggers AFTER en lugar de BEFORE para Auditoría

**Estado**: Accepted  
**Fecha**: 2026-03-23  
**Contexto**: Al diseñar el sistema de auditoría, surgió la pregunta de cuándo ejecutar los triggers de auditoría en relación con las operaciones de DML. La decisión afecta la integridad de datos, performance y manejo de errores.

**Decisión**: Usar triggers `AFTER INSERT OR UPDATE OR DELETE FOR EACH ROW` en lugar de `BEFORE`.

**Alternativas Consideradas**:
1. **BEFORE Triggers**: Se ejecutan antes de que los datos se escriban en la tabla
2. **AFTER Triggers**: Se ejecutan después de que los datos se confirman en la tabla
3. **INSTEAD OF Triggers**: Reemplazan completamente la operación original

**Consecuencias Positivas**:
- **Integridad Garantizada**: Los datos ya pasaron todas las constraints y validaciones
- **Rollback Seguro**: Si la auditoría falla, los datos originales ya están guardados
- **Performance**: No bloquea la operación original durante la auditoría
- **Simplicidad**: Acceso directo a `OLD` y `NEW` con valores finales validados

**Consecuencias Negativas**:
- **Ligeramente Posterior**: La auditoría ocurre microsegundos después del cambio
- **No puede Prevenir**: No puede bloquear operaciones inválidas (solo las registra)

**Justificación Bibliográfica**: 
- **Clean Architecture Cap. 22**: "The Database Is a Detail" - los triggers son infraestructura que no debe interferir con operaciones de negocio
- **PostgreSQL Documentation**: AFTER triggers son recomendados para auditoría porque garantizan que la transacción principal fue exitosa

**Estado Actual**: Vigente. Reconsiderar si se requiere pre-validación de datos en auditoría.

---

## ADR-002: Usar JSONB para old_data/new_data en lugar de Columnas Fijas

**Estado**: Accepted  
**Fecha**: 2026-03-23  
**Contexto**: Para almacenar estados antes y después de cambios, se evaluó entre usar columnas tipadas fijas vs JSONB flexible. La decisión impacta schema, futuro mantenimiento y capacidad de consulta.

**Decisión**: Usar JSONB para `old_data` y `new_data` en lugar de columnas específicas por tabla.

**Alternativas Consideradas**:
1. **Columnas Fijas**: Crear columnas específicas para cada tabla auditada (ej: old_customer_name, new_customer_name)
2. **JSONB Flexible**: Almacenar el registro completo como JSONB
3. **HSTORE**: Usar tipo HSTORE de PostgreSQL (key-value)
4. **XML**: Almacenar como XML (obsoleto para este caso)

**Consecuencias Positivas**:
- **Universalidad**: Un schema almacena datos de CUALQUIER tabla
- **Flexibilidad Futura**: Agregar columnas a tablas de dominio no requiere cambios en audit_log
- **Consultas Potentes**: JSONB con GIN indexes permite búsquedas eficientes
- **Versionamiento Completo**: Almacena estado completo, no solo campos cambiados

**Consecuencias Negativas**:
- **Storage Overhead**: JSONB ocupa más espacio que columnas tipadas
- **Complejidad de Consulta**: Requiere operadores JSONB (->, ->>, @>)
- **Validación de Tipos**: No hay validación de tipos a nivel de base de datos

**Justificación Bibliográfica**:
- **Clean Architecture Cap. 20**: "Open/Closed Principle" - el sistema está abierto a nuevas tablas sin modificación
- **PostgreSQL JSONB Documentation**: JSONB es recomendado para datos semi-estructurados y esquemas evolutivos

**Estado Actual**: Vigente. Reconsiderar si el overhead de storage se vuelve crítico (>1TB de logs).

---

## ADR-003: No usar Foreign Keys de audit_log a Tablas de Dominio

**Estado**: Accepted  
**Fecha**: 2026-03-23  
**Contexto**: Al diseñar el schema de auditoría, se evaluó si audit_log debía tener foreign keys a las tablas de dominio para mantener integridad referencial.

**Decisión**: No usar foreign keys de audit_log a tablas de dominio. Almacenar `table_name` y `record_id` como campos independientes.

**Alternativas Consideradas**:
1. **Foreign Keys Directas**: FK a cada tabla de dominio (customers_id, products_id, orders_id)
2. **Tabla de Metadatos**: Tabla separada con mapeo de tablas a IDs
3. **Sin Foreign Keys**: Almacenar nombre de tabla y ID como texto/entero

**Consecuencias Positivas**:
- **Independencia del Dominio**: La infraestructura de auditoría no depende del schema de dominio
- **Survivabilidad**: Si se elimina una tabla, los registros de auditoría permanecen
- **Flexibilidad**: Puede auditar cualquier tabla sin modificar constraints
- **Performance**: Evita cascadas de deletes que podrían perder historial

**Consecuencias Negativas**:
- **Sin Integridad Referencial**: No hay validación automática de que los IDs referenciados existan
- **Datos Huerfanos**: Posibles registros de auditoría para tablas eliminadas
- **Validación Manual**: Requiere validación a nivel de aplicación si se necesita integridad

**Justificación Bibliográfica**:
- **Clean Architecture Cap. 22**: "The Database Is a Detail" - la infraestructura de auditoría no debe depender del dominio
- **Systems Analysis Cap. 10**: "Audit trails should survive schema changes" - los logs deben ser independientes del schema

**Estado Actual**: Vigente. Reconsiderar si se requiere integridad referencial estricta.

---

## ADR-004: Implementar Función Genérica audit_trigger_func() en lugar de Triggers Específicos

**Estado**: Accepted  
**Fecha**: 2026-03-23  
**Contexto**: Para implementar auditoría en múltiples tablas, se evaluó entre crear una función por tabla vs una función genérica que sirva para todas.

**Decisión**: Implementar `audit_trigger_func()` genérica usando Strategy Pattern para manejar INSERT/UPDATE/DELETE.

**Alternativas Consideradas**:
1. **Funciones Específicas**: Una función por tabla (audit_customers_func, audit_products_func)
2. **Función Genérica**: Una función que detecta operación y tabla dinámicamente
3. **Procedimientos Almacenados**: Múltiples procedimientos con lógica compartida
4. **Application-Level**: Manejar auditoría en código de aplicación

**Consecuencias Positivas**:
- **DRY Principle**: No repetición de lógica entre tablas
- **Mantenimiento Simplificado**: Cambios en lógica de auditoría requieren modificar solo una función
- **Consistencia**: Todas las tablas usan exactamente la misma lógica
- **Extensibilidad**: Agregar nuevas tablas requiere solo crear trigger, no nueva función

**Consecuencias Negativas**:
- **Complejidad Inicial**: La función genérica es más compleja de implementar
- **Debugging**: Errores pueden afectar múltiples tablas simultáneamente
- **Performance**: Pequeño overhead por detección dinámica de operación

**Justificación Bibliográfica**:
- **Clean Code Cap. 3**: "Functions Should Do One Thing" - la función hace una cosa: auditar
- **Design Patterns**: Strategy Pattern permite diferentes comportamientos (I/U/D) con misma interfaz
- **Clean Architecture Cap. 20**: Open/Closed Principle - abierto a extensión sin modificación

**Estado Actual**: Vigente. Reconsiderar si se requieren reglas de auditoría específicas por tabla.

---

## ADR-005: Usar postgres:15-alpine en docker-compose en lugar de latest o debian

**Estado**: Accepted  
**Fecha**: 2026-03-23  
**Contexto**: Al definir el entorno de desarrollo con Docker, se evaluó qué imagen de PostgreSQL usar considerando tamaño, compatibilidad y reproducibilidad.

**Decisión**: Usar `postgres:15-alpine` específicamente en lugar de `postgres:latest` o `postgres:15`.

**Alternativas Consideradas**:
1. **postgres:latest**: Siempre la versión más reciente
2. **postgres:15**: Versión 15 pero basada en Debian
3. **postgres:15-alpine**: Versión 15 basada en Alpine Linux
4. **Build Propia**: Dockerfile personalizado

**Consecuencias Positivas**:
- **Reproducibilidad Exacta**: La misma imagen se obtiene en cualquier momento
- **Tamaño Reducido**: Alpine (~50MB) vs Debian (~300MB), descargas más rápidas
- **Superficie de Ataque Mínor**: Alpine tiene menos paquetes instalados por defecto
- **Compatibilidad Verificada**: PostgreSQL 15 soporta todas las características usadas

**Consecuencias Negativas**:
- **Actualizaciones Manuales**: Requiere cambio explícito para nuevas versiones
- **Compatibilidad**: Alpine puede tener diferencias menores vs Debian
- **Community Support**: Menos documentación específica para Alpine

**Justificación Bibliográfica**:
- **Docker Best Practices**: "Use specific image tags, not latest" para builds reproducibles
- **Clean Architecture Cap. 22**: "The Database Is a Detail" - la imagen específica es un detalle intercambiable
- **Software Development Cap. 17**: "Reproducible Environments" - versiones específicas garantizan consistencia

**Estado Actual**: Vigente. Reconsiderar al actualizar a PostgreSQL 16+.

---

## ADR-006: Mapear Puerto 5433:5432 en lugar de usar Puerto Dinámico

**Estado**: Accepted  
**Fecha**: 2026-03-23  
**Contexto**: Al configurar Docker Compose, se evaluó entre usar puerto dinámico (random) vs puerto fijo alternativo para evitar conflictos con PostgreSQL nativo del host.

**Decisión**: Mapear puerto fijo 5433:5432 (host:container) en lugar de puerto dinámico.

**Alternativas Consideradas**:
1. **Puerto Dinámico**: Dejar que Docker asigne un puerto aleatorio
2. **Puerto Fijo 5433**: Usar 5433 consistentemente
3. **Configurable**: Variable de entorno para elegir puerto
4. **Sin Mapeo**: Solo acceso a través de red Docker

**Consecuencias Positivas**:
- **Predictibilidad**: Siempre el mismo puerto, facilita configuración
- **Documentación Sencilla**: Un puerto para documentar y recordar
- **Evita Conflictos**: 5433 raramente está ocupado vs 5432 siempre ocupado
- **Flexibilidad**: Variable `DB_HOST_PORT` permite cambiar si 5433 está ocupado

**Consecuencias Negativas**:
- **Posible Conflicto**: 5433 podría estar ocupado en algunas máquinas
- **Hardcoded**: Menos flexible que puerto completamente dinámico

**Justificación Bibliográfica**:
- **Docker Best Practices**: "Use fixed ports for development" para consistencia
- **Clean Architecture Cap. 22**: "The Database Is a Detail" - el puerto es un detalle de infraestructura intercambiable
- **DevOps Principles**: "Predictable environments" facilitan desarrollo y debugging

**Estado Actual**: Vigente. Reconsiderar si hay muchos conflictos reportados.

---

## Referencias Bibliográficas

- **Clean Architecture**: Robert C. Martin, 2017
  - Cap. 15: "What Is Architecture?" - Keeping Options Open
  - Cap. 20: "The Open-Closed Principle" 
  - Cap. 22: "The Database Is a Detail"
  
- **Clean Code**: Robert C. Martin, 2008
  - Cap. 3: "Functions Should Do One Thing"
  - Cap. 4: "Comments Should Explain Why, Not What"
  - Cap. 17: "Smells and Heuristics"
  
- **Software Development**: Ian Sommerville, 2016
  - Cap. 17: "Documentation as Code"
  - Cap. 18: "Reproducible Environments"
  
- **Systems Analysis and Design**: Kendall & Kendall, 8th Ed
  - Cap. 10: "Design Documentation Reduces Maintenance Costs"
  
- **PostgreSQL Documentation**: Official PostgreSQL Documentation
  - Chapter 39: "Triggers"
  - Chapter 8: "Data Types - JSONB"
  - Chapter 33: "Database Administration"

---

## Proceso de Mantenimiento

1. **Revisión Trimestral**: Evaluar si los ADRs siguen vigentes
2. **Nuevos ADRs**: Documentar decisiones arquitectónicas significativas
3. **Deprecación**: Marcar ADRs obsoletos claramente
4. **Referencias Cruzadas**: Mantener enlaces con código implementado
5. **Stakeholder Review**: Revisión por equipo de arquitectura cada cambio

## Mantenimiento del Documento

**Propietario:** fisherk2  
**Frecuencia de revisión:** Trimestral  
**Proceso de cambios:**
1. Proponer nuevo ADR o modificación
2. Revisión por equipo técnico
3. Aprobación por arquitecto principal
4. Actualización del documento

---

> **Nota sobre importancia de ADRs:** Documentar decisiones arquitectónicas evita que el equipo "redescubra" soluciones, proporciona contexto para decisiones futuras, y facilita el onboarding de nuevos miembros. Un ADR bien mantenido es un activo estratégico para el equipo.