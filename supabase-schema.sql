-- THE GRID — Command Center cloud store (Supabase)
-- Run this once in Supabase → SQL Editor → New query → Run.

create table if not exists grid_command (
  id          text primary key,
  data        jsonb not null default '{"notes":[],"schedules":[],"ideas":[]}'::jsonb,
  updated_at  timestamptz default now()
);

-- one row holds the whole command-center state
insert into grid_command (id) values ('hk23')
on conflict (id) do nothing;

-- Row Level Security: the public (anon) key may read + update only this table.
alter table grid_command enable row level security;

drop policy if exists grid_command_read   on grid_command;
drop policy if exists grid_command_update on grid_command;

create policy grid_command_read
  on grid_command for select
  to anon, authenticated
  using (true);

create policy grid_command_update
  on grid_command for update
  to anon, authenticated
  using (true) with check (true);

-- ═══ EL TALLER / VIGÍA — presencia en vivo (quién está adentro del universo) ═══
-- Corré este bloque en el SQL editor de tu Supabase para activar la presencia global.
-- Mientras no exista la tabla, VIGÍA funciona en "modo local" (solo te ves a vos).

create table if not exists universe_presence (
  id        text primary key,
  name      text,
  tier      text,
  last_seen timestamptz
);

alter table universe_presence enable row level security;

drop policy if exists universe_presence_read   on universe_presence;
drop policy if exists universe_presence_insert on universe_presence;
drop policy if exists universe_presence_update on universe_presence;

create policy universe_presence_read
  on universe_presence for select
  to anon, authenticated
  using (true);

create policy universe_presence_insert
  on universe_presence for insert
  to anon, authenticated
  with check (true);

create policy universe_presence_update
  on universe_presence for update
  to anon, authenticated
  using (true) with check (true);

-- ═══ MUNDO MVB / CONECTOR — vendedores de entradas integrados a la página ═══
-- Corré este bloque para que la gente pueda registrarse como vendedor/a desde el
-- panel CONECTOR y aparezca para todos. Sin la tabla, el registro queda en modo local.

create table if not exists universe_sellers (
  id         text primary key,
  name       text,
  rol        text,
  contact    text,
  events     text,
  created_at timestamptz
);

alter table universe_sellers enable row level security;

drop policy if exists universe_sellers_read   on universe_sellers;
drop policy if exists universe_sellers_insert on universe_sellers;

create policy universe_sellers_read
  on universe_sellers for select
  to anon, authenticated
  using (true);

create policy universe_sellers_insert
  on universe_sellers for insert
  to anon, authenticated
  with check (true);

-- ═══ MUNDO MVB — eventos cargados desde el propio universo ═══
-- Con esta tabla, todo evento que cargues con "＋ CARGAR UN EVENTO REAL" lo ve
-- todo el mundo. Sin ella, el evento queda guardado en tu dispositivo (marcado LOCAL).

create table if not exists universe_events (
  id         text primary key,
  cat        text,
  name       text,
  venue      text,
  zona       text,
  "when"     text,
  price      text,
  fire       int,
  lineup     text,
  tags       text,
  why        text,
  px         real,
  py         real,
  created_at timestamptz
);

alter table universe_events enable row level security;

drop policy if exists universe_events_read   on universe_events;
drop policy if exists universe_events_insert on universe_events;

create policy universe_events_read
  on universe_events for select
  to anon, authenticated
  using (true);

create policy universe_events_insert
  on universe_events for insert
  to anon, authenticated
  with check (true);
