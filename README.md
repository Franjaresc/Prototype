# Panel de Control Logístico — Especificaciones del Proyecto
 
Este repositorio contiene el frontend/backend del Panel de Control Logístico (Next.js, App Router) para la gestión, seguimiento y auditoría de cierres diarios de rutas de reparto.
 
> **IMPORTANT: FEATURE FREEZE** — No se deben proponer ni implementar funcionalidades fuera de las indicadas en este documento.
 
---
 
## Resumen del propósito
 
Aplicación interna para que el personal administrativo registre cierres diarios de rutas (entregas y recogidas), cargue evidencia fotográfica, registre reembolsos e incidencias, y visualice métricas y detalles por ruta.
 
---
 
## Stack tecnológico (definitivo y cerrado)
 
| Capa | Tecnología | Notas |
|---|---|---|
| Framework | Next.js (App Router) | TypeScript strict |
| Base de datos | PostgreSQL — **Neon** | Serverless, branching, scale-to-zero |
| ORM | **Drizzle ORM** + drizzle-kit | Driver: `postgres.js` |
| Almacenamiento de archivos | **Cloudflare R2** | S3-compatible, sin egress fees |
| Autenticación | **Auth.js v5** (Credentials) | username + bcrypt, sin email |
| Validación | **Zod** | Server Actions y formularios |
| Estilos | Tailwind CSS | — |
| Visualización de datos | Recharts o Tremor | Se elige al implementar el dashboard |
 
### Decisiones arquitectónicas registradas
 
- **Drizzle sobre Prisma**: menor footprint en serverless, tipado estructural nativo en TypeScript strict, sin paso `prisma generate` en el pipeline de deploy, SQL legible y depurable.
- **Neon sobre Supabase (BD)**: mejor arquitectura serverless PostgreSQL, separación real de compute/storage, branching instantáneo para desarrollo, precio inferior tras adquisición por Databricks (2025).
- **Cloudflare R2 sobre Supabase Storage**: Neon no incluye file storage propio; R2 ofrece 10 GB/mes gratuitos y cero costes de egress. Compatible con la misma interfaz S3 que cualquier SDK estándar.
- **Auth.js v5 sobre Supabase Auth**: Supabase Auth está diseñado alrededor del email, que no aplica a este sistema. Auth.js con Credentials Provider permite login por `username` + `password` sin email, con control total del flujo en el servidor.

---
 
## Usuarios del sistema
 
El sistema es de uso exclusivo por personal administrativo interno. No hay registro público ni acceso externo.
 
### Usuarios fijos del sistema
 
| Username | Rol de sistema |
|---|---|
| `yesica` | Administrativo |
| `alejandra` | Administrativo |
| `demily` | Administrativo |
| `admin` | Administrador |
 
- Las cuentas se crean manualmente por el administrador (no hay registro self-service).
- El login es por `username` + `password` (sin email).
- Las contraseñas se almacenan hasheadas con **bcrypt**.
- La sesión se gestiona mediante Auth.js v5 (JWT).
- El campo `confirmado_por` en cada cierre de ruta se toma **automáticamente de la sesión activa** — no es un campo editable por el usuario. Esto garantiza trazabilidad real y elimina la posibilidad de suplantar a otro usuario.

---
 
## Casos de uso
 
### 1. Ingreso de Datos — Cierre de Ruta
 
- Registrar número de paquetes: `exitosas`, `incidencias` y `total` para **Entrega** y **Recogida**.
- Vincular a `codigo_ruta` (ej. `U0065`).
- Asignar personal a la ruta con su rol operativo (`Conductor`, `Ayudante`, `Andarín`).
- Asociar matrícula del vehículo.
- Registrar `hora_cierre` (`timestamptz`), `comentarios_percances` (nullable) y `reembolso_total`.
- `confirmado_por` se asigna automáticamente desde la sesión del usuario autenticado.
- Subir evidencia fotográfica obligatoria del cierre de ruta.

