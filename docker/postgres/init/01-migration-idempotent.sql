-- Idempotent migration derived from drizzle/0001_dusty_patriot.sql
-- Safe to run multiple times in a database that may already contain objects.

-- Create schema
CREATE SCHEMA IF NOT EXISTS woolfandfox;

-- Create enums
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type t JOIN pg_namespace n ON n.oid = t.typnamespace WHERE t.typname = 'rol_sistema_enum' AND n.nspname = 'woolfandfox') THEN
        CREATE TYPE woolfandfox.rol_sistema_enum AS ENUM('admin', 'administrativo');
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type t JOIN pg_namespace n ON n.oid = t.typnamespace WHERE t.typname = 'tipo_operacion_enum' AND n.nspname = 'woolfandfox') THEN
        CREATE TYPE woolfandfox.tipo_operacion_enum AS ENUM('Entrega', 'Recogida');
    END IF;
END $$;

-- Tables (IF NOT EXISTS)
CREATE TABLE IF NOT EXISTS woolfandfox.asignacion_personal (
    ruta_id uuid NOT NULL,
    personal_id uuid NOT NULL,
    CONSTRAINT asignacion_personal_ruta_id_personal_id_pk PRIMARY KEY(ruta_id, personal_id)
);

CREATE TABLE IF NOT EXISTS woolfandfox.operaciones_diarias (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
    ruta_id uuid NOT NULL,
    tipo_operacion woolfandfox.tipo_operacion_enum NOT NULL,
    exitosas integer NOT NULL,
    incidencias integer NOT NULL,
    total integer NOT NULL,
    CONSTRAINT operaciones_diarias_exitosas_chk CHECK (exitosas >= 0),
    CONSTRAINT operaciones_diarias_incidencias_chk CHECK (incidencias >= 0),
    CONSTRAINT operaciones_diarias_total_chk CHECK (total >= 0),
    CONSTRAINT operaciones_diarias_total_consistency_chk CHECK (total = exitosas + incidencias)
);

CREATE TABLE IF NOT EXISTS woolfandfox.personal (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
    nombre text NOT NULL,
    rol_id integer NOT NULL,
    CONSTRAINT personal_nombre_chk CHECK (btrim(nombre) <> '')
);

CREATE TABLE IF NOT EXISTS woolfandfox.roles (
    id serial PRIMARY KEY NOT NULL,
    nombre_rol text NOT NULL,
    CONSTRAINT roles_nombre_rol_chk CHECK (nombre_rol in ('Conductor', 'Ayudante', 'Andarín'))
);

CREATE TABLE IF NOT EXISTS woolfandfox.rutas (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
    codigo_ruta text NOT NULL,
    fecha date NOT NULL,
    vehiculo_id uuid NOT NULL,
    reembolso_total numeric(12, 2) DEFAULT '0' NOT NULL,
    comentarios_percances text,
    confirmado_por uuid NOT NULL,
    foto_cierre_url text NOT NULL,
    hora_cierre timestamp with time zone NOT NULL,
    CONSTRAINT rutas_codigo_chk CHECK (btrim(codigo_ruta) <> ''),
    CONSTRAINT rutas_reembolso_chk CHECK (reembolso_total >= 0),
    CONSTRAINT rutas_foto_url_chk CHECK (btrim(foto_cierre_url) <> '')
);

CREATE TABLE IF NOT EXISTS woolfandfox.usuarios (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
    username text NOT NULL,
    password_hash text NOT NULL,
    nombre text NOT NULL,
    rol_sistema woolfandfox.rol_sistema_enum NOT NULL,
    activo boolean DEFAULT true NOT NULL,
    creado_en timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT usuarios_username_chk CHECK (btrim(username) <> ''),
    CONSTRAINT usuarios_nombre_chk CHECK (btrim(nombre) <> '')
);

CREATE TABLE IF NOT EXISTS woolfandfox.vehiculos (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
    matricula text NOT NULL,
    CONSTRAINT vehiculos_matricula_chk CHECK (btrim(matricula) <> '')
);

