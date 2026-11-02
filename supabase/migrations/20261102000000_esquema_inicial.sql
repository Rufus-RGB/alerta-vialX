-- Alerta Vial · esquema inicial de Supabase
-- Ejecutar completo en: Supabase → SQL Editor → New query → Run.
-- Crea tablas, seguridad por filas (RLS), buckets de fotos y la creación automática de perfiles.

create extension if not exists pgcrypto;

-- =====================================================================
-- Perfiles (uno por usuario de auth.users)
-- =====================================================================
create table if not exists public.perfiles (
  id uuid primary key references auth.users (id) on delete cascade,
  nombre text not null default '',
  correo text not null default '',
  celular text not null default '',
  rol text not null default 'ciudadano' check (rol in ('ciudadano', 'dev', 'autoridad')),
  estado text not null default 'activo' check (estado in ('activo', 'pendiente', 'bloqueado')),
  localidad text not null default 'Chapinero',
  creado_en timestamptz not null default now()
);

-- Funciones de rol (security definer para poder usarlas dentro de las políticas sin recursión).
create or replace function public.es_dev() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.perfiles where id = auth.uid() and rol = 'dev' and estado = 'activo');
$$;

create or replace function public.es_autoridad() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.perfiles where id = auth.uid() and rol = 'autoridad' and estado = 'activo');
$$;

-- Al registrarse se crea el perfil. Solo se aceptan los roles ciudadano o autoridad (pendiente de aprobación);
-- las cuentas DEV se asignan a mano con SQL.
create or replace function public.crear_perfil() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_rol text := coalesce(new.raw_user_meta_data ->> 'rol', 'ciudadano');
begin
  if v_rol not in ('ciudadano', 'autoridad') then
    v_rol := 'ciudadano';
  end if;
  insert into public.perfiles (id, nombre, correo, celular, rol, estado)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'nombre', split_part(new.email, '@', 1)),
    coalesce(new.email, ''),
    coalesce(new.raw_user_meta_data ->> 'celular', ''),
    v_rol,
    case when v_rol = 'autoridad' then 'pendiente' else 'activo' end
  );
  return new;
end;
$$;

drop trigger if exists al_crear_usuario on auth.users;
create trigger al_crear_usuario after insert on auth.users
  for each row execute function public.crear_perfil();

alter table public.perfiles enable row level security;
create policy "perfil: leer propio o dev" on public.perfiles for select
  using (id = auth.uid() or public.es_dev());
create policy "perfil: editar propio" on public.perfiles for update
  using (id = auth.uid())
  with check (id = auth.uid() and rol = (select p.rol from public.perfiles p where p.id = auth.uid())
              and estado = (select p.estado from public.perfiles p where p.id = auth.uid()));
create policy "perfil: dev administra" on public.perfiles for update
  using (public.es_dev()) with check (public.es_dev());

-- =====================================================================
-- Solicitudes de cuenta de autoridad
-- =====================================================================
create table if not exists public.solicitudes_autoridad (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null default auth.uid() references public.perfiles (id) on delete cascade,
  nombre text not null default '',
  correo text not null,
  unidad text not null,
  placa text not null,
  carne_ruta text,
  estado text not null default 'pendiente' check (estado in ('pendiente', 'aprobado', 'rechazado')),
  creado_en timestamptz not null default now()
);
alter table public.solicitudes_autoridad enable row level security;
create policy "solicitud: crear propia" on public.solicitudes_autoridad for insert
  with check (usuario_id = auth.uid());
create policy "solicitud: ver propia o dev" on public.solicitudes_autoridad for select
  using (usuario_id = auth.uid() or public.es_dev());
create policy "solicitud: dev decide" on public.solicitudes_autoridad for update
  using (public.es_dev()) with check (public.es_dev());

-- =====================================================================
-- Reportes de hurto
-- =====================================================================
create sequence if not exists public.reportes_consecutivo start 2053;

