-- Persistent team invitations and post-match results. Apply after the initial
-- booking, group-match, and direct-write-hardening migrations. This migration
-- neither exposes invite hashes nor gives Flutter direct write access.

create or replace function public.soccer_get_booking_match(
  p_booking_reference text
)
returns jsonb
language plpgsql
security definer set search_path = public
as $$
declare
  v_booking public.bookings;
  v_match public.matches;
begin
  if auth.uid() is null then
    raise exception 'Authentication required.' using errcode = '42501';
  end if;

  select * into v_booking
  from public.bookings
  where reference = p_booking_reference and status <> 'cancelled';
  if not found then
    raise exception 'Booking not found.' using errcode = 'P0001';
  end if;
  if v_booking.player_id <> auth.uid()
    and not public.is_venue_staff(v_booking.venue_id) then
    raise exception 'Match permission required.' using errcode = '42501';
  end if;

  select * into v_match
  from public.matches
  where booking_id = v_booking.id;
  if not found then
    return null;
  end if;

  return (
    select jsonb_build_object(
      'booking_reference', v_booking.reference,
      'organizer_id', v_match.organizer_id,
      'organizer_name', organizer.full_name,
      'starts_at', v_booking.starts_at,
      'ends_at', v_booking.ends_at,
      'field_number', field.sort_order,
      'player_capacity', v_match.player_capacity,
      'going_count', (
        select count(*) from public.match_participants participant
        where participant.match_id = v_match.id
          and participant.status = 'going'
      ),
      'participants', coalesce((
        select jsonb_agg(
          jsonb_build_object(
            'player_id', participant.profile_id,
            'display_name', participant_profile.full_name,
            'status', participant.status,
            'is_organizer', participant.profile_id = v_match.organizer_id
          ) order by participant.created_at
        )
        from public.match_participants participant
        join public.profiles participant_profile
          on participant_profile.id = participant.profile_id
        where participant.match_id = v_match.id
      ), '[]'::jsonb)
    )
    from public.profiles organizer
    join public.fields field on field.id = v_booking.field_id
    where organizer.id = v_match.organizer_id
  );
end;
$$;

create or replace function public.soccer_create_match_invite(
  p_booking_reference text,
  p_player_capacity smallint default 10
)
returns jsonb
language plpgsql
security definer set search_path = public
as $$
declare
  v_booking public.bookings;
  v_match public.matches;
  v_token text;
  v_result jsonb;
begin
  if auth.uid() is null then
    raise exception 'Authentication required.' using errcode = '42501';
  end if;
  if p_player_capacity is null or p_player_capacity not between 2 and 30 then
    raise exception 'Invalid player capacity.' using errcode = '22023';
  end if;

  select * into v_booking
  from public.bookings
  where reference = p_booking_reference and status <> 'cancelled'
  for update;
  if not found then
    raise exception 'Booking not found.' using errcode = 'P0001';
  end if;
  if v_booking.player_id <> auth.uid() then
    raise exception 'Match permission required.' using errcode = '42501';
  end if;
  if v_booking.status not in ('confirmed', 'recurring')
    or v_booking.starts_at <= now() then
    raise exception 'Only future confirmed bookings can invite a team.'
      using errcode = '22023';
  end if;

  insert into public.matches (booking_id, organizer_id, player_capacity)
  values (v_booking.id, v_booking.player_id, p_player_capacity)
  on conflict (booking_id) do update
    set player_capacity = excluded.player_capacity,
        updated_at = now()
  returning * into v_match;

  insert into public.match_participants (
    match_id, profile_id, status, responded_at
  ) values (
    v_match.id, v_booking.player_id, 'going', now()
  ) on conflict (match_id, profile_id) do update
    set status = 'going', responded_at = now();

  -- The raw token leaves this function once. A deliberate refresh revokes the
  -- previous link; simply opening the organizer screen never rotates a link.
  v_token := encode(gen_random_bytes(32), 'hex');
  insert into public.match_invites (match_id, token_hash, expires_at, revoked_at)
  values (
    v_match.id,
    encode(digest(v_token, 'sha256'), 'hex'),
    v_booking.starts_at,
    null
  ) on conflict (match_id) do update
    set token_hash = excluded.token_hash,
        expires_at = excluded.expires_at,
        revoked_at = null;

  select public.soccer_get_booking_match(p_booking_reference)
    into v_result;
  return v_result || jsonb_build_object('invite_token', v_token);
end;
$$;

