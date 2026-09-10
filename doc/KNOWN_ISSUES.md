# Known Issues

## Current Limitations
- No real backend connection yet. A staging Supabase schema and RLS foundation
  are prepared, but no project, credentials, SDK, or persistent repository is connected.
- Using mock data initially.
- No payment integration yet.
- Financial analytics uses mock booking totals and booking statuses, not payment receipts, refunds, taxes, discounts, or cash-reconciliation records.
- In-app mock notifications are available, but no push, SMS, WhatsApp, or scheduled background delivery is connected.
- Google and email/password contracts are prepared, but no authentication provider, email sender, account persistence, password hashing, or password-reset delivery is connected.
- Booking confirmation reserves a QR payload and UI location, but does not render or scan a QR code yet.
- Notification toggles are stored in mock memory only; no push, SMS, WhatsApp, scheduled reminder, or marketing message is sent.
- Field allocation, recurring bookings, permissions, and match results are mock in-memory data. A real backend must enforce concurrent booking rules and persist all updates.
- The current admin route guard is a mock client-side session boundary, not production authorization. Google or email/password sign-in must resolve an approved server-side role, and backend policies must deny player access to every admin resource.
- Slot watching updates inside the current mock process after booking activity. Supabase Realtime or a WebSocket backend must supply cross-device updates and server-side booking locks before live multi-user use.
- Venue settings, field allocation, and slot availability are mock/in-memory. The active mock slot repository now reflects booking capacity, but a backend must persist and enforce the same source of truth across devices.
- Flutter SDK is available at `F:\Apps\flutter-sdk`, but its `bin` folder is not in `PATH`; the project currently invokes it by absolute path.
- Android emulators are listed by Flutter, but the attempted `Pixel_7` launch remained `offline`; a manual Android app run could not be completed. Resolve emulator boot/ADB readiness before Android release validation.
- The supported Chrome launch reached the Flutter debug-service connection wait during this session, but the tool session did not receive a completed connection confirmation; repeat an interactive Chrome run before release validation.