create table if not exists public.reportes (
  id text primary key default ('AV-' || nextval('public.reportes_consecutivo')),
  usuario_id uuid default auth.uid() references public.perfiles (id) on delete set null,
  titulo text not null default 'Hurto de moto',
  vehiculo text not null check (vehiculo in ('moto', 'auto')),
  marca text,
  modelo text,
  placa text not null,
  color text,
  fecha timestamptz not null default now(),
  lat double precision not null,
  lng double precision not null,
  barrio text not null default '',
  direccion text not null default '',
  referencia text not null default '',
  descripcion text not null default '',
  fotos text[] not null default '{}',
  anonimo boolean not null default true,
  nivel text not null default 'alto' check (nivel in ('alto', 'medio', 'bajo', 'info')),
  estado text not null default 'enviado' check (estado in ('enviado', 'recibido', 'en_atencion', 'recuperado', 'cerrado')),
  moderacion text not null default 'pendiente' check (moderacion in ('pendiente', 'aprobado', 'rechazado')),
  posible_falso boolean not null default false,
  creado_en timestamptz not null default now()
);
create index if not exists reportes_usuario_idx on public.reportes (usuario_id);
create index if not exists reportes_moderacion_idx on public.reportes (moderacion, creado_en desc);

alter table public.reportes enable row level security;
create policy "reporte: crear propio" on public.reportes for insert
  with check (auth.uid() is not null and usuario_id = auth.uid());
create policy "reporte: ver propios, autoridad o dev" on public.reportes for select
  using (usuario_id = auth.uid() or public.es_autoridad() or public.es_dev());
create policy "reporte: autoridad o dev actualiza" on public.reportes for update
  using (public.es_autoridad() or public.es_dev()) with check (public.es_autoridad() or public.es_dev());

-- Vista pública del mapa: solo reportes aprobados de los últimos 30 días y sin datos del denunciante.
create or replace view public.incidentes_publicos as
  select id, titulo, vehiculo, placa, lat, lng, barrio, direccion, fecha, nivel,
         trim(concat_ws(' ', marca, modelo)) || coalesce(' · ' || color, '') as descripcion_vehiculo
  from public.reportes
  where moderacion = 'aprobado' and fecha > now() - interval '30 days';
grant select on public.incidentes_publicos to anon, authenticated;

-- =====================================================================
-- Perfil: vehículos y zonas favoritas
-- =====================================================================
create table if not exists public.vehiculos (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null default auth.uid() references public.perfiles (id) on delete cascade,
  tipo text not null check (tipo in ('moto', 'auto')),
  marca text not null,
  modelo text not null,
  anio int not null,
  placa text not null,
  color text not null,
  reportes int not null default 0,
  estado text not null default 'protegida' check (estado in ('protegida', 'recuperado', 'reportado')),
  foto text,
  creado_en timestamptz not null default now()
);
alter table public.vehiculos enable row level security;
create policy "vehiculo: dueño" on public.vehiculos for all
  using (usuario_id = auth.uid()) with check (usuario_id = auth.uid());
create policy "vehiculo: autoridad o dev consulta" on public.vehiculos for select
  using (public.es_autoridad() or public.es_dev());

create table if not exists public.zonas_favoritas (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null default auth.uid() references public.perfiles (id) on delete cascade,
  nombre text not null,
  direccion text not null,
  tipo text not null default 'otro' check (tipo in ('casa', 'trabajo', 'estudio', 'otro')),
  lat double precision not null,
  lng double precision not null,
  radio_km numeric not null default 1,
  avisar boolean not null default true,
  nivel text not null default 'bajo' check (nivel in ('alto', 'medio', 'bajo', 'info')),
  creado_en timestamptz not null default now()
);
alter table public.zonas_favoritas enable row level security;
create policy "zona favorita: dueño" on public.zonas_favoritas for all
  using (usuario_id = auth.uid()) with check (usuario_id = auth.uid());

-- =====================================================================
-- Datos públicos: zonas de riesgo, CAI, alertas
-- =====================================================================
create table if not exists public.zonas_riesgo (
  id bigint generated by default as identity primary key,
  nombre text not null unique,
  lat double precision not null,
  lng double precision not null,
  radio_m numeric not null default 1500,
  nivel text not null default 'medio' check (nivel in ('alto', 'medio', 'bajo')),
  reportes_semana int not null default 0,
  automatica boolean not null default false
);
alter table public.zonas_riesgo enable row level security;
create policy "zonas: lectura pública" on public.zonas_riesgo for select using (true);
create policy "zonas: dev escribe" on public.zonas_riesgo for all using (public.es_dev()) with check (public.es_dev());

