# Decisions Log

## Current Decisions
- Ball is included by default and is not an optional service.
- Optional services are limited to drinks, photography, and referee.
- MVP excludes notifications.
- MVP uses basic or manual payment.
- Only two user roles exist: player and admin.
- Flutter and Dart are the only active implementation stack; legacy React Native references are obsolete.
- Mock repositories are required before any real Supabase integration.
- All user-facing application copy must use Egyptian Arabic, with right-to-left layout and Arabic-Egypt locale settings.
- The player slot picker shows a seven-day week. Matching bookings are assigned to the first free field among fields 1-3 by the repository; a real backend must enforce the same rule atomically.
- Tentative and recurring bookings, staff permissions, and notification preferences are supported in mock mode. OTP delivery, QR rendering/scanning, and push delivery are intentionally not connected.
- The operational week starts on Saturday. The admin starts on a weekly availability summary, opens a day for its available hours, and manages existing bookings from a separate management section.
- GitHub versioning is mandatory for every completed user-requested change set: verify, commit with a descriptive message, push to `origin/main`, and record the resulting commit in the workflow log. Generated builds, local logs, and secrets must remain excluded.
- Flutter is the active UI layer: RTL is implemented through Flutter directionality and directional layout APIs, not CSS. Shared navigation uses a left-facing, Arabic-labelled back action. Slot repositories expose a watch stream so a future Supabase/WebSocket implementation can publish live availability.
- An admin registers a player from a specific available hour, instead of manually re-entering that hour. The reception flow requires a player or group name and phone number, lets the admin choose `مؤكد` or `مبدئي`, and delegates identical-field allocation to the booking repository.
- The admin registration form separates booking state from repetition intent: `مؤكد` or `مبدئي` applies to a one-off booking, while `ثابت` records the booking as recurring in the existing mock domain. `لمرة` keeps the selected state for one appointment.
- Admin day selection uses one shared Arabic calendar control in quick/fixed booking and booking editing. In mock mode it is constrained to the operational Saturday-to-Friday week; backend scheduling will later supply the valid date range.
- The public entry screen is player-only and offers Google or email/password choices, with no role selector and no SMS cost. The interface is mock-only until a real provider verifies the account and returns its role.
- Venue settings are isolated in a repository: configurable field count and opening/closing hours drive the admin occupancy dashboard, day availability, and quick bookings. Lowering capacity is rejected when an existing booking uses a now-removed field.
- The visual system uses an emerald football-club palette with a restrained warm accent, strong summary cards for player availability and admin occupancy, and shared component theming. Arabic labels and booking states remain the primary way to communicate meaning; color is supportive rather than the only signal.
- The public entry point is player-only and does not expose an admin-role switch. Admin access has a separate route and is guarded by the active role; an authoritative backend must later enforce the same rule for every API request and database policy.
- Admin accounts are invitation-only: no self-service admin registration exists. A future owner-managed backend must create an invitation, assign a venue-specific role, and reject any identity not granted that role.
