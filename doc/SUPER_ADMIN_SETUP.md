# Super Admin Setup

## Purpose

This is a one-time, controlled bootstrap for the first platform owner. It is
not an application feature and must not be delegated to a public client button.

## Safe Order

1. Apply the foundation migration, the admin e-mail invitation migration, and
   `20260921130000_super_admin_staff_management.sql` to Staging in order.
2. Sign in once with the intended owner's Google account so `auth.users` and
   `public.profiles` contain that verified identity.
3. In the Supabase SQL Editor, as a trusted project administrator, inspect the
   exact profile ID for that account. Never select by a client-supplied e-mail
   or copy a service-role key into Flutter.
4. Promote only that exact UUID to `super_admin` in a reviewed, one-off server
   operation. Record who approved it and when.
5. Sign out and back in through Google. The profile should now expose the
   super-admin-only team action.
6. Test an invitation, permission edit, revocation, non-invited Google user,
   and ordinary admin denial before enabling the live staff repository.

## Release Guard

Do not use the team screen for real access control until the migration is
applied and the Flutter staff repository calls its RPCs. The current UI is a
mock preview and does not persist invitations or revoke a real account.
