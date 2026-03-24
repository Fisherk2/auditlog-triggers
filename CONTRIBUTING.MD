# Guía de Contribución - PostgreSQL Audit Log Triggers

¡Bienvenido/a al proyecto PostgreSQL Audit Log Triggers! 🎉

Agradecemos tu interés en contribuir a este sistema de auditoría. Este documento te guiará paso a paso sobre cómo participar, qué estándares seguir y cómo asegurarnos de que todas las contribuciones mantengan la calidad y arquitectura del proyecto.

---

## 🤝 Tipos de Contribuciones Aceptadas

Aceptamos varios tipos de contribuciones:

- **🐛 Reportes de Bugs**: Problemas, errores o comportamientos inesperados
- **✨ Nuevas Features**: Funcionalidades que mejoren el sistema
- **📚 Documentación**: Mejoras a README, guías, ejemplos
- **🧪 Tests**: Mejoras o nuevos casos de prueba
- **🔧 Optimizaciones**: Mejoras de performance o refactorización
- **🌐 Traducciones**: Documentación en otros idiomas

---

## 🚀 Cómo Contribuir (Paso a Paso)

### 1. Preparación del Entorno

```bash
# 1. Fork del repositorio en GitHub
# 2. Clonar tu fork
git clone https://github.com/Fisherk2/auditlog-triggers
cd auditlog-triggers

# 3. Configurar entorno local
cp config/database.env.example config/database.env
# Editar config/database.env con tus credenciales

# 4. Iniciar PostgreSQL con Docker
docker-compose up -d

# 5. Aplicar migraciones y datos de prueba
psql -h localhost -p 5433 -U audit_admin -d auditlog_db_example -f migrations/V1__create_ecommerce_schema.sql
psql -h localhost -p 5433 -U audit_admin -d auditlog_db_example -f migrations/V2__create_audit_log_table.sql
psql -h localhost -p 5433 -U audit_admin -d auditlog_db_example -f migrations/V3__create_audit_trigger_function.sql
psql -h localhost -p 5433 -U audit_admin -d auditlog_db_example -f migrations/V4__apply_triggers_to_tables.sql
psql -h localhost -p 5433 -U audit_admin -d auditlog_db_example -f extensions/V5__create_audit_history_view.sql
psql -h localhost -p 5433 -U audit_admin -d auditlog_db_example -f extensions/V6__create_get_record_at_function.sql
psql -h localhost -p 5433 -U audit_admin -d auditlog_db_example -f seeds/seed_ecommerce_data.sql
```

### 2. Crear Rama de Feature

```bash
# Sincronizar con upstream
git remote add upstream https://github.com/Fisherk2/auditlog-triggers
git fetch upstream
git checkout main
git merge upstream/main

# Crear rama de feature (usar GitFlow)
git checkout -b feature/nombre-descriptivo
# O para bugs: git checkout -f bugfix/descripcion-del-bug
```

### 3. Hacer Cambios y Commits

```bash
# Hacer tus cambios...
# Añadir archivos
git add .

# Commits descriptivos
git commit -m "feat: agregar trigger de auditoría para tabla categories

- Implementar trigger AFTER INSERT/UPDATE/DELETE
- Agregar tests en test_audit_operations.sql
- Actualizar documentación en EXTENSION_GUIDE.md

Closes #123"
```

### 4. Push y Pull Request

```bash
# Push a tu fork
git push origin feature/nombre-descriptivo

# Abrir Pull Request en GitHub
# Usar plantilla que aparece automáticamente
```

---

## 📋 Estándares de Código

### Convenciones de Nombres

**SQL y PostgreSQL:**
- Tablas: `snake_case` en plural (ej: `customers`, `audit_log`)
- Columnas: `snake_case` en singular (ej: `customer_id`, `created_at`)
- Triggers: `tg_tabla_evento_timing` (ej: `tg_customers_audit_after`)
- Funciones: `snake_case` descriptivas (ej: `audit_trigger_func`)
- Índices: `idx_tabla_columna(s)` (ej: `idx_audit_log_table_name`)

**Archivos y Directorios:**
- Migraciones: `V#__descripcion.sql` (ej: `V1__create_ecommerce_schema.sql`)
- Documentación: `kebab-case.md` (ej: `extension-guide.md`)
- Scripts: `snake_case.sql` (ej: `test_audit_operations.sql`)

### Estándares de Comentarios

**Clean Code Cap. 4: "Comments should explain why, not what"**

