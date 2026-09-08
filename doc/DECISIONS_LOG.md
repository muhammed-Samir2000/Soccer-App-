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