-- This preview is deliberately safe for the holder of a high-entropy link.
-- It contains no phone number, e-mail, account identifier, or team roster.
create or replace function public.soccer_get_match_invite_preview(
  p_invite_token text
)
returns jsonb
language sql
stable
security definer set search_path = public
as $$
  select jsonb_build_object(
    'booking_reference', booking.reference,
    'organizer_name', organizer.full_name,
    'starts_at', booking.starts_at,
    'ends_at', booking.ends_at,
    'field_number', field.sort_order,
    'player_capacity', match.player_capacity,
    'going_count', count(participant.profile_id) filter (
      where participant.status = 'going'
    )
  )
  from public.match_invites invite
  join public.matches match on match.id = invite.match_id
  join public.bookings booking on booking.id = match.booking_id
  join public.fields field on field.id = booking.field_id
  join public.profiles organizer on organizer.id = match.organizer_id
  left join public.match_participants participant on participant.match_id = match.id
  where invite.token_hash = encode(digest(p_invite_token, 'sha256'), 'hex')
    and invite.revoked_at is null
    and invite.expires_at > now()
  group by booking.reference, organizer.full_name, booking.starts_at,
    booking.ends_at, field.sort_order, match.player_capacity;
$$;

-- Keep the older two-argument response RPC for backwards compatibility and
-- add the application-specific overload that validates the public display
-- name the invitee wants the organizer to see.
create or replace function public.soccer_respond_to_match_invite(
  p_invite_token text,
  p_status public.match_participation_status,
  p_display_name text
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
    raise exception 'Authentication required.' using errcode = '42501';
  end if;
  if p_status not in ('going', 'not_going') then
    raise exception 'Only going or not_going is allowed.' using errcode = '22023';
  end if;
  if coalesce(char_length(btrim(p_display_name)), 0) not between 2 and 80 then
    raise exception 'Invalid display name.' using errcode = '22023';
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

  select participant.status into v_current_status
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

  update public.profiles
  set full_name = btrim(p_display_name), updated_at = now()
  where id = auth.uid();
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

create or replace function public.soccer_save_match_result(
  p_booking_reference text,
  p_winning_team text,
  p_man_of_the_match text,
  p_man_of_the_match_description text default '',
  p_best_goal text default '',
  p_best_goal_description text default ''
)
returns jsonb
language plpgsql
security definer set search_path = public
as $$
declare
  v_booking public.bookings;
begin
  if auth.uid() is null then
    raise exception 'Authentication required.' using errcode = '42501';
  end if;
  select * into v_booking
  from public.bookings
  where reference = p_booking_reference and status <> 'cancelled'
  for update;
  if not found or v_booking.player_id <> auth.uid() then
    raise exception 'Match result permission required.' using errcode = '42501';
  end if;
  if v_booking.ends_at + interval '1 hour' > now() then
    raise exception 'Result is available one hour after the match ends.'
      using errcode = '22023';
  end if;
  if coalesce(char_length(btrim(p_winning_team)), 0) not between 2 and 80
    or coalesce(char_length(btrim(p_man_of_the_match)), 0) not between 2 and 80
    or (
      coalesce(char_length(btrim(p_best_goal)), 0) > 0
      and coalesce(char_length(btrim(p_best_goal)), 0) not between 2 and 80
    )
    or coalesce(char_length(btrim(p_man_of_the_match_description)), 0) > 250
    or coalesce(char_length(btrim(p_best_goal_description)), 0) > 250 then
    raise exception 'Invalid match result.' using errcode = '22023';
  end if;

  update public.bookings
  set match_result = jsonb_build_object(
        'winning_team', btrim(p_winning_team),
        'man_of_the_match', btrim(p_man_of_the_match),
        'man_of_the_match_description', btrim(p_man_of_the_match_description),
        'best_goal', btrim(p_best_goal),
        'best_goal_description', btrim(p_best_goal_description)
      ),
      updated_at = now()
  where id = v_booking.id
  returning * into v_booking;
  return to_jsonb(v_booking);
end;
$$;

revoke all on function public.soccer_get_booking_match(text) from public, anon;
revoke all on function public.soccer_create_match_invite(text, smallint) from public, anon;
revoke all on function public.soccer_get_match_invite_preview(text) from public;
revoke all on function public.soccer_respond_to_match_invite(
  text, public.match_participation_status, text
) from public, anon;
revoke all on function public.soccer_save_match_result(
  text, text, text, text, text, text
) from public, anon;

grant execute on function public.soccer_get_booking_match(text) to authenticated;
grant execute on function public.soccer_create_match_invite(text, smallint)
  to authenticated;
grant execute on function public.soccer_get_match_invite_preview(text)
  to anon, authenticated;
grant execute on function public.soccer_respond_to_match_invite(
  text, public.match_participation_status, text
) to authenticated;
grant execute on function public.soccer_save_match_result(
  text, text, text, text, text, text
) to authenticated;