### 2. Visualización — Dashboard
 
- Tablas y gráficos mostrando entregas y recogidas exitosas, fallidas y totales por ruta.
- Vista de detalle por cierre de ruta incluyendo URL pública de la foto y comentarios.

---
 
## Diseño de base de datos (normalizado, estricto)

### Convención de esquema PostgreSQL

- Esquema oficial del proyecto: `woolfandfox`
- Base de datos: `woolfandfox`
- Esta convención se usará en Drizzle, en la URL de conexión y en el entorno Docker local.
 
### Tabla `usuarios`
| Campo | Tipo | Notas |
|---|---|---|
| `id` | UUID (PK) | — |
| `username` | String (UNIQUE) | Login identifier |
| `password_hash` | String | bcrypt |
| `nombre` | String | Nombre visible en UI |
| `rol_sistema` | Enum: `admin`, `administrativo` | Control de acceso a la app |
| `activo` | Boolean | Permite desactivar sin borrar |
| `creado_en` | timestamptz | — |
 
### Tabla `roles`
| Campo | Tipo | Notas |
|---|---|---|
| `id` | Int (PK) | — |
| `nombre_rol` | String | `Conductor`, `Ayudante`, `Andarín` |
 
> Nota: estos roles son **operativos** (quién trabaja en la ruta), distintos del `rol_sistema` de la tabla `usuarios`.
 
### Tabla `personal`
| Campo | Tipo | Notas |
|---|---|---|
| `id` | UUID (PK) | — |
| `nombre` | String | — |
| `rol_id` | FK → `roles.id` | — |
 
### Tabla `vehiculos`
| Campo | Tipo | Notas |
|---|---|---|
| `id` | UUID (PK) | — |
| `matricula` | String (UNIQUE) | — |
 
### Tabla `rutas`
| Campo | Tipo | Notas |
|---|---|---|
| `id` | UUID (PK) | — |
| `codigo_ruta` | String | ej. `U0065` |
| `fecha` | Date | — |
| `vehiculo_id` | FK → `vehiculos.id` | — |
| `reembolso_total` | Decimal | — |
| `comentarios_percances` | Text (nullable) | — |
| `confirmado_por` | FK → `usuarios.id` | Tomado de sesión, nunca editable |
| `foto_cierre_url` | String | URL pública de R2 |
| `hora_cierre` | timestamptz | — |
 
### Tabla pivote `asignacion_personal`
| Campo | Tipo | Notas |
|---|---|---|
| `ruta_id` | FK → `rutas.id` | — |
| `personal_id` | FK → `personal.id` | — |
 
> PK compuesta: (`ruta_id`, `personal_id`)
 
### Tabla `operaciones_diarias`
| Campo | Tipo | Notas |
|---|---|---|
| `id` | UUID (PK) | — |
| `ruta_id` | FK → `rutas.id` | — |
| `tipo_operacion` | Enum: `Entrega`, `Recogida` | — |
| `exitosas` | Int | — |
| `incidencias` | Int | — |
| `total` | Int | — |

### Documentación detallada de la base de datos

#### Objetivo del modelo

La base de datos está diseñada para registrar cierres diarios de rutas de reparto con trazabilidad completa, control de usuarios internos, asignación de personal operativo y desglose de operaciones por tipo.

#### Convención general

- Esquema único del proyecto: `woolfandfox`
- Motor: PostgreSQL
- Tipo de tiempo: `timestamptz` para todos los campos de auditoría temporal
- Identificadores: UUID en entidades principales y `serial` solo en `roles.id`

#### Relaciones principales

- `personal.rol_id` → `roles.id`
- `rutas.vehiculo_id` → `vehiculos.id`
- `rutas.confirmado_por` → `usuarios.id`
- `asignacion_personal.ruta_id` → `rutas.id`
- `asignacion_personal.personal_id` → `personal.id`
- `operaciones_diarias.ruta_id` → `rutas.id`