-- Foreign keys: add only if constraint not present
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'asignacion_personal_ruta_id_rutas_id_fk') THEN
        ALTER TABLE woolfandfox.asignacion_personal
        ADD CONSTRAINT asignacion_personal_ruta_id_rutas_id_fk FOREIGN KEY (ruta_id) REFERENCES woolfandfox.rutas(id) ON DELETE cascade ON UPDATE cascade;
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'asignacion_personal_personal_id_personal_id_fk') THEN
        ALTER TABLE woolfandfox.asignacion_personal
        ADD CONSTRAINT asignacion_personal_personal_id_personal_id_fk FOREIGN KEY (personal_id) REFERENCES woolfandfox.personal(id) ON DELETE restrict ON UPDATE cascade;
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'operaciones_diarias_ruta_id_rutas_id_fk') THEN
        ALTER TABLE woolfandfox.operaciones_diarias
        ADD CONSTRAINT operaciones_diarias_ruta_id_rutas_id_fk FOREIGN KEY (ruta_id) REFERENCES woolfandfox.rutas(id) ON DELETE cascade ON UPDATE cascade;
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'personal_rol_id_roles_id_fk') THEN
        ALTER TABLE woolfandfox.personal
        ADD CONSTRAINT personal_rol_id_roles_id_fk FOREIGN KEY (rol_id) REFERENCES woolfandfox.roles(id) ON DELETE restrict ON UPDATE cascade;
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'rutas_vehiculo_id_vehiculos_id_fk') THEN
        ALTER TABLE woolfandfox.rutas
        ADD CONSTRAINT rutas_vehiculo_id_vehiculos_id_fk FOREIGN KEY (vehiculo_id) REFERENCES woolfandfox.vehiculos(id) ON DELETE restrict ON UPDATE cascade;
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'rutas_confirmado_por_usuarios_id_fk') THEN
        ALTER TABLE woolfandfox.rutas
        ADD CONSTRAINT rutas_confirmado_por_usuarios_id_fk FOREIGN KEY (confirmado_por) REFERENCES woolfandfox.usuarios(id) ON DELETE restrict ON UPDATE cascade;
    END IF;
END $$;

-- Indexes (IF NOT EXISTS)
CREATE INDEX IF NOT EXISTS idx_asignacion_personal_personal_id ON woolfandfox.asignacion_personal (personal_id);
CREATE UNIQUE INDEX IF NOT EXISTS operaciones_diarias_ruta_tipo_uk ON woolfandfox.operaciones_diarias (ruta_id, tipo_operacion);
CREATE INDEX IF NOT EXISTS idx_operaciones_diarias_ruta_id ON woolfandfox.operaciones_diarias (ruta_id);
CREATE INDEX IF NOT EXISTS idx_operaciones_diarias_tipo ON woolfandfox.operaciones_diarias (tipo_operacion);
CREATE INDEX IF NOT EXISTS idx_personal_rol_id ON woolfandfox.personal (rol_id);
CREATE UNIQUE INDEX IF NOT EXISTS roles_nombre_rol_uk ON woolfandfox.roles (nombre_rol);
CREATE UNIQUE INDEX IF NOT EXISTS rutas_codigo_fecha_uk ON woolfandfox.rutas (codigo_ruta, fecha);
CREATE INDEX IF NOT EXISTS idx_rutas_vehiculo_id ON woolfandfox.rutas (vehiculo_id);
CREATE INDEX IF NOT EXISTS idx_rutas_confirmado_por ON woolfandfox.rutas (confirmado_por);
CREATE INDEX IF NOT EXISTS idx_rutas_fecha ON woolfandfox.rutas (fecha DESC NULLS LAST);
CREATE UNIQUE INDEX IF NOT EXISTS usuarios_username_uk ON woolfandfox.usuarios (username);
CREATE UNIQUE INDEX IF NOT EXISTS vehiculos_matricula_uk ON woolfandfox.vehiculos (matricula);

-- Seed roles (idempotent)
INSERT INTO woolfandfox.roles (nombre_rol)
VALUES ('Conductor'), ('Ayudante'), ('Andarín')
ON CONFLICT (nombre_rol) DO NOTHING;

-- End of idempotent migration
