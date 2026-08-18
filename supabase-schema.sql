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

-- ═══ INQUILINOS — galaxias de usuarios dentro del universo madre ═══
-- Cada inquilino (ej. MVB · JEAN CHRISTOPHE) entra por TU puerta con su código,
-- vive en su galaxia y usa TUS agentes. Sin estas tablas todo funciona igual,
-- pero queda guardado solo en tu dispositivo (marcado LOCAL).

create table if not exists universe_galaxies (
  slug       text primary key,
  name       text,
  code       text,
  sub        text,
  bio        text,
  color      text,
  form       text,
  bg         text,
  tier       text,
  active     boolean default true,
  agents     text,
  links      text,
  created_at timestamptz
);

alter table universe_galaxies enable row level security;

drop policy if exists universe_galaxies_read   on universe_galaxies;
drop policy if exists universe_galaxies_insert on universe_galaxies;
drop policy if exists universe_galaxies_update on universe_galaxies;

create policy universe_galaxies_read
  on universe_galaxies for select
  to anon, authenticated
  using (true);

create policy universe_galaxies_insert
  on universe_galaxies for insert
  to anon, authenticated
  with check (true);

create policy universe_galaxies_update
  on universe_galaxies for update
  to anon, authenticated
  using (true) with check (true);

create table if not exists universe_products (
  id         text primary key,
  owner      text,
  name       text,
  kind       text,
  "desc"     text,
  url        text,
  created_at timestamptz
);

alter table universe_products enable row level security;

drop policy if exists universe_products_read   on universe_products;
drop policy if exists universe_products_insert on universe_products;

create policy universe_products_read
  on universe_products for select
  to anon, authenticated
  using (true);

create policy universe_products_insert
  on universe_products for insert
  to anon, authenticated
  with check (true);

-- El universo del inquilino guarda SUS nodos (los crea él mismo desde adentro).
alter table universe_galaxies add column if not exists nodes text;

-- ═══════════════════════════════════════════════════════════════════════════
-- VICEGOLFER — EARLY ACCESS / BETA SYSTEM
-- Corré este bloque completo en Supabase → SQL Editor → Run.
-- Alimenta /early-access (registro público vía RPC) y /admin/beta (dashboard).
-- La página pública NUNCA lee las tablas: solo puede ejecutar vg_apply_beta().
-- El admin entra con Supabase Auth (crear el usuario en Authentication → Users).
-- ═══════════════════════════════════════════════════════════════════════════

-- ── Campañas / cohortes (reutilizable: Beta 002, torneos, releases futuros) ──
create table if not exists vg_beta_campaigns (
  id           uuid primary key default gen_random_uuid(),
  campaign     text unique not null,            -- ej: vice_tracer_beta_001
  cohort       text not null,                   -- ej: BETA_001
  cohort_label text,                            -- ej: VICEGOLFER BETA 001
  capacity     int  not null default 25,        -- cupos antes de pasar a waitlist
  beta_prefix  text not null default 'VG-BETA-',
  wait_prefix  text not null default 'VG-WAIT-',
  is_active    boolean not null default true,
  created_at   timestamptz not null default now()
);

insert into vg_beta_campaigns (campaign, cohort, cohort_label, capacity)
values ('vice_tracer_beta_001', 'BETA_001', 'VICEGOLFER BETA 001', 25)
on conflict (campaign) do nothing;