create table if not exists public.cai (
  id bigint generated by default as identity primary key,
  nombre text not null,
  localidad text not null,
  direccion text not null default '',
  telefono text not null default '123',
  patrullas int,
  estado text not null default 'activo' check (estado in ('activo', 'refuerzo', 'inactivo')),
  tipo text not null default 'CAI' check (tipo in ('CAI', 'Punto seguro', 'Estación')),
  lat double precision not null,
  lng double precision not null
);
alter table public.cai enable row level security;
create policy "cai: lectura pública" on public.cai for select using (true);
create policy "cai: dev escribe" on public.cai for all using (public.es_dev()) with check (public.es_dev());

create table if not exists public.alertas (
  id text primary key default ('AL-' || substr(gen_random_uuid()::text, 1, 6)),
  tipo text not null check (tipo in ('hurto', 'aumento', 'cai', 'zona')),
  titulo text not null,
  lugar text not null,
  nivel text not null default 'alto' check (nivel in ('alto', 'medio', 'bajo', 'info')),
  lat double precision not null,
  lng double precision not null,
  vehiculo text check (vehiculo in ('moto', 'auto')),
  placa text,
  descripcion_vehiculo text,
  direccion text,
  distancia text,
  consejo text,
  creado_en timestamptz not null default now()
);
alter table public.alertas enable row level security;
create policy "alertas: lectura pública" on public.alertas for select using (true);
create policy "alertas: autoridad o dev escribe" on public.alertas for all
  using (public.es_autoridad() or public.es_dev()) with check (public.es_autoridad() or public.es_dev());

-- Notificaciones: usuario_id nulo = para todos.
create table if not exists public.notificaciones (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid references public.perfiles (id) on delete cascade,
  tipo text not null default 'hurto' check (tipo in ('hurto', 'atencion', 'aumento', 'cai', 'zona', 'gracias')),
  titulo text not null,
  detalle text not null default '',
  ruta text,
  leida boolean not null default false,
  creado_en timestamptz not null default now()
);
alter table public.notificaciones enable row level security;
create policy "notificaciones: propias o generales" on public.notificaciones for select
  using (usuario_id = auth.uid() or usuario_id is null);
create policy "notificaciones: marcar leídas" on public.notificaciones for update
  using (usuario_id = auth.uid()) with check (usuario_id = auth.uid());
create policy "notificaciones: dev escribe" on public.notificaciones for insert with check (public.es_dev());

-- =====================================================================
-- Panel DEV
-- =====================================================================
create table if not exists public.envios_masivos (
  id uuid primary key default gen_random_uuid(),
  titulo text not null,
  mensaje text not null default '',
  tipo text not null default 'Alerta de hurto',
  audiencia text[] not null default '{}',
  alcance int not null default 0,
  canales text[] not null default '{push}',
  apertura int not null default 0,
  creado_en timestamptz not null default now()
);
alter table public.envios_masivos enable row level security;
create policy "envios: dev" on public.envios_masivos for all using (public.es_dev()) with check (public.es_dev());

create table if not exists public.registros_actividad (
  id bigint generated by default as identity primary key,
  texto text not null,
  categoria text not null check (categoria in ('Reportes', 'Usuarios', 'Moderación', 'Sistema', 'Errores', 'Casos')),
  creado_en timestamptz not null default now()
);
alter table public.registros_actividad enable row level security;
create policy "registros: dev lee" on public.registros_actividad for select using (public.es_dev());
create policy "registros: autenticados escriben" on public.registros_actividad for insert with check (auth.uid() is not null);

create table if not exists public.permisos_roles (
  permiso text not null,
  rol text not null check (rol in ('ciudadano', 'dev', 'autoridad')),
  primary key (permiso, rol)
);
alter table public.permisos_roles enable row level security;
create policy "permisos: lectura autenticados" on public.permisos_roles for select using (auth.uid() is not null);
create policy "permisos: dev escribe" on public.permisos_roles for all using (public.es_dev()) with check (public.es_dev());

