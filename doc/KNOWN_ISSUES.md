# Known Issues

## Current Limitations
- `flutter build apk --release` currently fails in Kotlin incremental-cache
  cleanup because the project is on `F:` while cached pub packages are on `C:`.
  Android release signing is also configured with a debug key and is not safe
  for distribution.
- The Codex embedded browser does not render Flutter Canvas reliably. Use a
  full Edge or Chrome window for local web acceptance tests.
- Google OAuth is configured for the resumed Staging project and its client
  adapter exists, but a complete manual Google sign-in and returned-session
  verification still needs to be recorded. Booking, RSVP, settings,
  notification, and staff data still use mock repositories.
- Using mock data initially.
- No payment integration yet.
- Financial analytics uses mock booking totals and booking statuses, not payment receipts, refunds, taxes, discounts, or cash-reconciliation records.
- In-app mock notifications are available, but no push, SMS, WhatsApp, or scheduled background delivery is connected.
- Google authentication is available only when runtime Staging configuration is
  supplied. Email/password registration, password reset, and all notification
  delivery remain intentionally unimplemented.
- Booking confirmation reserves a QR payload and UI location, but does not render or scan a QR code yet.
- Notification toggles are stored in mock memory only; no push, SMS, WhatsApp, scheduled reminder, or marketing message is sent.
- Field allocation, recurring bookings, permissions, and match results are mock in-memory data. A real backend must enforce concurrent booking rules and persist all updates.
- The current admin route guard is a mock client-side session boundary, not production authorization. Google or email/password sign-in must resolve an approved server-side role, and backend policies must deny player access to every admin resource.
- Slot watching updates inside the current mock process after booking activity. Supabase Realtime or a WebSocket backend must supply cross-device updates and server-side booking locks before live multi-user use.
- Venue settings, field allocation, and slot availability are mock/in-memory. The active mock slot repository now reflects booking capacity, but a backend must persist and enforce the same source of truth across devices.
- Google-authenticated player identity now labels a newly created mock booking
  and makes it visible in `حجوزاتي` during the current app session only. A
  refresh, another browser, or another device still loses the booking until an
  authenticated Supabase booking repository and server-side booking RPC exist.
- Flutter SDK is available at `F:\Apps\flutter-sdk`, but its `bin` folder is not in `PATH`; the project currently invokes it by absolute path.
- Android emulators are listed by Flutter, but the attempted `Pixel_7` launch remained `offline`; a manual Android app run could not be completed. Resolve emulator boot/ADB readiness before Android release validation.
- The live Edge preview now connects to Flutter and initializes Supabase, but a
  complete manual Google sign-in and returned-session check is still required
  before authentication can pass its release gate.
- A copied demo invitation can open in a fresh local browser tab, but its RSVP
  data is mock/in-memory. A refresh, another browser, or another device cannot
  see an attendee's response until authenticated Supabase repositories replace
  `MockMatchRepository`.
- The production group-invite migration is checked in but not applied. Google
  OAuth, real invitation-token issuance, token revocation, waitlist behavior,
  push reminders, and notification-consent enforcement remain backend work.
- The admin-team UI records e-mail invitations in mock memory for the current
  release. `20260913143000_admin_email_invitations.sql` is not yet reported as
  applied; until it is and a Supabase staff repository is connected, inviting a
  real e-mail will not grant production access.
