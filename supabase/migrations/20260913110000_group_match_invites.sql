-- Group-match invitations. Apply after the initial booking foundation migration.
-- Invite tokens are never stored in plaintext: the Flutter client receives one
-- only from a future booking RPC, while this schema stores its SHA-256 hash.

create type public.match_participation_status as enum (
  'invited',
  'going',
  'not_going'
);

create table public.matches (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null unique references public.bookings (id) on delete cascade,
  organizer_id uuid not null references public.profiles (id) on delete restrict,
  player_capacity smallint not null default 10 check (player_capacity between 2 and 30),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.match_invites (
  match_id uuid primary key references public.matches (id) on delete cascade,
  token_hash text not null unique check (char_length(token_hash) = 64),
  expires_at timestamptz not null,
  revoked_at timestamptz,
  created_at timestamptz not null default now(),
  check (expires_at > created_at)
);

create table public.match_participants (
  match_id uuid not null references public.matches (id) on delete cascade,
  profile_id uuid not null references public.profiles (id) on delete cascade,
  status public.match_participation_status not null default 'invited',
  responded_at timestamptz,
  created_at timestamptz not null default now(),
  primary key (match_id, profile_id),
  check ((status = 'invited' and responded_at is null) or status <> 'invited')
);

create index match_participants_match_status_idx
  on public.match_participants (match_id, status);

create or replace function public.can_read_match(target_match_id uuid)
returns boolean
language sql
stable
security definer set search_path = public
as $$
  select exists (
    select 1
    from public.matches match
    join public.bookings booking on booking.id = match.booking_id
    where match.id = target_match_id
      and (
        match.organizer_id = auth.uid()
        or public.is_venue_staff(booking.venue_id)
        or exists (
          select 1
          from public.match_participants participant
          where participant.match_id = match.id
            and participant.profile_id = auth.uid()
        )
      )
  );
$$;

alter table public.matches enable row level security;
alter table public.match_invites enable row level security;
alter table public.match_participants enable row level security;

create policy "matches readable by organizer participant or staff" on public.matches
  for select to authenticated using (public.can_read_match(id));
create policy "participants readable by match audience" on public.match_participants
  for select to authenticated using (public.can_read_match(match_id));

-- Token hashes are not readable from the client. Creation and revocation are
-- server-side operations owned by future SECURITY DEFINER booking RPCs.
revoke all on public.matches from anon, authenticated;
revoke all on public.match_invites from anon, authenticated;
revoke all on public.match_participants from anon, authenticated;
grant select on public.matches to authenticated;
grant select on public.match_participants to authenticated;

-- Safe unauthenticated preview for a holder of the high-entropy invite link.
-- It deliberately returns no phone number, e-mail, roster, or user identifier.
create or replace function public.get_match_invite_summary(p_invite_token text)
returns table (
  booking_reference text,
  starts_at timestamptz,
  ends_at timestamptz,
  venue_name text,
  player_capacity smallint,
  going_count bigint
)
language sql
stable
security definer set search_path = public
as $$
  select
    booking.reference,
    booking.starts_at,
    booking.ends_at,
    venue.name,
    match.player_capacity,
    count(participant.profile_id) filter (where participant.status = 'going')
  from public.match_invites invite
  join public.matches match on match.id = invite.match_id
  join public.bookings booking on booking.id = match.booking_id
  join public.venues venue on venue.id = booking.venue_id
  left join public.match_participants participant on participant.match_id = match.id
  where invite.token_hash = encode(digest(p_invite_token, 'sha256'), 'hex')
    and invite.revoked_at is null
    and invite.expires_at > now()
  group by booking.reference, booking.starts_at, booking.ends_at, venue.name, match.player_capacity;
$$;

-- Serializing on the match row prevents two simultaneous RSVP requests from
-- taking the final remaining place. A future RPC creates the invite and adds
-- the organizer as going in the same booking transaction.
create or replace function public.respond_to_match_invite(
  p_invite_token text,
  p_status public.match_participation_status
)
returns table (
  match_id uuid,
  response_status public.match_participation_status,
  going_count bigint,
  player_capacity smallint
)
language plpgsql
security definer set search_path = public
as $$
declare
  v_match_id uuid;
  v_capacity smallint;
  v_current_status public.match_participation_status;
  v_going_count bigint;
begin
  if auth.uid() is null then
    raise exception 'Authentication is required.' using errcode = '28000';
  end if;
  if p_status not in ('going', 'not_going') then
    raise exception 'Only going or not_going is allowed.' using errcode = '22023';
  end if;

  select match.id, match.player_capacity
    into v_match_id, v_capacity
  from public.match_invites invite
  join public.matches match on match.id = invite.match_id
  where invite.token_hash = encode(digest(p_invite_token, 'sha256'), 'hex')
    and invite.revoked_at is null
    and invite.expires_at > now()
  for update of match;

  if v_match_id is null then
    raise exception 'Invite is invalid or expired.' using errcode = 'P0001';
  end if;

  select participant.status
    into v_current_status
  from public.match_participants participant
  where participant.match_id = v_match_id and participant.profile_id = auth.uid();

  if p_status = 'going' and coalesce(v_current_status::text, '') <> 'going' then
    select count(*) into v_going_count
    from public.match_participants participant
    where participant.match_id = v_match_id and participant.status = 'going';
    if v_going_count >= v_capacity then
      raise exception 'Match is full.' using errcode = 'P0001';
    end if;
  end if;

  insert into public.match_participants (match_id, profile_id, status, responded_at)
  values (v_match_id, auth.uid(), p_status, now())
  on conflict (match_id, profile_id) do update
    set status = excluded.status, responded_at = excluded.responded_at;

  update public.matches set updated_at = now() where id = v_match_id;

  select count(*) into v_going_count
  from public.match_participants participant
  where participant.match_id = v_match_id and participant.status = 'going';

  return query select v_match_id, p_status, v_going_count, v_capacity;
end;
$$;

grant execute on function public.get_match_invite_summary(text) to anon, authenticated;
grant execute on function public.respond_to_match_invite(text, public.match_participation_status)
  to authenticated;
