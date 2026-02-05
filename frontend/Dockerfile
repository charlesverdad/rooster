# Build stage
FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /app

# Copy Flutter project
COPY rooster_app/ ./

# Get dependencies
RUN flutter pub get

# Build argument for API URL
ARG API_BASE_URL=http://localhost:8000/api

# Build web release
# CRITICAL: --pwa-strategy none prevents Flutter from generating its own
# flutter_service_worker.js which would replace our custom service-worker.js
# and break push notifications (accept/decline actions, silent API calls).
RUN flutter build web --release --pwa-strategy none --dart-define=API_BASE_URL=${API_BASE_URL}

# Production stage
FROM nginx:alpine

# Copy built web app
COPY --from=builder /app/build/web /usr/share/nginx/html

# Copy nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
