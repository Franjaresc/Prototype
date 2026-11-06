# Inicialización de PostgreSQL local

Este directorio contiene los scripts de arranque e inicialización para el contenedor PostgreSQL local.

## Archivos

- `00-enable-extensions.sql`: habilita `pgcrypto`, `uuid-ossp` y crea el esquema base.
- `01-migration-idempotent.sql`: crea el esquema, enums, tablas, constraints, índices y roles base de forma segura.
- `02-schema.sql`: esquema oficial canónico del proyecto.
- `03-seed.sql`: inserta roles y usuarios iniciales para desarrollo local.

## Cómo aplicar la migración idempotente en un entorno nuevo

Si quieres preparar una base de datos nueva desde cero, ejecuta el script idempotente dentro del contenedor de PostgreSQL:

```bash
docker exec -i woolfandfox-postgres psql -U woolfandfox -d woolfandfox -f /docker-entrypoint-initdb.d/01-migration-idempotent.sql
```

## Flujo recomendado

1. Levanta el stack local.
2. Aplica `01-migration-idempotent.sql` si la base aún no está preparada.
3. Ejecuta `03-seed.sql` para insertar los usuarios y roles iniciales.
4. Verifica que el esquema `woolfandfox` exista y que los índices principales estén creados.

## Notas

- El script idempotente puede ejecutarse varias veces sin romper el estado de la base.
- Si el contenedor usa el volumen persistente existente, pueden aparecer mensajes de tipo `NOTICE` indicando que algunos objetos ya existen; es normal.
- Para datos reales de producción, no uses estos seed de desarrollo.
