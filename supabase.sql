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
