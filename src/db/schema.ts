import { sql } from 'drizzle-orm';
import {
  pgSchema,
  uuid,
  text,
  integer,
  serial,
  boolean,
  date,
  timestamp,
  numeric,
  index,
  uniqueIndex,
  primaryKey,
  check,
} from 'drizzle-orm/pg-core';

export const appSchema = pgSchema('woolfandfox');

export const rolSistemaEnum = appSchema.enum('rol_sistema_enum', ['admin', 'administrativo']);
export const tipoOperacionEnum = appSchema.enum('tipo_operacion_enum', ['Entrega', 'Recogida']);

export const roles = appSchema.table(
  'roles',
  {
    id: serial('id').primaryKey(),
    nombre_rol: text('nombre_rol').notNull(),
  },
  (t) => [
    uniqueIndex('roles_nombre_rol_uk').on(t.nombre_rol),
    check('roles_nombre_rol_chk', sql`${t.nombre_rol} in ('Conductor', 'Ayudante', 'Andarín')`),
  ],
);

export const vehiculos = appSchema.table(
  'vehiculos',
  {
    id: uuid('id').defaultRandom().primaryKey(),
    matricula: text('matricula').notNull(),
  },
  (t) => [
    uniqueIndex('vehiculos_matricula_uk').on(t.matricula),
    check('vehiculos_matricula_chk', sql`btrim(${t.matricula}) <> ''`),
  ],
);

export const usuarios = appSchema.table(
  'usuarios',
  {
    id: uuid('id').defaultRandom().primaryKey(),
    username: text('username').notNull(),
    password_hash: text('password_hash').notNull(),
    nombre: text('nombre').notNull(),
    rol_sistema: rolSistemaEnum('rol_sistema').notNull(),
    activo: boolean('activo').notNull().default(true),
    creado_en: timestamp('creado_en', { withTimezone: true }).notNull().defaultNow(),
  },
  (t) => [
    uniqueIndex('usuarios_username_uk').on(t.username),
    check('usuarios_username_chk', sql`btrim(${t.username}) <> ''`),
    check('usuarios_nombre_chk', sql`btrim(${t.nombre}) <> ''`),
  ],
);

export const personal = appSchema.table(
  'personal',
  {
    id: uuid('id').defaultRandom().primaryKey(),
    nombre: text('nombre').notNull(),
    rol_id: integer('rol_id')
      .notNull()
      .references(() => roles.id, { onUpdate: 'cascade', onDelete: 'restrict' }),
  },
  (t) => [
    index('idx_personal_rol_id').on(t.rol_id),
    check('personal_nombre_chk', sql`btrim(${t.nombre}) <> ''`),
  ],
);

export const rutas = appSchema.table(
  'rutas',
  {
    id: uuid('id').defaultRandom().primaryKey(),
    codigo_ruta: text('codigo_ruta').notNull(),
    fecha: date('fecha').notNull(),
    vehiculo_id: uuid('vehiculo_id')
      .notNull()
      .references(() => vehiculos.id, { onUpdate: 'cascade', onDelete: 'restrict' }),
    reembolso_total: numeric('reembolso_total', { precision: 12, scale: 2 }).notNull().default('0'),
    comentarios_percances: text('comentarios_percances'),
    confirmado_por: uuid('confirmado_por')
      .notNull()
      .references(() => usuarios.id, { onUpdate: 'cascade', onDelete: 'restrict' }),
    foto_cierre_url: text('foto_cierre_url').notNull(),
    hora_cierre: timestamp('hora_cierre', { withTimezone: true }).notNull(),
  },
  (t) => [
    uniqueIndex('rutas_codigo_fecha_uk').on(t.codigo_ruta, t.fecha),
    index('idx_rutas_vehiculo_id').on(t.vehiculo_id),
    index('idx_rutas_confirmado_por').on(t.confirmado_por),
    index('idx_rutas_fecha').on(t.fecha.desc()),
    check('rutas_codigo_chk', sql`btrim(${t.codigo_ruta}) <> ''`),
    check('rutas_reembolso_chk', sql`${t.reembolso_total} >= 0`),
    check('rutas_foto_url_chk', sql`btrim(${t.foto_cierre_url}) <> ''`),
  ],
);

export const asignacionPersonal = appSchema.table(
  'asignacion_personal',
  {
    ruta_id: uuid('ruta_id')
      .notNull()
      .references(() => rutas.id, { onUpdate: 'cascade', onDelete: 'cascade' }),
    personal_id: uuid('personal_id')
      .notNull()
      .references(() => personal.id, { onUpdate: 'cascade', onDelete: 'restrict' }),
  },
  (t) => [
    primaryKey({ columns: [t.ruta_id, t.personal_id] }),
    index('idx_asignacion_personal_personal_id').on(t.personal_id),
  ],
);

export const operacionesDiarias = appSchema.table(
  'operaciones_diarias',
  {
    id: uuid('id').defaultRandom().primaryKey(),
    ruta_id: uuid('ruta_id')
      .notNull()
      .references(() => rutas.id, { onUpdate: 'cascade', onDelete: 'cascade' }),
    tipo_operacion: tipoOperacionEnum('tipo_operacion').notNull(),
    exitosas: integer('exitosas').notNull(),
    incidencias: integer('incidencias').notNull(),
    total: integer('total').notNull(),
  },
  (t) => [
    uniqueIndex('operaciones_diarias_ruta_tipo_uk').on(t.ruta_id, t.tipo_operacion),
    index('idx_operaciones_diarias_ruta_id').on(t.ruta_id),
    index('idx_operaciones_diarias_tipo').on(t.tipo_operacion),
    check('operaciones_diarias_exitosas_chk', sql`${t.exitosas} >= 0`),
    check('operaciones_diarias_incidencias_chk', sql`${t.incidencias} >= 0`),
    check('operaciones_diarias_total_chk', sql`${t.total} >= 0`),
    check('operaciones_diarias_total_consistency_chk', sql`${t.total} = ${t.exitosas} + ${t.incidencias}`),
  ],
);
