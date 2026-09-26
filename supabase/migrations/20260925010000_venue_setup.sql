-- First-run venue setup. Reviewed separately from previously applied migrations.
-- Existing accounts/roles are never changed by this migration.
begin;

create function public.save_soccer_venue(
  p_venue_id uuid, p_name text, p_field_count integer,
  p_hourly_price_cents integer, p_opening_hour integer, p_closing_hour integer
) returns uuid
language plpgsql security definer set search_path = public
as $$
declare
  v_id uuid;
begin
  if auth.uid() is null or not public.is_platform_super_admin() then
    raise exception 'Only the existing super admin may configure the venue.' using errcode = '42501';
  end if;
  if p_name is null or length(btrim(p_name)) not between 2 and 100
    or p_field_count is null or p_field_count not between 1 and 12
    or p_hourly_price_cents is null or p_hourly_price_cents not between 100 and 10000000
    or p_hourly_price_cents % 100 <> 0
    or p_opening_hour is null or p_opening_hour not between 0 and 23
    or p_closing_hour is null or p_closing_hour not between 0 and 23
    or p_opening_hour = p_closing_hour then
    raise exception 'Invalid venue settings.' using errcode = '22023';
  end if;
  -- Serialize setup requests and prevent duplicate first-run submissions.
  perform pg_advisory_xact_lock(25092501);
  if p_venue_id is null then
    if exists(select 1 from public.venues) then
      raise exception 'Venue already configured. Reload before editing.' using errcode = '22023';
    end if;
    insert into public.venues(name, opening_hour, closing_hour)
    values(btrim(p_name), p_opening_hour, p_closing_hour) returning id into v_id;
  else
    select id into v_id from public.venues where id=p_venue_id for update;
    if v_id is null then raise exception 'Venue not found.' using errcode = '22023'; end if;
    -- Do not hide fields or change opening hours under active future bookings.
    if exists (
      select 1 from public.bookings b join public.fields f on f.id=b.field_id
      where b.venue_id=v_id and b.status<>'cancelled' and b.ends_at>now()
        and (f.sort_order>p_field_count or
          ((extract(hour from b.starts_at at time zone 'Africa/Cairo')::int-p_opening_hour+24)%24)
          >= ((p_closing_hour-p_opening_hour+24)%24))
    ) then raise exception 'Settings conflict with existing future bookings.' using errcode = '22023'; end if;
    update public.venues set name=btrim(p_name), opening_hour=p_opening_hour,
      closing_hour=p_closing_hour where id=v_id;
  end if;
  insert into public.fields(venue_id,name,sort_order,hourly_price_cents,is_active)
    select v_id, 'ملعب '||n, n, p_hourly_price_cents, true
    from generate_series(1,p_field_count) n
    on conflict(venue_id,sort_order) do update
      set hourly_price_cents=excluded.hourly_price_cents,is_active=true;
  update public.fields set is_active=false where venue_id=v_id and sort_order>p_field_count;
  return v_id;
end;
$$;

revoke all on function public.save_soccer_venue(uuid,text,integer,integer,integer,integer) from public, anon;
grant execute on function public.save_soccer_venue(uuid,text,integer,integer,integer,integer) to authenticated;
commit;
