CREATE SCHEMA "woolfandfox";
--> statement-breakpoint
CREATE TYPE "woolfandfox"."rol_sistema_enum" AS ENUM('admin', 'administrativo');--> statement-breakpoint
CREATE TYPE "woolfandfox"."tipo_operacion_enum" AS ENUM('Entrega', 'Recogida');--> statement-breakpoint
CREATE TABLE "woolfandfox"."asignacion_personal" (
	"ruta_id" uuid NOT NULL,
	"personal_id" uuid NOT NULL,
	CONSTRAINT "asignacion_personal_ruta_id_personal_id_pk" PRIMARY KEY("ruta_id","personal_id")
);
--> statement-breakpoint
CREATE TABLE "woolfandfox"."operaciones_diarias" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"ruta_id" uuid NOT NULL,
	"tipo_operacion" "woolfandfox"."tipo_operacion_enum" NOT NULL,
	"exitosas" integer NOT NULL,
	"incidencias" integer NOT NULL,
	"total" integer NOT NULL,
	CONSTRAINT "operaciones_diarias_exitosas_chk" CHECK ("woolfandfox"."operaciones_diarias"."exitosas" >= 0),
	CONSTRAINT "operaciones_diarias_incidencias_chk" CHECK ("woolfandfox"."operaciones_diarias"."incidencias" >= 0),
	CONSTRAINT "operaciones_diarias_total_chk" CHECK ("woolfandfox"."operaciones_diarias"."total" >= 0),
	CONSTRAINT "operaciones_diarias_total_consistency_chk" CHECK ("woolfandfox"."operaciones_diarias"."total" = "woolfandfox"."operaciones_diarias"."exitosas" + "woolfandfox"."operaciones_diarias"."incidencias")
);
--> statement-breakpoint
CREATE TABLE "woolfandfox"."personal" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"nombre" text NOT NULL,
	"rol_id" integer NOT NULL,
	CONSTRAINT "personal_nombre_chk" CHECK (btrim("woolfandfox"."personal"."nombre") <> '')
);
--> statement-breakpoint
CREATE TABLE "woolfandfox"."roles" (
	"id" serial PRIMARY KEY NOT NULL,
	"nombre_rol" text NOT NULL,
	CONSTRAINT "roles_nombre_rol_chk" CHECK ("woolfandfox"."roles"."nombre_rol" in ('Conductor', 'Ayudante', 'Andarín'))
);
--> statement-breakpoint
CREATE TABLE "woolfandfox"."rutas" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"codigo_ruta" text NOT NULL,
	"fecha" date NOT NULL,
	"vehiculo_id" uuid NOT NULL,
	"reembolso_total" numeric(12, 2) DEFAULT '0' NOT NULL,
	"comentarios_percances" text,
	"confirmado_por" uuid NOT NULL,
	"foto_cierre_url" text NOT NULL,
	"hora_cierre" timestamp with time zone NOT NULL,
	CONSTRAINT "rutas_codigo_chk" CHECK (btrim("woolfandfox"."rutas"."codigo_ruta") <> ''),
	CONSTRAINT "rutas_reembolso_chk" CHECK ("woolfandfox"."rutas"."reembolso_total" >= 0),
	CONSTRAINT "rutas_foto_url_chk" CHECK (btrim("woolfandfox"."rutas"."foto_cierre_url") <> '')
);
--> statement-breakpoint
CREATE TABLE "woolfandfox"."usuarios" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"username" text NOT NULL,
	"password_hash" text NOT NULL,
	"nombre" text NOT NULL,
	"rol_sistema" "woolfandfox"."rol_sistema_enum" NOT NULL,
	"activo" boolean DEFAULT true NOT NULL,
	"creado_en" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "usuarios_username_chk" CHECK (btrim("woolfandfox"."usuarios"."username") <> ''),
	CONSTRAINT "usuarios_nombre_chk" CHECK (btrim("woolfandfox"."usuarios"."nombre") <> '')
);
--> statement-breakpoint
CREATE TABLE "woolfandfox"."vehiculos" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"matricula" text NOT NULL,
	CONSTRAINT "vehiculos_matricula_chk" CHECK (btrim("woolfandfox"."vehiculos"."matricula") <> '')
);
--> statement-breakpoint