-- ── Solicitudes de acceso ──
create table if not exists vg_beta_applications (
  id               uuid primary key default gen_random_uuid(),
  campaign_id      uuid not null references vg_beta_campaigns(id),
  campaign         text not null,
  beta_cohort      text not null,               -- BETA_001 | WAITLIST
  position         int  not null,
  beta_id          text not null,               -- VG-BETA-001 / VG-WAIT-026
  user_id          uuid,                        -- link futuro a auth.users al activar
  name             text not null,
  email            text not null,
  social_handle    text not null,
  handicap         numeric(4,1),
  club             text,
  improvement_area text,
  source           text,
  referral_url     text,
  status           text not null default 'APPLIED'
                   check (status in ('APPLIED','SELECTED','WAITLIST','INVITED',
                                     'ACTIVATED','FEEDBACK_RECEIVED','DECLINED')),
  utm_source       text,
  utm_medium       text,
  utm_campaign     text,
  utm_content      text,
  notes            text,
  created_at       timestamptz not null default now(),
  approved_at      timestamptz,
  invited_at       timestamptz,
  activated_at     timestamptz,
  unique (campaign_id, position)
);

create unique index if not exists vg_beta_applications_email_uq
  on vg_beta_applications (campaign_id, lower(email));
create index if not exists vg_beta_applications_status_ix
  on vg_beta_applications (campaign_id, status);
create index if not exists vg_beta_applications_source_ix
  on vg_beta_applications (campaign_id, source);

-- ── RLS: anon NO puede leer ni escribir las tablas. Solo el admin logueado. ──
alter table vg_beta_campaigns    enable row level security;
alter table vg_beta_applications enable row level security;

drop policy if exists vg_campaigns_admin_read  on vg_beta_campaigns;
drop policy if exists vg_apps_admin_read       on vg_beta_applications;
drop policy if exists vg_apps_admin_update     on vg_beta_applications;

create policy vg_campaigns_admin_read
  on vg_beta_campaigns for select
  to authenticated
  using ((auth.jwt() ->> 'email') = 'hk23hub@gmail.com');

create policy vg_apps_admin_read
  on vg_beta_applications for select
  to authenticated
  using ((auth.jwt() ->> 'email') = 'hk23hub@gmail.com');

create policy vg_apps_admin_update
  on vg_beta_applications for update
  to authenticated
  using      ((auth.jwt() ->> 'email') = 'hk23hub@gmail.com')
  with check ((auth.jwt() ->> 'email') = 'hk23hub@gmail.com');

-- ── Timestamps automáticos al cambiar status desde el admin ──
create or replace function vg_beta_status_stamp() returns trigger
language plpgsql as $$
begin
  if new.status is distinct from old.status then
    if new.status = 'SELECTED'  and new.approved_at  is null then new.approved_at  := now(); end if;
    if new.status = 'INVITED'   and new.invited_at   is null then new.invited_at   := now(); end if;
    if new.status = 'ACTIVATED' and new.activated_at is null then new.activated_at := now(); end if;
  end if;
  return new;
end $$;

drop trigger if exists vg_beta_status_stamp_trg on vg_beta_applications;
create trigger vg_beta_status_stamp_trg
  before update on vg_beta_applications
  for each row execute function vg_beta_status_stamp();

