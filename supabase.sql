-- ============================================================
-- Finanzas personales · configuración de la base de datos
-- Pega TODO este contenido en el SQL Editor de Supabase
-- y presiona "Run". Se puede volver a ejecutar sin problema.
-- ============================================================

-- 1. La tabla: una sola fila por usuario, con todos tus datos dentro.
create table if not exists public.finanzas (
  user_id     uuid primary key references auth.users(id) on delete cascade,
  estado      jsonb not null,
  actualizado timestamptz not null default now()
);

-- Límite de tamaño como red de seguridad: tus finanzas reales pesan pocos KB
-- incluso con años de movimientos, así que 5 MB deja mucho margen y solo
-- evita que un error de la app (o un intento de abuso) llene la base de
-- datos con una fila gigante. Si ya habías creado la tabla antes de esto,
-- este bloque se lo agrega ahora; si la tabla es nueva, no hace nada extra.
do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'finanzas_estado_tamano_max'
  ) then
    alter table public.finanzas
      add constraint finanzas_estado_tamano_max
      check (pg_column_size(estado) < 5 * 1024 * 1024);
  end if;
end $$;

-- 2. Seguridad a nivel de fila: sin esto, cualquiera con la clave pública
--    podría leer la tabla. Con esto, cada quien solo alcanza su propia fila.
alter table public.finanzas enable row level security;

drop policy if exists "cada usuario ve solo lo suyo" on public.finanzas;
create policy "cada usuario ve solo lo suyo"
  on public.finanzas
  for all
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- 3. Exponer la tabla en la API. Desde 2026 las tablas nuevas no quedan
--    expuestas por defecto, así que estos permisos son obligatorios.
grant usage on schema public to authenticated;
grant select, insert, update, delete on table public.finanzas to authenticated;

-- ============================================================
-- Comprobación: debe devolver una fila con rowsecurity = true
-- ============================================================
select schemaname, tablename, rowsecurity
from pg_tables
where tablename = 'finanzas';


-- ============================================================
-- PARTE 2 (opcional) · Aprobar quién puede crear una cuenta
-- Sin esto, cualquiera con el enlace de tu sitio puede registrarse.
-- Con esto, solo se crea la cuenta si el correo está en la lista
-- de abajo. Se puede volver a ejecutar sin problema.
-- ============================================================

-- 1. La lista de correos autorizados a registrarse.
create table if not exists public.invitados (
  email      text primary key,
  nota       text,
  creado_en  timestamptz not null default now()
);

-- Se protege a propósito sin ninguna política: así, nadie puede leerla
-- ni modificarla a través de la clave pública de la app. Solo tú, desde
-- el SQL Editor o el Table Editor del panel de Supabase, puedes tocarla.
alter table public.invitados enable row level security;

-- 2. Escribe aquí los correos que sí pueden crear una cuenta.
--    Para aprobar a alguien más adelante, no hace falta repetir todo
--    este script: basta con un INSERT como este, o usar el Table Editor.
insert into public.invitados (email) values
  ('tu-correo@ejemplo.com'),
  ('correo-de-tu-pareja@ejemplo.com')
on conflict (email) do nothing;

-- 3. La función que Supabase consulta justo antes de crear cualquier cuenta.
create or replace function public.hook_aprobar_registro(event jsonb)
returns jsonb
language plpgsql
as $$
declare
  correo text;
begin
  correo := lower(trim(event->'user'->>'email'));

  if exists (select 1 from public.invitados where lower(email) = correo) then
    return '{}'::jsonb; -- está en la lista: se deja crear la cuenta
  end if;

  return jsonb_build_object(
    'error', jsonb_build_object(
      'http_code', 403,
      'message', 'Este correo todavía no está autorizado para crear una cuenta. Pídele a quien administra la app que lo agregue primero.'
    )
  );
end;
$$;

-- 4. Permisos: solo el propio sistema de autenticación de Supabase
--    puede llamar esta función y leer la lista; nadie más.
grant usage on schema public to supabase_auth_admin;
grant select on public.invitados to supabase_auth_admin;
grant execute on function public.hook_aprobar_registro(jsonb) to supabase_auth_admin;
revoke execute on function public.hook_aprobar_registro(jsonb) from authenticated, anon, public;

-- ============================================================
-- Después de correr esto, falta UN paso que solo se hace desde el
-- panel (no por SQL): activar el gancho. Ver el README para el detalle.
-- ============================================================

