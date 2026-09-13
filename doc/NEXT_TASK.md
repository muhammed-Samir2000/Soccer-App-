# Next Task

## Task
- Create a staging Supabase project, configure Google OAuth redirect URLs, and
  validate the booking and group-match invitation migrations before adding
  authenticated Supabase repository adapters.

## Requirements
- Read `SPECKIT.md`, `WORKFLOW_LOG.md`, and `DECISIONS_LOG.md` before any future work.
- Preserve the Flutter/Dart-only application and the domain repository contracts.
- Apply `supabase/migrations/20260910170000_initial_booking_schema.sql` and
  `supabase/migrations/20260913110000_group_match_invites.sql` only to the
  approved staging project. Test token expiry, revocation, anonymous preview,
  authenticated RSVP, capacity race handling, and every RLS policy.
- Do not connect a production project without a backup, explicit approval, and
  a completed staging rehearsal. Never place a service-role key in Flutter.
- Do not add a payment provider without separately approved payment scope.
- OTP, QR generation/scanning, push delivery, and reminder scheduling require
  approved service providers and a backend implementation. Marketing for open
  slots requires separate player opt-in.
- After any future completed change set, verify it, commit it, and push it to `origin/main`; record the commit hash and outcome in `WORKFLOW_LOG.md`.

## Expected Output
- Confirmed Auth/OAuth and RLS results, then an approved prompt to implement
  authenticated Supabase repository adapters and transactional notifications.
