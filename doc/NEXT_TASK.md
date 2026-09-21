# Next Task

## Task
- Verify the active Supabase Project URL and Google OAuth return flow, then
  connect the first RLS-backed slot and booking repository to the selected
  venue.

## Requirements
- Read `SPECKIT.md`, `WORKFLOW_LOG.md`, and `DECISIONS_LOG.md` before any future work.
- Preserve the Flutter/Dart-only application and the domain repository contracts.
- Do not retry OAuth until the configured Supabase Project URL resolves in DNS
  and the browser can load its `/auth/v1/authorize` endpoint.
- The initial booking and group-match migrations are reported as applied and
  their RLS/function inventory was checked. Do not rerun them.
- Review and apply
  `supabase/migrations/20260913143000_admin_email_invitations.sql` once to
  Staging. Seed a venue, fields, and one authorized manager using a controlled
  administrative process before testing the UI against it.
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
