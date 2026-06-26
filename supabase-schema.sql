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
