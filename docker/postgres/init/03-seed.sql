-- Seed inicial para roles y usuarios (usar solo en entornos de desarrollo)
-- Requiere la extensión pgcrypto para crypt()/gen_salt()

BEGIN;

-- Roles operativos (id serial)
INSERT INTO woolfandfox.roles (nombre_rol)
VALUES ('Conductor'), ('Ayudante'), ('Andarín')
ON CONFLICT (nombre_rol) DO NOTHING;

-- Usuarios administrativos (passwords generados con crypt + gen_salt)
-- Reemplaza las contraseñas por valores definitivos en producción.
INSERT INTO woolfandfox.usuarios (username, password_hash, nombre, rol_sistema)
VALUES
  ('yesica', crypt('changeme123', gen_salt('bf')), 'Yesica', 'administrativo'),
  ('alejandra', crypt('changeme123', gen_salt('bf')), 'Alejandra', 'administrativo'),
  ('demily', crypt('changeme123', gen_salt('bf')), 'Demily', 'administrativo'),
  ('admin', crypt('adminchangeme!', gen_salt('bf')), 'Administrador', 'admin')
ON CONFLICT (username) DO NOTHING;

COMMIT;