-- ── RPC público: registro server-side, race-safe, con dedupe y validación ──
create or replace function vg_apply_beta(
  p_campaign     text,
  p_name         text,
  p_email        text,
  p_social       text,
  p_handicap     numeric default null,
  p_club         text default null,
  p_improvement  text default null,
  p_source       text default null,
  p_referral     text default null,
  p_utm_source   text default null,
  p_utm_medium   text default null,
  p_utm_campaign text default null,
  p_utm_content  text default null
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  c        vg_beta_campaigns%rowtype;
  existing vg_beta_applications%rowtype;
  v_email  text;
  v_pos    int;
  v_cohort text;
  v_status text;
  v_id     text;
  v_recent int;
begin
  -- validación server-side
  v_email := lower(trim(coalesce(p_email,'')));
  if v_email !~ '^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$' or length(v_email) > 254 then
    return jsonb_build_object('ok', false, 'error', 'invalid_email');
  end if;
  if coalesce(trim(p_name),'') = '' or length(p_name) > 120 then
    return jsonb_build_object('ok', false, 'error', 'invalid_name');
  end if;
  if coalesce(trim(p_social),'') = '' or length(p_social) > 80 then
    return jsonb_build_object('ok', false, 'error', 'invalid_social');
  end if;
  if p_handicap is not null and (p_handicap < -10 or p_handicap > 54) then
    return jsonb_build_object('ok', false, 'error', 'invalid_handicap');
  end if;

  -- campaña pedida, o la activa más reciente como fallback
  select * into c from vg_beta_campaigns
    where campaign = nullif(trim(coalesce(p_campaign,'')),'');
  if not found then
    select * into c from vg_beta_campaigns
      where is_active order by created_at desc limit 1;
  end if;
  if not found then
    return jsonb_build_object('ok', false, 'error', 'no_campaign');
  end if;

  -- duplicado: mismo email no puede ocupar dos posiciones
  select * into existing from vg_beta_applications
    where campaign_id = c.id and lower(email) = v_email;
  if found then
    return jsonb_build_object('ok', true, 'duplicate', true,
      'beta_id', existing.beta_id, 'cohort', existing.beta_cohort,
      'status', existing.status, 'position', existing.position);
  end if;

  -- rate limit blando: máx 30 registros nuevos por minuto por campaña
  select count(*) into v_recent from vg_beta_applications
    where campaign_id = c.id and created_at > now() - interval '60 seconds';
  if v_recent >= 30 then
    return jsonb_build_object('ok', false, 'error', 'rate_limited');
  end if;

  -- lock por campaña: dos registros simultáneos jamás comparten posición
  perform pg_advisory_xact_lock(hashtext('vg_beta_' || c.id::text));

  select coalesce(max(position), 0) + 1 into v_pos
    from vg_beta_applications where campaign_id = c.id;

  if v_pos <= c.capacity then
    v_cohort := c.cohort;
    v_status := 'APPLIED';
    v_id     := c.beta_prefix || lpad(v_pos::text, 3, '0');
  else
    v_cohort := 'WAITLIST';
    v_status := 'WAITLIST';
    v_id     := c.wait_prefix || lpad(v_pos::text, 3, '0');
  end if;

  begin
    insert into vg_beta_applications
      (campaign_id, campaign, beta_cohort, position, beta_id,
       name, email, social_handle, handicap, club, improvement_area,
       source, referral_url, status,
       utm_source, utm_medium, utm_campaign, utm_content)
    values
      (c.id, c.campaign, v_cohort, v_pos, v_id,
       left(trim(p_name),120), v_email, left(trim(p_social),80),
       p_handicap, nullif(left(trim(coalesce(p_club,'')),120),''),
       nullif(left(trim(coalesce(p_improvement,'')),60),''),
       nullif(left(trim(coalesce(p_source,'')),60),''),
       nullif(left(trim(coalesce(p_referral,'')),500),''),
       v_status,
       nullif(left(trim(coalesce(p_utm_source,'')),120),''),
       nullif(left(trim(coalesce(p_utm_medium,'')),120),''),
       nullif(left(trim(coalesce(p_utm_campaign,'')),120),''),
       nullif(left(trim(coalesce(p_utm_content,'')),120),''));
  exception when unique_violation then
    -- carrera exacta con el mismo email: devolver el registro existente
    select * into existing from vg_beta_applications
      where campaign_id = c.id and lower(email) = v_email;
    return jsonb_build_object('ok', true, 'duplicate', true,
      'beta_id', existing.beta_id, 'cohort', existing.beta_cohort,
      'status', existing.status, 'position', existing.position);
  end;

  return jsonb_build_object('ok', true, 'duplicate', false,
    'beta_id', v_id, 'cohort', v_cohort, 'status', v_status, 'position', v_pos);
end $$;

revoke all on function vg_apply_beta(text,text,text,text,numeric,text,text,text,text,text,text,text,text) from public;
grant execute on function vg_apply_beta(text,text,text,text,numeric,text,text,text,text,text,text,text,text) to anon, authenticated;
