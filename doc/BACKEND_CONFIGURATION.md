# Backend Configuration

## Current State

The MVP runs entirely with mock repositories. It does not connect to Supabase
or any other backend.

## Supabase Foundation

The secure staging schema and row-level security foundation are prepared in
`supabase/migrations/20260910170000_initial_booking_schema.sql`. Apply it only
to an approved staging project, then follow `supabase/README.md` before adding
the Supabase Flutter SDK.

## Future Flutter Connection

After backend scope, credentials, and approval are provided, pass these values
at build time only. Do not commit values in source files, documentation, or
version control.

```text
flutter run --dart-define=SUPABASE_URL=<approved-project-url> --dart-define=SUPABASE_ANON_KEY=<approved-anon-key>
```

`BackendConfiguration` reads those two runtime values. A future Supabase
repository should implement the existing domain repository interfaces and be
provided through `AppDependencies`; screens must not import a Supabase SDK or
construct backend repositories directly.

## Scope Gate

No live backend connection, authentication provider, or payment provider may
be introduced without approved credentials and user approval.
