CREATE TYPE "public"."woolfandfox.rol_sistema_enum" AS ENUM('admin', 'administrativo');--> statement-breakpoint
CREATE TYPE "public"."woolfandfox.tipo_operacion_enum" AS ENUM('Entrega', 'Recogida');--> statement-breakpoint
CREATE TABLE "woolfandfox.asignacion_personal" (
	"ruta_id" uuid NOT NULL,
	"personal_id" uuid NOT NULL
);
--> statement-breakpoint
CREATE TABLE "woolfandfox.operaciones_diarias" (
	"id" uuid PRIMARY KEY DEFAULT 'gen_random_uuid()' NOT NULL,
	"ruta_id" uuid NOT NULL,
	"tipo_operacion" "woolfandfox.tipo_operacion_enum" NOT NULL,
	"exitosas" integer NOT NULL,
	"incidencias" integer NOT NULL,
	"total" integer NOT NULL
);
--> statement-breakpoint
CREATE TABLE "woolfandfox.personal" (
	"id" uuid PRIMARY KEY DEFAULT 'gen_random_uuid()' NOT NULL,
	"nombre" text NOT NULL,
	"rol_id" integer NOT NULL
);
--> statement-breakpoint
CREATE TABLE "woolfandfox.roles" (
	"id" serial PRIMARY KEY NOT NULL,
	"nombre_rol" text NOT NULL
);
--> statement-breakpoint
CREATE TABLE "woolfandfox.rutas" (
	"id" uuid PRIMARY KEY DEFAULT 'gen_random_uuid()' NOT NULL,
	"codigo_ruta" text NOT NULL,
	"fecha" text NOT NULL,
	"vehiculo_id" uuid NOT NULL,
	"reembolso_total" numeric DEFAULT 0 NOT NULL,
	"comentarios_percances" text,
	"confirmado_por" uuid NOT NULL,
	"foto_cierre_url" text NOT NULL,
	"hora_cierre" timestamp NOT NULL
);
--> statement-breakpoint
CREATE TABLE "woolfandfox.usuarios" (
	"id" uuid PRIMARY KEY DEFAULT 'gen_random_uuid()' NOT NULL,
	"username" text NOT NULL,
	"password_hash" text NOT NULL,
	"nombre" text NOT NULL,
	"rol_sistema" "woolfandfox.rol_sistema_enum" NOT NULL,
	"activo" boolean DEFAULT true NOT NULL,
	"creado_en" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "woolfandfox.vehiculos" (
	"id" uuid PRIMARY KEY DEFAULT 'gen_random_uuid()' NOT NULL,
	"matricula" text NOT NULL
);
