-- V1 security hardening. Apply after the initial schema and the super-admin
-- migration. It preserves all rows and routes sensitive writes through the
-- existing SECURITY DEFINER RPCs, where every business rule is validated.

-- A venue manager may operate bookings, but must not be able to grant another
-- account manager-level access by writing a membership row directly.
drop policy if exists "memberships managed by managers"
  on public.venue_memberships;
drop policy if exists "memberships visible to relevant staff"
  on public.venue_memberships;

create policy "memberships visible to member or super admin"
  on public.venue_memberships
  for select to authenticated
  using (
    profile_id = auth.uid()
    or public.is_platform_super_admin()
  );

revoke all on public.venue_memberships from anon;
revoke insert, update, delete on public.venue_memberships from authenticated;
grant select on public.venue_memberships to authenticated;

-- The booking API validates ownership, price, hours, capacity and overlap.
-- Direct table mutations bypass those safeguards, so client roles may only
-- read rows allowed by RLS and must invoke the approved RPCs to mutate them.
revoke all on public.bookings from anon;
revoke insert, update, delete on public.bookings from authenticated;
grant select on public.bookings to authenticated;
