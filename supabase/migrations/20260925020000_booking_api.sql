-- Authenticated booking API. No caller may provide an owner ID or stored price.
begin;

create function public.soccer_slots(p_venue_id uuid, p_day date)
returns table(starts_at timestamptz, ends_at timestamptz, available_fields bigint, price_cents integer)
language plpgsql security definer set search_path=public
as $$
begin
  if auth.uid() is null then raise exception 'Sign in required.' using errcode='42501'; end if;
  if p_day is null or p_day < (now() at time zone 'Africa/Cairo')::date
    or p_day > (now() at time zone 'Africa/Cairo')::date + 90 then
    raise exception 'Invalid booking day.' using errcode='22023';
  end if;
  return query
    with hours as (
      select (p_day + make_interval(hours=>v.opening_hour) + make_interval(hours=>h))
          at time zone 'Africa/Cairo' as start_time
      from public.venues v,
        lateral generate_series(0,(v.closing_hour-v.opening_hour+24)%24-1) h
      where v.id=p_venue_id
    )
    select h.start_time, h.start_time+interval '1 hour',
      count(f.id) filter (where not exists (
        select 1 from public.bookings b where b.field_id=f.id and b.status<>'cancelled'
        and tstzrange(b.starts_at,b.ends_at,'[)') && tstzrange(h.start_time,h.start_time+interval '1 hour','[)')
      )), min(f.hourly_price_cents)
    from hours h join public.fields f on f.venue_id=p_venue_id and f.is_active
    where h.start_time>now()
    group by h.start_time order by h.start_time;
end;
$$;

create function public.soccer_create_booking(
  p_venue_id uuid, p_starts_at timestamptz, p_service_ids uuid[],
  p_expected_total_cents integer,
  p_admin boolean default false, p_player_name text default null,
  p_player_phone text default null, p_status public.booking_status default 'confirmed'
) returns jsonb
language plpgsql security definer set search_path=public
as $$
declare
  v_venue public.venues;
  v_field public.fields;
  v_booking public.bookings;
  v_name text;
  v_phone text;
  v_services jsonb;
  v_services_cost integer;
  v_services_count integer;
  v_local timestamp;
begin
  if auth.uid() is null then raise exception 'Sign in required.' using errcode='42501'; end if;
  if p_admin is null or p_service_ids is null or p_expected_total_cents is null then
    raise exception 'Invalid request.' using errcode='22023';
  end if;
  if p_admin and not (
    public.is_platform_super_admin() or exists (
      select 1 from public.venue_memberships m where m.venue_id=p_venue_id
      and m.profile_id=auth.uid() and m.can_create_bookings
    )
  ) then raise exception 'Booking permission required.' using errcode='42501'; end if;
  if p_status is null or p_status not in ('tentative','confirmed')
    or (not p_admin and p_status<>'confirmed') then
    raise exception 'Recurring bookings require a separate scheduling workflow.' using errcode='22023';
  end if;
  select * into v_venue from public.venues where id=p_venue_id for update;
  if not found then raise exception 'Venue not found.' using errcode='22023'; end if;
  v_local := p_starts_at at time zone 'Africa/Cairo';
  if p_starts_at is null or p_starts_at<=now() or p_starts_at>now()+interval '90 days'
    or date_trunc('hour',v_local)<>v_local
    or ((extract(hour from v_local)::int-v_venue.opening_hour+24)%24)
      >= ((v_venue.closing_hour-v_venue.opening_hour+24)%24) then
    raise exception 'Slot outside operating hours.' using errcode='22023';
  end if;
  select * into v_field from public.fields f where f.venue_id=p_venue_id and f.is_active
    and not exists (select 1 from public.bookings b where b.field_id=f.id and b.status<>'cancelled'
      and tstzrange(b.starts_at,b.ends_at,'[)') && tstzrange(p_starts_at,p_starts_at+interval '1 hour','[)'))
    order by f.sort_order limit 1 for update;
  if not found then raise exception 'Slot is fully booked.' using errcode='P0001'; end if;
  select count(*), coalesce(sum(s.price_cents),0),
    coalesce(jsonb_agg(jsonb_build_object('id',s.id,'name',s.name,'price_cents',s.price_cents)),'[]')
    into v_services_count,v_services_cost,v_services
    from public.optional_services s where s.venue_id=p_venue_id and s.is_active and s.id=any(p_service_ids);
  if v_services_count<>cardinality(p_service_ids) then
    raise exception 'Invalid or duplicate services.' using errcode='22023';
  end if;
  if p_expected_total_cents<>v_field.hourly_price_cents+v_services_cost then
    raise exception 'Prices changed. Review the booking again.' using errcode='22023';
  end if;
  select full_name,phone_number into v_name,v_phone from public.profiles where id=auth.uid();
  if v_name is null then raise exception 'Profile required.' using errcode='42501'; end if;
  if p_admin then
    v_name:=btrim(p_player_name); v_phone:=btrim(p_player_phone);
    if v_name is null or length(v_name) not between 2 and 80
      or v_phone is null or v_phone !~ '^01[0125][0-9]{8}$' then
      raise exception 'Player name and Egyptian phone required.' using errcode='22023';
    end if;
  end if;
  insert into public.bookings(venue_id,field_id,player_id,player_name,player_phone,
    starts_at,ends_at,status,base_price_cents,services,total_price_cents)
    values(p_venue_id,v_field.id,auth.uid(),v_name,v_phone,p_starts_at,p_starts_at+interval '1 hour',
      p_status,v_field.hourly_price_cents,v_services,v_field.hourly_price_cents+v_services_cost)
    returning * into v_booking;
  return to_jsonb(v_booking)||jsonb_build_object('field_number',v_field.sort_order);
end;
$$;

revoke all on function public.soccer_slots(uuid,date) from public,anon;
revoke all on function public.soccer_create_booking(uuid,timestamptz,uuid[],integer,boolean,text,text,public.booking_status) from public,anon;
grant execute on function public.soccer_slots(uuid,date) to authenticated;
grant execute on function public.soccer_create_booking(uuid,timestamptz,uuid[],integer,boolean,text,text,public.booking_status) to authenticated;
commit;
