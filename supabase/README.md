# Supabase Foundation

## Status

This folder prepares the application for an approved Supabase staging project.
It does not connect the Flutter app, contain credentials, or create a live
project.

## Apply The Migration

1. Create a separate Supabase **staging** project, not a production project.
2. In SQL Editor, apply `migrations/20260910170000_initial_booking_schema.sql`.
3. Create the first owner account through the approved authentication flow.
4. Using the Supabase dashboard with a service-role-only administrative process,
   promote that profile to `super_admin`. Never expose the service role key to
   Flutter or commit it to this repository.
5. Create a venue, its fields, active services, and staff memberships.
6. Run the RLS test checklist before connecting the Flutter client.

## Required Security Checks

- A player can read only their own rows in `bookings`.
- A player cannot insert or update `bookings` directly.
- A reception employee can only manage bookings for their assigned venue and
  only when their permission is enabled.
- A manager cannot manage another venue's fields, services, memberships, or
  bookings.
- Only a service-role administrative workflow can promote a `super_admin`.
- Two simultaneous requests for the same field/time are rejected by the
  exclusion constraint.

## Flutter Connection Gate

Only after this migration, RLS checks, credentials, and user approval are
complete should the next phase add `supabase_flutter` and repository
implementations. Supply public runtime values only with:

```text
flutter run --dart-define=SUPABASE_URL=<project-url> --dart-define=SUPABASE_ANON_KEY=<anon-key>
```

The anon key is public by design, but all authorization must be enforced by RLS.
The service-role key must never be included in Flutter, browser bundles, logs,
or Git.
