# Next Task

## Task
- Apply the approved Supabase staging migration and validate RLS before adding
  authenticated Supabase repository adapters or replacing mock repositories.

## Requirements
- Read `SPECKIT.md`, `WORKFLOW_LOG.md`, and `DECISIONS_LOG.md` before any future work.
- Preserve the Flutter/Dart-only application and the domain repository contracts.
- Apply `supabase/migrations/20260910170000_initial_booking_schema.sql` only
  to the approved staging project and complete `supabase/README.md` checks.
- Do not connect Supabase without explicit public runtime credentials, approved
  data scope, and user approval.
- Do not add a payment provider without separately approved payment scope.
- OTP, QR generation/scanning, and notification delivery require approved service providers and a backend implementation.
- After any future completed change set, verify it, commit it, and push it to `origin/main`; record the commit hash and outcome in `WORKFLOW_LOG.md`.

## Expected Output
- Confirmed RLS results and an approved prompt to implement authenticated
  Supabase repository adapters.
