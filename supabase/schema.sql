-- Human Rights Museum App remote sync schema
create extension if not exists pgcrypto;

insert into storage.buckets (id, name, public)
select 'error-attachments', 'error-attachments', true
where not exists (
  select 1 from storage.buckets where id = 'error-attachments'
);

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

create table if not exists public.action_segments (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  session_id uuid not null references public.test_sessions(id) on delete cascade,
  action_type text not null,
  started_at timestamptz not null default now(),
  ended_at timestamptz,
  target_distance_m double precision,
  target_heading_deg double precision,
  expected_behavior text,
  operator_confirmed boolean default false,
  metadata_json jsonb default '{}'::jsonb
);

create table if not exists public.sensor_samples (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  session_id uuid not null references public.test_sessions(id) on delete cascade,
  segment_id uuid references public.action_segments(id) on delete set null,
  sample_time timestamptz not null default now(),
  gps_lat double precision,
  gps_lng double precision,
  gps_accuracy double precision,
  gps_speed double precision,
  accel_x double precision,
  accel_y double precision,
  accel_z double precision,
  gyro_x double precision,
  gyro_y double precision,
  gyro_z double precision,
  mag_x double precision,
  mag_y double precision,
  mag_z double precision,
  heading double precision,
  ble_visible_count integer,
  ble_top_beacons jsonb default '[]'::jsonb,
  camera_tracking_state text,
  camera_feature_score double precision,
  metadata_json jsonb default '{}'::jsonb
);

create table if not exists public.user_feedback (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  session_id uuid not null references public.test_sessions(id) on delete cascade,
  segment_id uuid references public.action_segments(id) on delete set null,
  feedback_type text not null,
  value text not null,
  comment text,
  metadata_json jsonb default '{}'::jsonb
);

create table if not exists public.ground_truth_points (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  session_id uuid not null references public.test_sessions(id) on delete cascade,
  segment_id uuid references public.action_segments(id) on delete set null,
  point_label text not null,
  map_x double precision,
  map_y double precision,
  map_z double precision,
  heading_deg double precision,
  source text not null,
  metadata_json jsonb default '{}'::jsonb
);

create table if not exists public.derived_metrics (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  session_id uuid not null references public.test_sessions(id) on delete cascade,
  position_error_m double precision,
  heading_error_deg double precision,
  ble_rssi_variance double precision,
  imu_drift_score double precision,
  compass_interference_score double precision,
  camera_relocalization_success_rate double precision,
  sensor_confidence_curve jsonb default '[]'::jsonb,
  metadata_json jsonb default '{}'::jsonb
);

alter table public.app_errors enable row level security;
alter table public.beacon_registry enable row level security;
alter table public.test_sessions enable row level security;
alter table public.session_media enable row level security;
alter table public.action_segments enable row level security;
alter table public.sensor_samples enable row level security;
alter table public.user_feedback enable row level security;
alter table public.ground_truth_points enable row level security;
alter table public.derived_metrics enable row level security;

drop policy if exists "allow anon insert app_errors" on public.app_errors;
create policy "allow anon insert app_errors"
on public.app_errors
for insert
to anon
with check (true);

drop policy if exists "allow anon select beacon_registry" on public.beacon_registry;
create policy "allow anon select beacon_registry"
on public.beacon_registry
for select
to anon
using (true);

drop policy if exists "allow anon insert beacon_registry" on public.beacon_registry;
create policy "allow anon insert beacon_registry"
on public.beacon_registry
for insert
to anon
with check (true);

drop policy if exists "allow anon update beacon_registry" on public.beacon_registry;
create policy "allow anon update beacon_registry"
on public.beacon_registry
for update
to anon
using (true)
with check (true);

drop policy if exists "allow anon delete beacon_registry" on public.beacon_registry;
create policy "allow anon delete beacon_registry"
on public.beacon_registry
for delete
to anon
using (true);

drop policy if exists "allow anon insert test_sessions" on public.test_sessions;
create policy "allow anon insert test_sessions"
on public.test_sessions
for insert
to anon
with check (true);

drop policy if exists "allow anon select test_sessions" on public.test_sessions;
create policy "allow anon select test_sessions"
on public.test_sessions
for select
to anon
using (true);

drop policy if exists "allow anon insert session_media" on public.session_media;
create policy "allow anon insert session_media"
on public.session_media
for insert
to anon
with check (true);

drop policy if exists "allow anon select session_media" on public.session_media;
create policy "allow anon select session_media"
on public.session_media
for select
to anon
using (true);

drop policy if exists "allow anon insert action_segments" on public.action_segments;
create policy "allow anon insert action_segments"
on public.action_segments
for insert
to anon
with check (true);

drop policy if exists "allow anon update action_segments" on public.action_segments;
create policy "allow anon update action_segments"
on public.action_segments
for update
to anon
using (true)
with check (true);

drop policy if exists "allow anon select action_segments" on public.action_segments;
create policy "allow anon select action_segments"
on public.action_segments
for select
to anon
using (true);

drop policy if exists "allow anon insert sensor_samples" on public.sensor_samples;
create policy "allow anon insert sensor_samples"
on public.sensor_samples
for insert
to anon
with check (true);

drop policy if exists "allow anon select sensor_samples" on public.sensor_samples;
create policy "allow anon select sensor_samples"
on public.sensor_samples
for select
to anon
using (true);

drop policy if exists "allow anon insert user_feedback" on public.user_feedback;
create policy "allow anon insert user_feedback"
on public.user_feedback
for insert
to anon
with check (true);

drop policy if exists "allow anon select user_feedback" on public.user_feedback;
create policy "allow anon select user_feedback"
on public.user_feedback
for select
to anon
using (true);

drop policy if exists "allow anon insert ground_truth_points" on public.ground_truth_points;
create policy "allow anon insert ground_truth_points"
on public.ground_truth_points
for insert
to anon
with check (true);

drop policy if exists "allow anon select ground_truth_points" on public.ground_truth_points;
create policy "allow anon select ground_truth_points"
on public.ground_truth_points
for select
to anon
using (true);

drop policy if exists "allow anon insert derived_metrics" on public.derived_metrics;
create policy "allow anon insert derived_metrics"
on public.derived_metrics
for insert
to anon
with check (true);

drop policy if exists "allow anon select derived_metrics" on public.derived_metrics;
create policy "allow anon select derived_metrics"
on public.derived_metrics
for select
to anon
using (true);

drop policy if exists "allow anon insert error_attachments" on storage.objects;
create policy "allow anon insert error_attachments"
on storage.objects
for insert
to anon
with check (bucket_id = 'error-attachments');

drop policy if exists "allow anon select error_attachments" on storage.objects;
create policy "allow anon select error_attachments"
on storage.objects
for select
to anon
using (bucket_id = 'error-attachments');
