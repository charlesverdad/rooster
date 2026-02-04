# Rooster Development Commands
# Run `just` to see all available commands

# Show available commands
default:
    @just --list

# --- Setup ---

# First-time setup: install deps + git hooks
setup: install-hooks
    cd backend && uv sync
    cd frontend/rooster_app && flutter pub get

# Install git pre-commit hooks
install-hooks:
    cp scripts/pre-commit .git/hooks/pre-commit
    chmod +x .git/hooks/pre-commit

# --- Database ---

# Start PostgreSQL (uses shell.nix shellHook functions)
db-start:
    @bash -c 'source <(grep -A10 "start_db()" shell.nix | sed "s/^    //" | head -8); start_db'

# Stop PostgreSQL
db-stop:
    @bash -c 'source <(grep -A6 "stop_db()" shell.nix | sed "s/^    //" | head -6); stop_db'

# Run database migrations
db-migrate:
    cd backend && uv run alembic upgrade head

# Create a new migration (usage: just db-migration "description")
db-migration name:
    cd backend && uv run alembic revision --autogenerate -m "{{name}}"

# --- Dev Servers ---

# Run backend dev server
backend:
    cd backend && uv run uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# Run frontend dev server
frontend:
    cd frontend/rooster_app && flutter run -d chrome

# Run both backend and frontend
dev:
    #!/usr/bin/env bash
    set -euo pipefail
    trap 'kill $(jobs -p) 2>/dev/null' EXIT
    just backend &
    sleep 3
    just frontend

# --- Lint & Format ---

# Lint backend (ruff)
lint-backend:
    cd backend && uv run ruff check .

# Format backend (ruff)
fmt-backend:
    cd backend && uv run ruff format .

# Lint frontend (flutter analyze)
lint-frontend:
    cd frontend/rooster_app && flutter analyze

# Format frontend (dart)
fmt-frontend:
    cd frontend/rooster_app && dart format .

# Lint everything
lint: lint-backend lint-frontend

# Format everything
fmt: fmt-backend fmt-frontend

# --- Tests ---

# Run backend tests
test-backend *args:
    cd backend && uv run pytest {{args}}

# Run frontend tests
test-frontend:
    cd frontend/rooster_app && flutter test

# Run all tests
test: test-backend test-frontend

# --- Pre-commit check (same as what the hook runs) ---

# Run all pre-commit checks
check:
    cd backend && uv run ruff check . && uv run ruff format --check .
    cd frontend/rooster_app && flutter analyze && dart format --set-exit-if-changed .

# --- Build ---

# Build frontend for production (usage: just frontend-build "https://api.example.com/api")
frontend-build api_url="http://localhost:8000/api":
    cd frontend/rooster_app && flutter build web --release --dart-define=API_BASE_URL={{api_url}}

# --- Docker ---

# Build all Docker images
docker-build:
    docker compose build

# Start all services
docker-up:
    docker compose up -d

# Stop all services
docker-down:
    docker compose down

# View logs
docker-logs:
    docker compose logs -f

# --- Tunnel (share dev build via public URL) ---

# Build and start the full tunnel stack (proxy + cloudflared)
tunnel:
    docker compose -f docker-compose.yaml -f docker-compose.tunnel.yaml up --build

# Tear down tunnel stack
tunnel-down:
    docker compose -f docker-compose.yaml -f docker-compose.tunnel.yaml down

# Follow tunnel logs to find the public *.trycloudflare.com URL
tunnel-logs:
    docker compose -f docker-compose.yaml -f docker-compose.tunnel.yaml logs -f tunnel
