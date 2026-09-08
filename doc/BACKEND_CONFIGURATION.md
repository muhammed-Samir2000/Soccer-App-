# Backend Configuration

## Current State

The MVP runs entirely with mock repositories. It does not connect to Supabase
or any other backend.

## Future Supabase Setup

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

No backend integration, schema, authentication provider, or payment provider
may be introduced without an approved backend scope.