#### Reglas de integridad

- `usuarios.username` es único y no puede quedar vacío.
- `vehiculos.matricula` es único y no puede quedar vacío.
- `rutas.codigo_ruta + rutas.fecha` es único para evitar doble cierre el mismo día.
- `operaciones_diarias.ruta_id + tipo_operacion` es único para evitar duplicados por ruta y tipo.
- `operaciones_diarias.total` debe ser igual a `exitosas + incidencias`.
- Los importes monetarios no pueden ser negativos.
- `confirmado_por` debe venir de una cuenta válida del sistema.

#### Índices relevantes

- `idx_rutas_fecha` para listados recientes del dashboard.
- `idx_rutas_confirmado_por` para auditoría por usuario.
- `idx_rutas_vehiculo_id` para búsquedas por vehículo.
- `idx_operaciones_diarias_ruta_id` y `idx_operaciones_diarias_tipo` para agregaciones rápidas.
- `idx_personal_rol_id` para filtros por rol operativo.

#### Seed base

El sistema parte con los roles operativos precargados:
- Conductor
- Ayudante
- Andarín

#### Notas operativas

- El script SQL base (`schema.sql`) y el schema Drizzle (`drizzle/schema.ts`) deben permanecer siempre alineados.
- Cualquier cambio estructural debe reflejarse en migraciones con drizzle-kit y actualizarse en este documento.
- La tabla `usuarios` se usa para autenticación por Auth.js v5 con Credentials Provider.

#### Seed inicial recomendado

El seed inicial debe parecerse a un entorno real de producción, pero con datos seguros y controlados. No debe incluir información sensible real del cliente si no ha sido aprobada explícitamente.

Se recomienda pedir al cliente:

- Lista de usuarios iniciales con nombre visible y `username` final.
- Contraseñas temporales o la política para generarlas.
- Confirmación de los roles operativos que deben existir desde el inicio.
- Matrículas de vehículos de prueba o reales autorizadas para precarga.
- Códigos de ruta de ejemplo que deban existir en la base inicial.
- Cualquier criterio de nomenclatura interna que deba respetarse.

Si no entregan datos reales, el seed debe usar datos sintéticos pero verosímiles:

- Usuarios administrativos con nombres del equipo.
- Vehículos con matrículas ficticias válidas en formato realista.
- Rutas de ejemplo tipo `U0065`, `U0066`.
- Datos de operaciones coherentes con cierres reales, sin reflejar información sensible.

Objetivo del seed:

- Permitir probar login, dashboard, relaciones y filtros desde el primer día.
- Simular producción sin comprometer privacidad ni seguridad.
- Dejar la base lista para demo, QA y validación funcional.
 
---
 
## Reglas de arquitectura y convenciones
 
### Almacenamiento de fotos (Cloudflare R2)
- Bucket: `cierres-ruta` (público).
- Nomenclatura de archivo al subir: `{codigo_ruta}_{fecha}_{timestamp}.{ext}`.
- Solo se almacena en base de datos la **URL pública resultante** y metadata mínima.
- La subida ocurre en un **Server Action** de Next.js — nunca desde el cliente directamente.

### Timezones
- Todos los registros de tiempo usan `timestamptz` (TIMESTAMP WITH TIME ZONE).
- No se usan timestamps locales en ningún punto del sistema.

### Seguridad
- Todas las entradas se validan y sanitizan en Server Actions (nunca confiar en el cliente).
- `confirmado_por` se extrae de la sesión en el servidor; el cliente no puede enviarlo ni modificarlo.
- Las rutas de la aplicación están protegidas por middleware de Auth.js — sin sesión válida, redirección al login.
- La creación y desactivación de usuarios es exclusiva del rol `admin`.

### Validación
- Se usará **Zod** para la validación de esquemas en Server Actions y formularios.
- Los enums de base de datos (`tipo_operacion`, `rol_sistema`) se definen en Drizzle y se reutilizan como tipos TypeScript en toda la app — no se duplican manualmente.

