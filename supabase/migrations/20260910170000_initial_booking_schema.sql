-- Football playground booking foundation. Apply only to an approved Supabase
-- staging project. This migration contains no project URL, key, or account data.

create extension if not exists pgcrypto;
create extension if not exists btree_gist;

create type public.platform_role as enum ('player', 'admin', 'super_admin');
create type public.venue_role as enum ('manager', 'reception');
create type public.booking_status as enum ('tentative', 'confirmed', 'recurring', 'cancelled');

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name text not null check (char_length(trim(full_name)) between 2 and 80),
  phone_number text,
  platform_role public.platform_role not null default 'player',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.venues (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(trim(name)) between 2 and 100),
  opening_hour smallint not null check (opening_hour between 0 and 23),
  closing_hour smallint not null check (closing_hour between 1 and 24 and closing_hour > opening_hour),
  created_at timestamptz not null default now()
);

create table public.venue_memberships (
  venue_id uuid not null references public.venues (id) on delete cascade,
  profile_id uuid not null references public.profiles (id) on delete cascade,
  role public.venue_role not null,
  can_create_bookings boolean not null default false,
  can_edit_bookings boolean not null default false,
  can_view_financial_reports boolean not null default false,
  created_at timestamptz not null default now(),
  primary key (venue_id, profile_id)
);

create table public.fields (
  id uuid primary key default gen_random_uuid(),
  venue_id uuid not null references public.venues (id) on delete cascade,
  name text not null check (char_length(trim(name)) between 2 and 60),
  sort_order smallint not null check (sort_order > 0),
  hourly_price_cents integer not null check (hourly_price_cents >= 0),
  is_active boolean not null default true,
  unique (venue_id, sort_order)
);

create table public.optional_services (
  id uuid primary key default gen_random_uuid(),
  venue_id uuid not null references public.venues (id) on delete cascade,
  name text not null check (char_length(trim(name)) between 2 and 80),
  price_cents integer not null check (price_cents >= 0),
  is_active boolean not null default true,
  unique (venue_id, name)
);

create table public.bookings (
  id uuid primary key default gen_random_uuid(),
  reference text not null unique default ('HAGZ-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8))),
  venue_id uuid not null references public.venues (id) on delete restrict,
  field_id uuid not null references public.fields (id) on delete restrict,
  player_id uuid not null references public.profiles (id) on delete restrict,
  player_name text not null check (char_length(trim(player_name)) between 2 and 80),
  player_phone text,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  status public.booking_status not null default 'tentative',
  base_price_cents integer not null check (base_price_cents >= 0),
  services jsonb not null default '[]'::jsonb,
  total_price_cents integer not null check (total_price_cents >= 0),
  match_result jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (ends_at > starts_at),
  check (jsonb_typeof(services) = 'array')
);

-- A field cannot have overlapping active bookings. A cancelled booking frees it.
alter table public.bookings
  add constraint bookings_no_overlapping_active_field
  exclude using gist (
    field_id with =,
    tstzrange(starts_at, ends_at, '[)') with &&
  ) where (status in ('tentative', 'confirmed', 'recurring'));

create index bookings_player_starts_at_idx on public.bookings (player_id, starts_at desc);
create index bookings_venue_starts_at_idx on public.bookings (venue_id, starts_at);
create index fields_venue_active_idx on public.fields (venue_id, is_active, sort_order);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, full_name)
  values (
    new.id,
    coalesce(nullif(trim(new.raw_user_meta_data ->> 'full_name'), ''), 'لاعب جديد')
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

create or replace function public.is_venue_staff(target_venue_id uuid)
returns boolean
language sql
stable
security definer set search_path = public
as $$
  select exists (
    select 1
    from public.venue_memberships membership
    where membership.venue_id = target_venue_id
      and membership.profile_id = auth.uid()
  ) or exists (
    select 1 from public.profiles profile
    where profile.id = auth.uid() and profile.platform_role = 'super_admin'
  );
$$;

create or replace function public.can_manage_venue(target_venue_id uuid)
returns boolean
language sql
stable
security definer set search_path = public
as $$
  select exists (
    select 1
    from public.venue_memberships membership
    where membership.venue_id = target_venue_id
      and membership.profile_id = auth.uid()
      and membership.role = 'manager'
  ) or exists (
    select 1 from public.profiles profile
    where profile.id = auth.uid() and profile.platform_role = 'super_admin'
  );
$$;

create or replace function public.can_edit_bookings(target_venue_id uuid)
returns boolean
language sql
stable
security definer set search_path = public
as $$
  select exists (
    select 1
    from public.venue_memberships membership
    where membership.venue_id = target_venue_id
      and membership.profile_id = auth.uid()
      and membership.can_edit_bookings
  ) or exists (
    select 1 from public.profiles profile
    where profile.id = auth.uid() and profile.platform_role = 'super_admin'
  );
$$;

alter table public.profiles enable row level security;
alter table public.venues enable row level security;
alter table public.venue_memberships enable row level security;
alter table public.fields enable row level security;
alter table public.optional_services enable row level security;
alter table public.bookings enable row level security;

create policy "profiles readable by owner" on public.profiles
  for select to authenticated using (id = auth.uid());
create policy "profiles editable by owner" on public.profiles
  for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

revoke all on public.profiles from authenticated;
grant select on public.profiles to authenticated;
grant update (full_name, phone_number) on public.profiles to authenticated;

create policy "venues readable by authenticated users" on public.venues
  for select to authenticated using (true);
create policy "venues managed by managers" on public.venues
  for update to authenticated using (public.can_manage_venue(id)) with check (public.can_manage_venue(id));

create policy "memberships visible to relevant staff" on public.venue_memberships
  for select to authenticated using (profile_id = auth.uid() or public.can_manage_venue(venue_id));
create policy "memberships managed by managers" on public.venue_memberships
  for all to authenticated using (public.can_manage_venue(venue_id)) with check (public.can_manage_venue(venue_id));

create policy "fields readable by authenticated users" on public.fields
  for select to authenticated using (true);
create policy "fields managed by venue managers" on public.fields
  for all to authenticated using (public.can_manage_venue(venue_id)) with check (public.can_manage_venue(venue_id));

create policy "services readable by authenticated users" on public.optional_services
  for select to authenticated using (true);
create policy "services managed by venue managers" on public.optional_services
  for all to authenticated using (public.can_manage_venue(venue_id)) with check (public.can_manage_venue(venue_id));

create policy "bookings readable by player or staff" on public.bookings
  for select to authenticated using (player_id = auth.uid() or public.is_venue_staff(venue_id));
create policy "bookings editable by authorized staff" on public.bookings
  for update to authenticated using (
    public.is_venue_staff(venue_id)
    and public.can_edit_bookings(venue_id)
  ) with check (public.is_venue_staff(venue_id));

-- Do not grant direct booking creation to players. The approved next migration
-- must expose a SECURITY DEFINER RPC that validates price, services, hours,
-- field capacity, and the authenticated player before inserting a booking.
revoke insert on public.bookings from anon, authenticated;
