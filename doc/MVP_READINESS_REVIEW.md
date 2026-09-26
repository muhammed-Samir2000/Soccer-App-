# MVP readiness review — 2026-09-25

Status: initial review and UI corrections; not a completed live MVP.

## Evidence

- Reviewed active requirements, phase status, decisions, next task, known issues,
  backend configuration, player flow, and repository wiring.
- Opened the running admin login and dashboard. Admin entry still explicitly
  uses demo access; the deployed bundle predates the changes below.
- AppDependencies.fromBackend replaces authentication only. Booking, slots,
  matches, staff, settings and notifications remain in-memory mock repositories.
- Player slots are a fixed sample list rather than the operating schedule used
  by the administration screens. These must share one authoritative schedule.
- Finance derives totals from booking status; there are no payment receipts.
- The project folder is a ZIP extraction without a project .git directory.

## Changes in this review

- Payment screen now describes cash payment at the venue and confirms the
  booking without claiming that cash was collected.
- Payment content scrolls on small screens instead of relying on fixed spacers.
- Confirmation asks the player to retain the reference, replacing unfinished QR
  implementation copy, and clarifies that confirmation is not a receipt.
- Financial labels describe booking value rather than collected funds.
- Occupancy copy refers to the displayed period rather than a week when the
  dashboard actually displays the remaining month.
- Existing widget expectations updated for the revised labels and scrollable
  payment action.

## Required for a shared live MVP

1. Confirm the target staging project and venue; inspect existing migrations
   before applying any pending changes. Never rerun reported applied migrations.
2. Verify Google return/session flow and server-owned administrative membership.
3. Implement persistent venue, slot and booking adapters with server-side
   ownership, pricing and atomic overlap checks.
4. Replace mock staff and match functionality or explicitly defer these screens.
5. Remove demo access from live builds only once authenticated access is working.
6. Verify two-device booking, refresh persistence, conflict rejection, permission
   denial, overnight scheduling, cancellation and error recovery.

## Validation limitations

- Docker client exists but this agent session receives permission denied on the
  Docker Engine named pipe. No rebuild or runtime test of these edits completed.
- Flutter/Dart were not found in PATH or at the SDK path recorded in Known Issues.
- Source review is not a substitute for flutter analyze and flutter test.
- No database connection, migration, remote push or deployment performed.
- The owner has been asked whether the intended first release is shared across
  devices with Supabase or local to one device. Persistence implementation awaits
  that choice; local browser storage must not be presented as shared persistence.