ALTER TABLE "woolfandfox"."asignacion_personal" ADD CONSTRAINT "asignacion_personal_ruta_id_rutas_id_fk" FOREIGN KEY ("ruta_id") REFERENCES "woolfandfox"."rutas"("id") ON DELETE cascade ON UPDATE cascade;--> statement-breakpoint
ALTER TABLE "woolfandfox"."asignacion_personal" ADD CONSTRAINT "asignacion_personal_personal_id_personal_id_fk" FOREIGN KEY ("personal_id") REFERENCES "woolfandfox"."personal"("id") ON DELETE restrict ON UPDATE cascade;--> statement-breakpoint
ALTER TABLE "woolfandfox"."operaciones_diarias" ADD CONSTRAINT "operaciones_diarias_ruta_id_rutas_id_fk" FOREIGN KEY ("ruta_id") REFERENCES "woolfandfox"."rutas"("id") ON DELETE cascade ON UPDATE cascade;--> statement-breakpoint
ALTER TABLE "woolfandfox"."personal" ADD CONSTRAINT "personal_rol_id_roles_id_fk" FOREIGN KEY ("rol_id") REFERENCES "woolfandfox"."roles"("id") ON DELETE restrict ON UPDATE cascade;--> statement-breakpoint
ALTER TABLE "woolfandfox"."rutas" ADD CONSTRAINT "rutas_vehiculo_id_vehiculos_id_fk" FOREIGN KEY ("vehiculo_id") REFERENCES "woolfandfox"."vehiculos"("id") ON DELETE restrict ON UPDATE cascade;--> statement-breakpoint
ALTER TABLE "woolfandfox"."rutas" ADD CONSTRAINT "rutas_confirmado_por_usuarios_id_fk" FOREIGN KEY ("confirmado_por") REFERENCES "woolfandfox"."usuarios"("id") ON DELETE restrict ON UPDATE cascade;--> statement-breakpoint
CREATE INDEX "idx_asignacion_personal_personal_id" ON "woolfandfox"."asignacion_personal" USING btree ("personal_id");--> statement-breakpoint
CREATE UNIQUE INDEX "operaciones_diarias_ruta_tipo_uk" ON "woolfandfox"."operaciones_diarias" USING btree ("ruta_id","tipo_operacion");--> statement-breakpoint
CREATE INDEX "idx_operaciones_diarias_ruta_id" ON "woolfandfox"."operaciones_diarias" USING btree ("ruta_id");--> statement-breakpoint
CREATE INDEX "idx_operaciones_diarias_tipo" ON "woolfandfox"."operaciones_diarias" USING btree ("tipo_operacion");--> statement-breakpoint
CREATE INDEX "idx_personal_rol_id" ON "woolfandfox"."personal" USING btree ("rol_id");--> statement-breakpoint
CREATE UNIQUE INDEX "roles_nombre_rol_uk" ON "woolfandfox"."roles" USING btree ("nombre_rol");--> statement-breakpoint
CREATE UNIQUE INDEX "rutas_codigo_fecha_uk" ON "woolfandfox"."rutas" USING btree ("codigo_ruta","fecha");--> statement-breakpoint
CREATE INDEX "idx_rutas_vehiculo_id" ON "woolfandfox"."rutas" USING btree ("vehiculo_id");--> statement-breakpoint
CREATE INDEX "idx_rutas_confirmado_por" ON "woolfandfox"."rutas" USING btree ("confirmado_por");--> statement-breakpoint
CREATE INDEX "idx_rutas_fecha" ON "woolfandfox"."rutas" USING btree ("fecha" DESC NULLS LAST);--> statement-breakpoint
CREATE UNIQUE INDEX "usuarios_username_uk" ON "woolfandfox"."usuarios" USING btree ("username");--> statement-breakpoint
CREATE UNIQUE INDEX "vehiculos_matricula_uk" ON "woolfandfox"."vehiculos" USING btree ("matricula");--> statement-breakpoint
-- Removed DROP TYPE statements generated incorrectly by earlier migration generation