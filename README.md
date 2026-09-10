# Soccer Booking App

Flutter application for football playground booking, with player and manager
experiences in Egyptian Arabic.

## Run With Docker

Docker builds the Flutter Web application and serves it through Nginx. It lets
the same release run on any computer or server with Docker installed.

```text
docker compose up --build
```

Open `http://localhost:8080`.

To use another port, create a local `.env` from `.env.example` and set:

```text
APP_PORT=8080
SUPABASE_URL=<project-url>
SUPABASE_ANON_KEY=<public-anon-or-publishable-key>
```

Do not commit `.env`, and never use a Supabase `service_role` key in Flutter,
Docker build arguments, browser bundles, or Git.

## Open From Anywhere

Docker makes the release portable but does not publish it to the internet by
itself. To make it publicly available, run the same `docker compose up -d
--build` command on a VPS or cloud host, then configure a domain, HTTPS reverse
proxy, and firewall for port 443. Keep the host's `.env` outside Git.

## Quality Checks

```text
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

The Supabase schema and security setup are documented in `supabase/README.md`.