```sql
-- ✅ BIEN: Explica por qué, no qué
-- Usar AFTER triggers para garantizar que los datos ya pasaron todas las constraints
-- antes de registrar en audit_log, evitando inconsistencias si la transacción falla
CREATE TRIGGER tg_customers_audit
AFTER INSERT OR UPDATE OR DELETE ON customers
FOR EACH ROW
EXECUTE FUNCTION audit_trigger_func();

-- ❌ MAL: Solo repite lo que el código dice
-- Crear trigger para auditar customers
CREATE TRIGGER tg_customers_audit
AFTER INSERT OR UPDATE OR DELETE ON customers
FOR EACH ROW
EXECUTE FUNCTION audit_trigger_func();
```

### Migraciones Idempotentes

**Todas las migraciones deben ser re-ejecutables sin error:**

```sql
-- ✅ BIEN: Usar IF NOT EXISTS
CREATE TABLE IF NOT EXISTS audit_log (
    -- ...
);

-- ✅ BIEN: Verificar antes de crear trigger
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'tg_customers_audit'
    ) THEN
        CREATE TRIGGER tg_customers_audit
        AFTER INSERT OR UPDATE OR DELETE ON customers
        FOR EACH ROW
        EXECUTE FUNCTION audit_trigger_func();
    END IF;
END $$;
```

### Formato de Código SQL

```sql
-- Palabras clave en mayúsculas
SELECT 
    customer_id,
    customer_name,
    created_at
FROM customers
WHERE customer_id = 1
ORDER BY created_at DESC;

-- Indentación consistente (4 espacios)
-- Comentarios alineados
CREATE OR REPLACE FUNCTION audit_trigger_func()
RETURNS TRIGGER AS $$
BEGIN
    -- Determinar tipo de operación
    IF TG_OP = 'INSERT' THEN
        -- Insertar registro de auditoría
        INSERT INTO audit_log (
            table_name,
            record_id,
            operation,
            old_data,
            new_data,
            changed_by,
            changed_at
        ) VALUES (
            TG_TABLE_NAME,
            NEW.id,
            'I',
            NULL,
            row_to_json(NEW),
            current_user,
            now()
        );
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

## 🔍 Proceso de Pull Request

### Checklist Antes de Crear PR

- [ ] **Tests pasan**: `psql -f queries/test_audit_operations.sql` muestra todos PASSED
- [ ] **Código sigue estándares**: Revisar sección de estándares arriba
- [ ] **Documentación actualizada**: README, guías, comentarios actualizados
- [ ] **Migraciones idempotentes**: Se pueden ejecutar múltiples veces sin error
- [ ] **Commits descriptivos**: Mensajes claros siguiendo conventional commits
- [ ] **Rama actualizada**: Sincronizada con main upstream

### Descripción Requerida en PR

```markdown
## Descripción
Breve descripción de los cambios implementados.

## Tipo de Cambio
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation
- [ ] Performance improvement
- [ ] Refactoring

## Testing
- [ ] Tests existentes pasan
- [ ] Nuevos tests agregados
- [ ] Manual testing realizado

## Checklist
- [ ] Código sigue estándares del proyecto
- [ ] Self-review del código completado
- [ ] Documentation actualizada
- [ ] Sin conflictos de merge

## Issues Relacionados
Closes #123
```

### Criterios de Aceptación

- **Mínimo 1 reviewer**: Otro desarrollador debe aprobar
- **Tests 100% pasando**: Todos los tests deben mostrar PASSED
- **Sin conflictos**: Merge limpio sin conflictos
- **Documentación completa**: Cambios documentados apropiadamente
- **Performance aceptable**: No regresiones de performance significativas

---

## 🐛 Reporte de Bugs

### Plantilla para Reportar Bugs

```markdown
**Descripción del Bug**
Breve descripción del problema encontrado.

**Pasos para Reproducir**
1. Ejecutar `psql -f migrations/V1__create_ecommerce_schema.sql`
2. Ejecutar `INSERT INTO customers (...) VALUES (...)`
3. Ejecutar `SELECT * FROM audit_history`
4. Observar error: ...

**Comportamiento Esperado**
Describir qué debería pasar.

**Comportamiento Actual**
Describir qué está pasando realmente.

**Información del Ambiente**
- PostgreSQL: 15.2
- Docker: 24.0.0
- Sistema Operativo: Ubuntu 22.04
- Versión del proyecto: 1.0.0

**Output de Error (si aplica)**
```
ERROR: function audit_trigger_func() does not exist
CONTEXT: SQL statement "SELECT audit_trigger_func()"
```

**Archivos Adjuntos**
- Logs relevantes
- Screenshots
- Archivos de configuración (sin credenciales)

