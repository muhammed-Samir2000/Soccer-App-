-- Super-admin-only staff administration. Apply after
-- 20260913143000_admin_email_invitations.sql on Staging, then rehearse it
-- with a non-production venue before enabling a live Flutter repository.
-- No account e-mail, phone number, URL, or credential belongs in this file.

alter table public.admin_email_invitations
  add column if not exists phone_number text;

alter table public.admin_email_invitations
  drop constraint if exists admin_email_invitations_phone_number_check;

alter table public.admin_email_invitations
  add constraint admin_email_invitations_phone_number_check
  check (
    phone_number is null
    or phone_number ~ '^01[0125][0-9]{8}$'
  );

create or replace function public.is_platform_super_admin()
returns boolean
language sql
stable
security definer set search_path = public
as $$
  select exists (
    select 1
    from public.profiles profile
    where profile.id = auth.uid()
      and profile.platform_role = 'super_admin'
  );
$$;

revoke all on function public.is_platform_super_admin() from public;
grant execute on function public.is_platform_super_admin() to authenticated;

-- Venue managers can still operate their venue, but only the platform owner
-- can see contact details or change who may enter any admin area.
drop policy if exists "admin invitations visible to venue managers"
  on public.admin_email_invitations;
drop policy if exists "admin invitations created by venue managers"
  on public.admin_email_invitations;
drop policy if exists "admin invitations updated by venue managers"
  on public.admin_email_invitations;

create policy "admin invitations visible to super admins"
  on public.admin_email_invitations
  for select to authenticated
  using (public.is_platform_super_admin());

-- Mutations happen only through the RPCs below. This avoids client-selected
-- ownership and keeps the accepted/revoked state transitions controlled.
revoke insert, update, delete on public.admin_email_invitations from authenticated;

create or replace function public.invite_venue_admin(
  p_venue_id uuid,
  p_email text,
  p_phone_number text,
  p_role public.venue_role,
  p_can_create_bookings boolean,
  p_can_edit_bookings boolean,
  p_can_view_financial_reports boolean
)
returns public.admin_email_invitations
language plpgsql
security definer set search_path = public
as $$
declare
  v_email text := lower(btrim(p_email));
  v_phone text := btrim(p_phone_number);
  v_invitation public.admin_email_invitations;
begin
  if auth.uid() is null or not public.is_platform_super_admin() then
    raise exception 'Super-admin access is required.' using errcode = '42501';
  end if;
  if v_email !~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$' then
    raise exception 'A valid e-mail is required.' using errcode = '22023';
  end if;
  if v_phone !~ '^01[0125][0-9]{8}$' then
    raise exception 'A valid Egyptian mobile number is required.' using errcode = '22023';
  end if;

  insert into public.admin_email_invitations (
    venue_id, email, phone_number, role, can_create_bookings,
    can_edit_bookings, can_view_financial_reports, status, invited_by
  ) values (
    p_venue_id, v_email, v_phone, p_role, p_can_create_bookings,
    p_can_edit_bookings, p_can_view_financial_reports, 'pending', auth.uid()
  )
  returning * into v_invitation;
  return v_invitation;
end;
$$;

create or replace function public.update_venue_admin_invitation(
  p_invitation_id uuid,
  p_role public.venue_role,
  p_can_create_bookings boolean,
  p_can_edit_bookings boolean,
  p_can_view_financial_reports boolean
)
returns public.admin_email_invitations
language plpgsql
security definer set search_path = public
as $$
declare v_invitation public.admin_email_invitations;
begin
  if auth.uid() is null or not public.is_platform_super_admin() then
    raise exception 'Super-admin access is required.' using errcode = '42501';
  end if;
  update public.admin_email_invitations
    set role = p_role,
        can_create_bookings = p_can_create_bookings,
        can_edit_bookings = p_can_edit_bookings,
        can_view_financial_reports = p_can_view_financial_reports
    where id = p_invitation_id and status in ('pending', 'accepted')
    returning * into v_invitation;
  if v_invitation.id is null then
    raise exception 'Invitation was not found or was revoked.' using errcode = 'P0001';
  end if;
  if v_invitation.status = 'accepted' then
    update public.venue_memberships membership
      set role = v_invitation.role,
          can_create_bookings = v_invitation.can_create_bookings,
          can_edit_bookings = v_invitation.can_edit_bookings,
          can_view_financial_reports = v_invitation.can_view_financial_reports
      from auth.users auth_user
      where auth_user.id = membership.profile_id
        and membership.venue_id = v_invitation.venue_id
        and lower(auth_user.email) = v_invitation.email;
  end if;
  return v_invitation;
end;
$$;

create or replace function public.revoke_venue_admin_invitation(
  p_invitation_id uuid
)
returns void
language plpgsql
security definer set search_path = public
as $$
begin
  if auth.uid() is null or not public.is_platform_super_admin() then
    raise exception 'Super-admin access is required.' using errcode = '42501';
  end if;
  update public.admin_email_invitations
    set status = 'revoked', revoked_at = now()
    where id = p_invitation_id and status in ('pending', 'accepted');
  if not found then
    raise exception 'Invitation was not found or already revoked.' using errcode = 'P0001';
  end if;
  delete from public.venue_memberships membership
    using public.admin_email_invitations invitation, auth.users auth_user
    where invitation.id = p_invitation_id
      and membership.venue_id = invitation.venue_id
      and membership.profile_id = auth_user.id
      and lower(auth_user.email) = invitation.email;
  update public.profiles profile
    set platform_role = 'player', updated_at = now()
    from auth.users auth_user
    where profile.id = auth_user.id
      and lower(auth_user.email) = (
        select email from public.admin_email_invitations where id = p_invitation_id
      )
      and profile.platform_role = 'admin'
      and not exists (
        select 1 from public.venue_memberships membership
        where membership.profile_id = profile.id
      );
end;
$$;

grant execute on function public.invite_venue_admin(
  uuid, text, text, public.venue_role, boolean, boolean, boolean
) to authenticated;
grant execute on function public.update_venue_admin_invitation(
  uuid, public.venue_role, boolean, boolean, boolean
) to authenticated;
grant execute on function public.revoke_venue_admin_invitation(uuid)
  to authenticated;
