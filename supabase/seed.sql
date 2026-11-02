-- Alerta Vial · datos iniciales (los mismos del diseño de Figma).
-- Ejecutar después de la migración, en Supabase → SQL Editor.

insert into public.zonas_riesgo (nombre, lat, lng, radio_m, nivel, reportes_semana, automatica) values
  ('Kennedy', 4.6286, -74.1569, 1500, 'alto', 42, true),
  ('Bosa', 4.6186, -74.1906, 1300, 'alto', 35, true),
  ('Ciudad Bolívar', 4.5097, -74.1522, 1500, 'alto', 31, false),
  ('Engativá', 4.7069, -74.1150, 1200, 'medio', 19, true),
  ('Chapinero', 4.6683, -74.0537, 1000, 'medio', 16, false),
  ('Usaquén', 4.7030, -74.0300, 1500, 'bajo', 6, false)
on conflict (nombre) do nothing;

insert into public.cai (nombre, localidad, direccion, telefono, patrullas, estado, tipo, lat, lng) values
  ('CAI Chapinero', 'Chapinero', 'Calle 63 # 13-20', '601 235 0000', 3, 'activo', 'CAI', 4.6490, -74.0640),
  ('CAI Fontanar', 'Suba', 'Calle 145 # 92-50', '601 680 1111', 2, 'activo', 'CAI', 4.7480, -74.0950),
  ('CAI Patio Bonito', 'Kennedy', 'Cra. 86 # 38-10 Sur', '601 451 2222', 4, 'activo', 'CAI', 4.6330, -74.1640),
  ('CAI Bosa Centro', 'Bosa', 'Cl. 65 Sur # 80-10', '601 775 3333', 2, 'activo', 'CAI', 4.6170, -74.1930),
  ('CAI Lucero', 'Ciudad Bolívar', 'Cl. 70 Sur # 17C-05', '601 731 4444', 1, 'refuerzo', 'CAI', 4.5130, -74.1500),
  ('CAI Galerías', 'Teusaquillo', 'Cl. 53 # 24-30', '601 288 5555', 2, 'activo', 'CAI', 4.6440, -74.0770),
  ('CAI Unicentro', 'Usaquén', 'Cra. 15 # 124-30', '601 213 6666', 3, 'activo', 'CAI', 4.7020, -74.0420),
  ('CAI Álamos', 'Engativá', 'Cl. 72 # 98-20', '601 547 7777', 0, 'inactivo', 'CAI', 4.6970, -74.1140),
  ('Punto seguro Calle 72', 'Chapinero', 'Cl. 72 # 10-30', '—', null, 'activo', 'Punto seguro', 4.6580, -74.0580),
  ('CAI Tintal', 'Kennedy', 'Cra. 86 # 6-37', '601 452 8888', 2, 'activo', 'CAI', 4.6420, -74.1560),
  ('Estación Kennedy', 'Kennedy', 'Av. 1 de Mayo # 73-50 Sur', '601 450 0000', 12, 'activo', 'Estación', 4.6240, -74.1500);

insert into public.alertas (id, tipo, titulo, lugar, nivel, lat, lng, vehiculo, placa, descripcion_vehiculo, direccion, distancia, consejo, creado_en) values
  ('AL-301', 'hurto', 'Hurto reportado cerca', 'Kennedy', 'alto', 4.6265, -74.1480, 'moto', 'HGT56Y', 'Motocicleta · Pulsar NS200', 'Av. Boyacá con Calle 38 sur', 'A 800 m de tu ubicación', 'Evita la zona y asegura tu vehículo con candado.', now() - interval '3 minutes'),
  ('AL-300', 'aumento', 'Aumento de reportes', 'Teusaquillo', 'medio', 4.6381, -74.0786, null, null, null, null, 'A 3,1 km de tu ubicación', 'Parquea en lugares vigilados y con buena iluminación.', now() - interval '165 minutes'),
  ('AL-299', 'cai', 'CAI cercano', 'CAI Fontanar', 'info', 4.7480, -74.0950, null, null, null, 'Calle 145 # 92-50, Suba', 'A 1,2 km de tu ubicación', 'Guarda el número del CAI para emergencias.', now() - interval '135 minutes'),
  ('AL-298', 'zona', 'Zona de alto riesgo', 'Kennedy', 'alto', 4.6286, -74.1569, null, null, null, null, 'A 1,5 km de tu ubicación', 'Evita detenerte en semáforos solitarios en la noche.', now() - interval '165 minutes')
on conflict (id) do nothing;

insert into public.notificaciones (usuario_id, tipo, titulo, detalle, ruta, creado_en) values
  (null, 'hurto', 'Hurto a 500 m de ti', 'Moto · Chapinero', '/mapa?zona=Chapinero', now() - interval '5 minutes'),
  (null, 'aumento', 'Aumento de reportes en Kennedy', '+35 % esta semana', '/mapa?zona=Kennedy', now() - interval '2 hours'),
  (null, 'cai', 'Nuevo CAI cerca de tu zona', 'CAI Fontanar · Suba', null, now() - interval '2 days');

insert into public.permisos_roles (permiso, rol) values
  ('Crear reportes', 'ciudadano'), ('Crear reportes', 'autoridad'), ('Crear reportes', 'dev'),
  ('Ver mapa y alertas', 'ciudadano'), ('Ver mapa y alertas', 'autoridad'), ('Ver mapa y alertas', 'dev'),
  ('Ver datos personales del denunciante', 'autoridad'), ('Ver datos personales del denunciante', 'dev'),
  ('Atender y cerrar casos', 'autoridad'),
  ('Consultar placas', 'autoridad'), ('Consultar placas', 'dev'),
  ('Moderar reportes', 'dev'), ('Aprobar autoridades', 'dev'), ('Gestionar usuarios', 'dev'),
  ('Enviar notificaciones masivas', 'dev'), ('Configurar sistema', 'dev'),
  ('Exportar datos', 'autoridad'), ('Exportar datos', 'dev')
on conflict do nothing;

insert into public.configuracion_sistema (id, valores) values
  (1, '{"mapaCalor": true, "zonasAutomaticas": true, "exigirFoto": false, "moderacionAutomatica": true, "cierreHoras": 72, "mantenimiento": false}')
on conflict (id) do nothing;

insert into public.registros_actividad (texto, categoria) values
  ('Copia de seguridad completada', 'Sistema'),
  ('Base de datos inicializada con los datos del diseño', 'Sistema');

-- Para convertir tu cuenta en DEV (después de registrarte en la app), cambia el correo y ejecuta:
-- update public.perfiles set rol = 'dev', estado = 'activo' where correo = 'tu-correo@ejemplo.com';
