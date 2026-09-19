# ==============================================================================
# Stage 1: Build Flutter Web Release
# ==============================================================================
FROM ghcr.io/cirruslabs/flutter:3.29.0 AS builder

WORKDIR /app

# Cache dependencies
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copy source code and compile web release
COPY . .
RUN flutter build web --release --pwa-strategy=none

# ==============================================================================
# Stage 2: High-Performance Lightweight Nginx Server
# ==============================================================================
FROM nginx:alpine

# Copy custom Nginx SPA configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy compiled Flutter web assets
COPY --from=builder /app/build/web /usr/share/nginx/html

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
