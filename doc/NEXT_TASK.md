# Next Task

## Task
- Apply the V1 Staging security migration, then replace mock staff operations
  with an RLS/RPC-backed repository before public-release testing.

## Requirements
- Read `SPECKIT.md`, `WORKFLOW_LOG.md`, and `DECISIONS_LOG.md` before any future work.
- Read `doc/V1_AUDIT_2026-09-29.md` and resolve its Critical and High findings
  before treating the application as a public V1 candidate.
- Take a verified Staging backup, then apply pending migrations in timestamp
  order: overnight operating hours, unbounded booking dates/update-cancel,
  then `20260929100000_harden_direct_write_paths.sql`. Do not apply them to a
  production project without a rehearsal and rollback plan.
- Preserve the Flutter/Dart-only application and the domain repository contracts.
- The configured Supabase Project URL was resumed and resolves in DNS. Verify
  the full browser return/session path before treating authentication as ready.
- Preserve the local contract that carries the active player's identity into a
  booking, but let Supabase derive the final identity from `auth.uid()` rather
  than trusting a client-supplied player ID.
- Preserve the explicit saved-session continuation and sign-out/change-account
  actions when replacing the mock entry flow with production navigation.
- The initial booking and group-match migrations are reported as applied and
  their RLS/function inventory was checked. Do not rerun them.
- Review and apply
  `supabase/migrations/20260913143000_admin_email_invitations.sql` once to
  Staging. Seed a venue, fields, and one authorized manager using a controlled
  administrative process before testing the UI against it.
- After that migration, review and apply
  `supabase/migrations/20260921130000_super_admin_staff_management.sql`. Use a
  controlled Supabase server-side process to assign exactly one existing,
  verified Google profile the `super_admin` platform role; never expose a
  client button, service-role key, or e-mail-based self-promotion path.
- Implement and test a RLS/RPC-backed `StaffRepository` against the selected
  venue before claiming invitations, phone records, permission changes, or
  revocations are persistent.
- Apply `supabase/migrations/20260921140000_allow_overnight_venue_hours.sql`
  once to Staging before persisting a venue schedule that closes after
  midnight, such as 15:00 to 02:00. Do not modify the already-applied initial
  migration; this additive migration replaces its old closing-hour constraint.
- Apply `supabase/migrations/20260929090000_remove_booking_horizon.sql` once
  to Staging. It removes the temporary 90-day server cap and supplies the
  authenticated manager update/cancel RPCs. Then validate tomorrow, a later
  day this month, the first day of next month, and a date several months ahead
  with two accounts attempting the same slot.
- Test a pending invitation, a case-insensitive matching Google e-mail, a
  non-invited player denial, a revoked invitation, permission updates, and the
  inability to create a `super_admin` account from the client.
- Do not connect a production project without a backup, explicit approval, and
  a completed staging rehearsal. Never place a service-role key in Flutter.
- Do not add a payment provider without separately approved payment scope.
- OTP, QR generation/scanning, push delivery, and reminder scheduling require
  approved service providers and a backend implementation. Marketing for open
  slots requires separate player opt-in.
- After any future completed change set, verify it, commit it, and push it to `origin/main`; record the commit hash and outcome in `WORKFLOW_LOG.md`.

## Expected Output
- A verified e-mail-to-membership promotion path and a Supabase staff
  repository bound to a selected venue, without exposing any service-role key.
