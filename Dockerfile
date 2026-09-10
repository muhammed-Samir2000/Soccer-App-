# syntax=docker/dockerfile:1

# Keep the Flutter image aligned with the SDK used by this project.
ARG FLUTTER_IMAGE=ghcr.io/cirruslabs/flutter:3.47.2
FROM ${FLUTTER_IMAGE} AS build

WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .

# These are optional public web-client values. Do not provide a service-role key.
ARG SUPABASE_URL=""
ARG SUPABASE_ANON_KEY=""
RUN flutter build web --release \
    --dart-define=SUPABASE_URL=${SUPABASE_URL} \
    --dart-define=SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY}

FROM nginx:1.27-alpine AS runtime

COPY docker/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD wget -q -O /dev/null http://127.0.0.1/ || exit 1
