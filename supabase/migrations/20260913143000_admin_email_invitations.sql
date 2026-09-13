-- Venue managers invite a known Google e-mail before that person signs in.
-- This file contains no account addresses or project-specific configuration.

create type public.admin_invitation_status as enum (
  'pending',
  'accepted',
  'revoked'
);

create table public.admin_email_invitations (
  id uuid primary key default gen_random_uuid(),
  venue_id uuid not null references public.venues (id) on delete cascade,
  email text not null check (
    email = lower(btrim(email))
    and char_length(email) between 3 and 254
    and position('@' in email) > 1
  ),
  role public.venue_role not null default 'reception',
  can_create_bookings boolean not null default true,
  can_edit_bookings boolean not null default true,
  can_view_financial_reports boolean not null default false,
  status public.admin_invitation_status not null default 'pending',
  invited_by uuid not null references public.profiles (id) on delete restrict,
  invited_at timestamptz not null default now(),
  accepted_at timestamptz,
  revoked_at timestamptz,
  check (
    (status = 'pending' and accepted_at is null and revoked_at is null)
    or (status = 'accepted' and accepted_at is not null and revoked_at is null)
    or (status = 'revoked' and revoked_at is not null)
  )
);

create unique index admin_email_invitations_venue_email_idx
  on public.admin_email_invitations (venue_id, lower(email));

create index admin_email_invitations_pending_email_idx
  on public.admin_email_invitations (lower(email))
  where status = 'pending';

alter table public.admin_email_invitations enable row level security;

revoke all on public.admin_email_invitations from anon, authenticated;
grant select, insert, update on public.admin_email_invitations to authenticated;

create policy "admin invitations visible to venue managers"
  on public.admin_email_invitations
  for select to authenticated
  using (public.can_manage_venue(venue_id));

create policy "admin invitations created by venue managers"
  on public.admin_email_invitations
  for insert to authenticated
  with check (
    public.can_manage_venue(venue_id)
    and invited_by = auth.uid()
    and status = 'pending'
  );

create policy "admin invitations updated by venue managers"
  on public.admin_email_invitations
  for update to authenticated
  using (public.can_manage_venue(venue_id))
  with check (public.can_manage_venue(venue_id));

-- A user can never choose their own platform role from the Flutter client.
-- On a successful Google session, this RPC consumes only pending invitations
-- whose normalized e-mail exactly matches the signed Auth JWT claim.
create or replace function public.accept_admin_email_invitation()
returns table (
  accepted_venue_id uuid,
  accepted_role public.venue_role
)
language plpgsql
security definer set search_path = public
as $$
declare
  v_email text;
  v_invitation public.admin_email_invitations%rowtype;
begin
  if auth.uid() is null then
    raise exception 'Authentication is required.' using errcode = '28000';
  end if;

  v_email := lower(btrim(coalesce(auth.jwt() ->> 'email', '')));
  if v_email = '' then
    raise exception 'An e-mail identity is required.' using errcode = '22023';
  end if;

  for v_invitation in
    select *
    from public.admin_email_invitations
    where email = v_email and status = 'pending'
    for update
  loop
    insert into public.venue_memberships (
      venue_id,
      profile_id,
      role,
      can_create_bookings,
      can_edit_bookings,
      can_view_financial_reports
    )
    values (
      v_invitation.venue_id,
      auth.uid(),
      v_invitation.role,
      v_invitation.can_create_bookings,
      v_invitation.can_edit_bookings,
      v_invitation.can_view_financial_reports
    )
    on conflict (venue_id, profile_id) do update
      set role = excluded.role,
          can_create_bookings = excluded.can_create_bookings,
          can_edit_bookings = excluded.can_edit_bookings,
          can_view_financial_reports = excluded.can_view_financial_reports;

    update public.profiles
      set platform_role = case
            when platform_role = 'player' then 'admin'::public.platform_role
            else platform_role
          end,
          updated_at = now()
      where id = auth.uid();

    update public.admin_email_invitations
      set status = 'accepted', accepted_at = now()
      where id = v_invitation.id;

    accepted_venue_id := v_invitation.venue_id;
    accepted_role := v_invitation.role;
    return next;
  end loop;
end;
$$;

grant execute on function public.accept_admin_email_invitation() to authenticated;
