-- Human Rights Museum App remote sync schema
create extension if not exists pgcrypto;

create table if not exists public.app_errors (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  app_version text not null,
  build_number text not null,
  platform text not null,
  device_model text,
  error_source text not null,
  error_message text not null,
  stack_trace text,
  context_json jsonb default '{}'::jsonb,
  beacon_snapshot_json jsonb default '[]'::jsonb
);

create table if not exists public.beacon_registry (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  beacon_key text not null unique,
  display_name text not null,
  remote_id text,
  device_name text,
  manufacturer_hex text,
  service_data_hex text,
  last_rssi integer,
  note text,
  extra_json jsonb default '{}'::jsonb
);

create table if not exists public.test_sessions (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  session_name text not null,
  test_type text not null,
  note text,
  location_label text,
  content_version text,
  app_version text,
  beacon_keys text[] default '{}',
  metadata_json jsonb default '{}'::jsonb
);

create table if not exists public.session_media (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  session_id uuid references public.test_sessions(id) on delete cascade,
  media_type text not null,
  storage_path text not null,
  public_url text,
  metadata_json jsonb default '{}'::jsonb
);

alter table public.app_errors enable row level security;
alter table public.beacon_registry enable row level security;
alter table public.test_sessions enable row level security;
alter table public.session_media enable row level security;

create policy "allow anon insert app_errors"
on public.app_errors
for insert
to anon
with check (true);

create policy "allow anon select beacon_registry"
on public.beacon_registry
for select
to anon
using (true);

create policy "allow anon insert beacon_registry"
on public.beacon_registry
for insert
to anon
with check (true);

create policy "allow anon update beacon_registry"
on public.beacon_registry
for update
to anon
using (true)
with check (true);

create policy "allow anon insert test_sessions"
on public.test_sessions
for insert
to anon
with check (true);

create policy "allow anon select test_sessions"
on public.test_sessions
for select
to anon
using (true);

create policy "allow anon insert session_media"
on public.session_media
for insert
to anon
with check (true);

create policy "allow anon select session_media"
on public.session_media
for select
to anon
using (true);