---
 
## Flujo de autenticación
 
```
1. Usuario accede a cualquier ruta
2. Middleware verifica sesión (Auth.js)
3. Sin sesión → redirect a /login
4. /login: formulario username + password
5. Server Action valida contra tabla `usuarios` (bcrypt.compare)
6. Auth.js crea sesión JWT con { id, username, nombre, rol_sistema }
7. Sesión disponible en Server Components y Server Actions via auth()
```
 
---
 
## Roadmap de implementación
 
1. **Configurar proyecto**: Next.js + TypeScript strict + Tailwind + Drizzle + Neon. ✅
2. **Schema SQL**: definición oficial del esquema PostgreSQL (`schema.sql`). ✅
3. **Schema Drizzle**: espejo exacto del SQL en `drizzle/schema.ts` + `drizzle/db.ts` + `drizzle.config.ts`. ✅
4. **Seed inicial**: crear los 4 usuarios del sistema con contraseñas hasheadas.
5. **Auth**: configurar Auth.js v5 con Credentials Provider.
6. **Middleware**: proteger todas las rutas excepto `/login`.
7. **Server Actions — Storage**: subida de fotos a Cloudflare R2.
8. **Server Actions — BD**: escritura de cierres de ruta con validación Zod.
9. **UI — Formulario de cierre**: con validaciones estrictas.
10. **UI — Dashboard**: métricas, tablas y detalle de cierre.

---
 
## Notas operativas
 
- Implementación estrictamente dentro del alcance (feature freeze).
- No se implementarán funcionalidades no descritas en este documento sin revisión explícita del propietario del proyecto.
- Todas las decisiones de stack quedan cerradas salvo justificación técnica documentada.

---

## Entorno Docker local

Para desarrollo local se añadió un stack Docker separado del entorno productivo. El objetivo es levantar la aplicación y la base de datos sin depender de servicios externos.

### Archivos incluidos

- `docker-compose.yml`: orquesta la app Next.js y PostgreSQL local.
- `Dockerfile.dev`: imagen de desarrollo con hot reload.
- `Dockerfile`: imagen de producción para despliegue.
- `.env`: variables de entorno reales para tu máquina local.
- `.env.example`: plantilla de referencia para nuevos entornos.

### Servicios del stack

- `db`: PostgreSQL 16 en contenedor, inicializado con `schema.sql` del proyecto.
- `app`: Next.js en modo desarrollo, enlazado al volumen del proyecto para hot reload.

> El contenedor PostgreSQL local incluye `pgcrypto` y `uuid-ossp` por compatibilidad con la imagen oficial de Docker. En Neon estas extensiones son nativas y no se instalan explícitamente.

### Variables de entorno mínimas

Antes de arrancar el stack, el archivo `.env` debe contener:

```
POSTGRES_USER=
POSTGRES_PASSWORD=
POSTGRES_DB=
POSTGRES_PORT=
DATABASE_URL=
NEXTAUTH_URL=
NEXTAUTH_SECRET=
```

### Scripts disponibles

Los siguientes scripts están definidos en `package.json` bajo la clave `scripts`:

```bash
pnpm docker:up      # Arranca todos los servicios del stack
pnpm docker:down    # Detiene el stack
pnpm docker:logs    # Muestra logs en tiempo real
pnpm docker:clean   # Elimina contenedores y volúmenes locales
```

### Acceso local

- Aplicación: `http://localhost:3000`
- PostgreSQL: `localhost:5432`

### Notas operativas

- El contenedor de la app usa `pnpm dev` internamente para facilitar el desarrollo con hot reload.
- La base de datos se inicializa automáticamente con el esquema oficial del proyecto al primer arranque.
- No usar este entorno para datos reales de producción.
- Si se modifican variables de entorno, reiniciar el stack para que tomen efecto.