create table if not exists public.configuracion_sistema (
  id int primary key default 1 check (id = 1),
  valores jsonb not null default '{}'::jsonb,
  actualizado_en timestamptz not null default now()
);
alter table public.configuracion_sistema enable row level security;
create policy "config: lectura autenticados" on public.configuracion_sistema for select using (auth.uid() is not null);
create policy "config: dev escribe" on public.configuracion_sistema for all using (public.es_dev()) with check (public.es_dev());

-- =====================================================================
-- Storage: fotos de reportes, vehículos y carnés (privados, carpeta = id del usuario)
-- =====================================================================
insert into storage.buckets (id, name, public)
values ('reportes', 'reportes', false), ('vehiculos', 'vehiculos', false), ('carnes', 'carnes', false)
on conflict (id) do nothing;

create policy "fotos: subir a mi carpeta" on storage.objects for insert to authenticated
  with check (bucket_id in ('reportes', 'vehiculos', 'carnes') and (storage.foldername(name))[1] = auth.uid()::text);
create policy "fotos: ver mis archivos" on storage.objects for select to authenticated
  using (bucket_id in ('reportes', 'vehiculos', 'carnes') and (storage.foldername(name))[1] = auth.uid()::text);
create policy "fotos: autoridad ve reportes y vehículos" on storage.objects for select to authenticated
  using (bucket_id in ('reportes', 'vehiculos') and public.es_autoridad());
create policy "fotos: dev ve todo" on storage.objects for select to authenticated
  using (bucket_id in ('reportes', 'vehiculos', 'carnes') and public.es_dev());
create policy "fotos: borrar mis archivos" on storage.objects for delete to authenticated
  using (bucket_id in ('reportes', 'vehiculos', 'carnes') and (storage.foldername(name))[1] = auth.uid()::text);

-- =====================================================================
-- Registro de autoridades (puede llamarse sin sesión, justo después de signUp)
-- =====================================================================
create or replace function public.crear_solicitud_autoridad(
  p_usuario uuid, p_nombre text, p_correo text, p_unidad text, p_placa text, p_carne text
) returns void
language plpgsql security definer set search_path = public as $$
begin
  if not exists (
    select 1 from public.perfiles
    where id = p_usuario and rol = 'autoridad' and estado = 'pendiente' and lower(correo) = lower(p_correo)
  ) then
    raise exception 'Cuenta de autoridad no válida';
  end if;
  if exists (select 1 from public.solicitudes_autoridad where usuario_id = p_usuario) then
    return;
  end if;
  insert into public.solicitudes_autoridad (usuario_id, nombre, correo, unidad, placa, carne_ruta)
  values (p_usuario, p_nombre, p_correo, p_unidad, p_placa, p_carne);
end;
$$;
grant execute on function public.crear_solicitud_autoridad(uuid, text, text, text, text, text) to anon, authenticated;

-- Carné subido sin sesión: solo en carnes/pendientes/<uid>/ y solo si <uid> es una autoridad pendiente.
create or replace function public.es_autoridad_pendiente(p_id text) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.perfiles where id::text = p_id and rol = 'autoridad' and estado = 'pendiente');
$$;
grant execute on function public.es_autoridad_pendiente(text) to anon, authenticated;

create policy "carné: autoridad pendiente sube" on storage.objects for insert to anon, authenticated
  with check (
    bucket_id = 'carnes'
    and (storage.foldername(name))[1] = 'pendientes'
    and public.es_autoridad_pendiente((storage.foldername(name))[2])
  );

-- Al aprobar o rechazar una solicitud se actualiza el perfil.
create or replace function public.decidir_solicitud() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if new.estado <> old.estado then
    update public.perfiles
      set estado = case when new.estado = 'aprobado' then 'activo' when new.estado = 'rechazado' then 'bloqueado' else 'pendiente' end
      where id = new.usuario_id;
  end if;
  return new;
end;
$$;
drop trigger if exists al_decidir_solicitud on public.solicitudes_autoridad;
create trigger al_decidir_solicitud after update on public.solicitudes_autoridad
  for each row execute function public.decidir_solicitud();
