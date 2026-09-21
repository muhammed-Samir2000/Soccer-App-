# Current Phase

## Phase
- Google authentication and the first two Supabase staging migrations are in place; authenticated booking, RSVP, and staff repositories remain pending.

## Current Focus
- Release readiness is blocked by an invalid or inactive configured Staging
  Project URL. Verify it from Supabase before attempting Google OAuth again.
- The approved Supabase staging project has the booking and group-match schema,
  RLS verification, Google provider, and local redirect URLs configured.
- The Flutter client can start Google OAuth from runtime-only configuration.
  The live Edge preview is running at the configured local return URL; complete
  one manual Google sign-in and profile/session check before relying on it
  operationally.
- Staff invitations are implemented in mock UI and a new backend migration is
  checked in. The migration must be applied before a real manager can grant an
  invited Google account venue access.

## Completed
- Product, scope, and player-flow documentation.
- Execution-ready Flutter SPECKIT with phase prompts.
- Append-only workflow log and handoff process.
- Phase 0: Flutter project, theme, central routing, launch screen, smoke test, and Web launch verification.
- Phase 1: mock role entry, slot models/repository, availability UI, and booking-summary route.
- Phase 2: booking draft, included ball, optional services, domain pricing, and payment handoff.
- Phase 3: mock manual payment, booking repository, reference creation, and final confirmation.
- Phase 4: shared booking repository and basic admin bookings list.
- Phase 5: repository dependency boundaries, secret-free Supabase configuration placeholder, error/empty states, and MVP quality gate.
- Product extension: full week selector, player bookings and results, field grid, recurring/tentative booking tools, permissions, and notification preferences.
- Supabase preparation: staging schema, RLS policies, role/membership model,
  overlap prevention, and security test checklist.
- Supabase client initialization through runtime-only Dart defines; mock
  repositories remain active until authenticated adapters are verified.
- Group match flow: organizer creates a shareable invitation from a confirmed
  booking; teammates respond `جاي` or `مش جاي`; capacity is configurable and
  never changes the validity of the original booking.
- Google entry uses the standard outlined, multi-colour Google treatment and
  explains that the password is entered only on Google's official page.
- Admin team management now records an e-mail invitation, venue role, three
  permissions, and pending/active invitation state in mock mode.

## Next
- Verify the active Supabase Project URL and successful Google OAuth redirect.
- Replace mock staff, booking, slot, and match repositories incrementally only
  after the RLS/RPC acceptance checks pass. Do not use a service-role key in
  Flutter or add a payment provider.
- Fix the Android Kotlin cache/environment issue and create a protected release
  signing configuration before producing a distributable Android build.