**Impacto**
- [ ] Crítico: Sistema no usable
- [ ] Alto: Funcionalidad principal afectada
- [ ] Medio: Funcionalidad secundaria afectada
- [ ] Bajo: Issue cosmético
```

---

## ✨ Solicitudes de Features

### Plantilla para Proponer Features

```markdown
**Título de la Feature**
Título descriptivo y claro de la funcionalidad propuesta.

**Caso de Uso**
Describir el problema o necesidad que esta feature resolvería.

**Descripción Propuesta**
Explicación detallada de la funcionalidad propuesta.

**Beneficios Esperados**
- Mejora en usabilidad
- Reducción de tiempo de desarrollo
- Mejora en performance
- Otro: ...

**Impacto en Archivos Existentes**
- [ ] No requiere cambios
- [ ] Cambios menores (configuración)
- [ ] Cambios moderados (nuevas funciones)
- [ ] Cambios mayores (arquitectura)

**Implementación Sugerida**
Ideas iniciales sobre cómo implementar esta feature.

**Alternativas Consideradas**
Otras formas de resolver el mismo problema.

**Riesgos y Consideraciones**
Posibles problemas o complicaciones.

**Métricas de Éxito**
Cómo mediremos que esta feature fue exitosa.
```

---

## 📜 Código de Conducta

### Comportamiento Esperado

- **Respeto**: Tratar a todos con respeto y consideración
- **Inclusión**: Fomentar un ambiente inclusivo y diverso
- **Colaboración**: Trabajar juntos hacia objetivos comunes
- **Constructividad**: Feedback constructivo y orientado a mejorar
- **Paciencia**: Ser paciente con contribuidores de todos los niveles

### Lineamientos de Comunicación

- **Issues y PRs**: Mantener comunicación profesional y enfocada
- **Code Reviews**: Feedback específico, accionable y respetuoso
- **Discusiones**: Debates basados en méritos técnicos, no personales
- **Documentación**: Lenguaje inclusivo y accesible

### Reporte de Problemas

Si experimentas o observas comportamiento inapropiado:
1. Contacta a los mantenedores del proyecto
2. Envía email a: dev@fisherk2.com
3. Usa canales oficiales de comunicación

---

## 🏆 Reconocimiento de Contribuciones

### Tipos de Contribuidores

- **💻 Code Contributors**: Contribuciones de código
- **📖 Documentation Contributors**: Mejoras a documentación
- **🐛 Bug Hunters**: Reporte y resolución de bugs
- **🎨 Design Contributors**: Mejoras visuales o UX
- **🌍 Translation Contributors**: Traducciones

### Agradecimiento

- Todos los contribuidores son reconocidos en el README
- PRs significativos son destacados en release notes
- Contribuidores frecuentes pueden ser invitados como maintainers

---

## 📚 Recursos Adicionales

### Documentación del Proyecto

- **[README.md](README.md)**: Guía principal de uso
- **[ADR.md](ADR.md)**: Decisiones arquitectónicas
- **[docs/EXTENSION_GUIDE.md](docs/EXTENSION_GUIDE.md)**: Cómo extender el sistema
- **[naming_conventions.md](naming_conventions.md)**: Convenciones detalladas

### Herramientas Recomendadas

- **IDE**: VSCode con extensiones PostgreSQL
- **Cliente SQL**: DBeaver, pgAdmin, o psql
- **Git**: GitHub Desktop o línea de comandos
- **Docker**: Docker Desktop para desarrollo local

### Aprendizaje

- **PostgreSQL Documentation**: https://www.postgresql.org/docs/
- **Git Flow**: https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow

---

## 🤝 Preguntas Frecuentes

### ¿Cómo empiezo si soy nuevo en PostgreSQL?

1. Lee la [documentación de PostgreSQL](https://www.postgresql.org/docs/current/tutorial.html)
2. Revisa los [ejemplos en queries/](queries/)
3. Ejecuta los tests para entender el sistema
4. Empieza con contribuciones a documentación

### ¿Puedo contribuir si no sé Docker?

Sí, puedes:
- Contribuir a documentación
- Reportar bugs
- Proponer features
- Revisar código

### ¿Cómo sé qué issues están disponibles?

- Revisa labels: `good first issue`, `help wanted`
- Filtra por issues sin asignar
- Pregunta en discussions qué necesita ayuda

---

## 📞 Contacto

- **Issues**: GitHub Issues para bugs y features
- **Discussions**: GitHub Discussions para preguntas generales
- **Email**: dev@fisherk2.com para asuntos privados

---

*Gracias por tu interés en contribuir a PostgreSQL Audit Log Triggers! 🚀*

---