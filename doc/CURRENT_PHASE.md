# Current Phase

## Phase
- Google authentication, venue setup, shared slot availability, and secure one-off booking RPCs are now present in Supabase staging. The Flutter adapters are wired locally and await a successful rebuild and end-to-end browser verification.

## Current Focus
- The approved Supabase staging project has the booking and group-match schema,
  RLS verification, Google provider, and local redirect URLs configured.
- The Flutter client can start Google OAuth from runtime-only configuration, and
  the resumed Staging host now resolves. Complete a manual Edge or Chrome
  Google-sign-in/returned-session check before relying on it operationally.
- A restored Google session now requires an explicit `كمل للتطبيق` action or a
  visible sign-out/change-account choice; root screens no longer show a
  non-functional back action.
- The UI distinguishes super-admin from ordinary admin. Team invitations,
  mobile contact details, permission changes, and revocation are super-admin
  only in the client; the corresponding RLS/RPC migration is pending.
- Restored Google sessions are now available at the admin entry route, so a
  verified super-admin can explicitly continue to the administration dashboard.
- Operating schedules support an overnight operational day: for example,
  3:00 PM to 2:00 AM is an 11-hour shift and the post-midnight hours belong to
  the day that began the shift. The Supabase constraint migration is pending.
- A local authenticated player can create a mock booking and see it in
  `حجوزاتي` during the same app session. Persistence remains the next backend
  milestone.
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
- Super-admin team management adds an Egyptian mobile number and revocation;
  no client path creates or promotes a super-admin.

## Next
- Record successful Google OAuth redirect acceptance, then replace mock staff,
  booking, slot, and match repositories incrementally only
  after the RLS/RPC acceptance checks pass. Do not use a service-role key in
  Flutter or add a payment provider.
- Fix the Android Kotlin cache/environment issue and create a protected release
  signing configuration before producing a distributable Android build.
