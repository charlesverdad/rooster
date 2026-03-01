# Claude Code Guidelines for Rooster

## Project Overview

Rooster is a church volunteer rostering application built with:
- **Backend**: Python + FastAPI + PostgreSQL
- **Frontend**: Flutter (Web, iOS, Android)

## Development Workflow

### Commits
- **Commit after each feature** - Keep commits atomic and focused
- Write clear commit messages describing what and why
- Format: `<type>: <description>` (e.g., `feat: add user authentication`)
- Make sure that the code compiles before committing anything. If it doesn't, fix it first.

### Environment
- **Always use `nix-shell`** for development environment
- Run `nix-shell` before running any backend or build commands
- The shell.nix provides Python, PostgreSQL, uv, and other dependencies
- **Use `uv` for Python package management** (not pip)

### Branch Strategy
- `main` - stable, production-ready code
- Feature branches for new work: `feat/<feature-name>`

## Project Structure

```
rooster/
├── backend/
│   ├── app/
│   │   ├── main.py           # FastAPI app entry
│   │   ├── api/              # Route handlers (auth, admin, teams, rosters, etc.)
│   │   ├── models/           # SQLAlchemy models (user, system_config, etc.)
│   │   ├── schemas/          # Pydantic schemas
│   │   ├── services/         # Business logic (admin, auth, team, etc.)
│   │   └── core/             # Config, security, deps
│   ├── alembic/              # Database migrations
│   ├── tests/
│   └── pyproject.toml        # Python dependencies (uv)
├── frontend/
│   └── rooster_app/          # Flutter project
│       └── lib/
│           ├── screens/
│           │   ├── admin/    # Sys admin panel (dashboard, users, config)
│           │   ├── auth/     # Login, register, first-run setup
│           │   └── ...
│           ├── providers/    # State management (auth, admin, etc.)
│           └── services/     # API services (admin, team, etc.)
├── docs/                     # Feature design documents
├── shell.nix
├── PRD.md
└── CLAUDE.md
```

## Backend Conventions

### FastAPI
- Use dependency injection for database sessions
- Pydantic models for request/response validation
- Async endpoints where beneficial
- Group routes by domain in `api/` directory

### Database
- SQLAlchemy ORM with async support
- Alembic for migrations - **always create migrations for schema changes**
- Use UUID for primary keys
- Timestamps on all tables (created_at, updated_at)

### Authentication
- JWT tokens for API authentication
- Password hashing with bcrypt
- Store tokens in secure HTTP-only cookies or Authorization header
- Auth config (email/Google toggles) can be changed at runtime via `auth_settings` DB table
- Config resolution: DB row (if exists) > env var defaults; `AUTH_FORCE_EMAIL_ENABLED` always overrides
- `is_deactivated` check on every authenticated request in `get_current_user`
- `SuperAdmin` dependency for admin-only endpoints (follows `CurrentUser` pattern)

### Code Style
- Follow PEP 8
- Type hints on all functions
- Docstrings for public functions

## Frontend Conventions

### Flutter
- Use Provider or Riverpod for state management
- Separate UI widgets from business logic
- Follow Material 3 design guidelines
- Organize by feature, not by type

### Code Style
- Follow Dart conventions
- Use `const` constructors where possible
- Extract reusable widgets

## Testing

### Backend
- pytest for unit and integration tests
- Test database with transactions (rollback after each test)
- Aim for coverage on business logic

### Frontend
- Widget tests for UI components
- Integration tests for critical flows

## Common Commands

All dev commands use `just` (available in `nix-shell`). Run `just` to see all available commands.

```bash
# Enter development environment
nix-shell

# First-time setup (install deps + git hooks)
just setup

# Run both backend + frontend
just dev

# Run just backend or frontend
just backend
just frontend

# Database
just db-migrate                        # Run migrations
just db-migration "description"        # Create new migration

# Lint & format
just lint                              # Lint everything
just fmt                               # Format everything
just check                             # Run pre-commit checks

# Tests
just test                              # Run all tests
just test-backend                      # Backend only
just test-frontend                     # Frontend only
just test-backend -k "test_name"       # Run specific test

# Install/sync dependencies
uv sync --project backend              # Install dependencies
uv add <package> --project backend     # Add new dependency
uv add --dev <package> --project backend  # Add dev dependency
```

## MVP Implementation Order

1. Project setup (nix-shell, backend scaffold, frontend scaffold)
2. Database models and migrations
3. User authentication (register, login, JWT)
4. Organisation and team management
5. Roster creation and manual assignments
6. Member availability
7. Dashboard views (member home, calendar)
8. Basic notifications (in-app)
9. Google OAuth social login
10. System admin panel (first-run setup, dashboard, user management, runtime auth config)

## Push Notifications & Service Worker

The app uses a **custom service worker** (`frontend/rooster_app/web/service-worker.js`) for:
- Web Push notification display (push event handler)
- Notification tap opens the relevant in-app page (notificationclick handler)
- Static asset caching (cache-first for assets, network-first for navigation)
- Notification deduplication via `tag` (e.g., `new-assignment` replaces previous)

**CRITICAL: `--pwa-strategy none` is required on all `flutter build web` commands.**
Without this flag, Flutter generates `flutter_service_worker.js` and registers it
via `flutter_bootstrap.js`, which **replaces the custom service worker** at the same
scope (`/`). The Flutter-generated SW has no push or notificationclick handlers,
so push notifications silently break. Both SWs call `skipWaiting()`, so the last
one registered wins — and Flutter's async bootstrap script always registers last.

### Service Worker Architecture
- `web/service-worker.js` — custom SW registered by inline script in `index.html`
- Push payloads include `url` (in-app route) and `tag` (for deduplication)
- `notificationclick` opens the app to the notification URL
- SW sends `NAVIGATE` postMessage to existing windows for in-app routing
- Accept/decline actions are handled in-app on the assignment detail screen
- Note: `event.action` from notification buttons is unreliable on Android Chrome,
  so we deliberately avoid silent API calls from the service worker

## System Admin Panel

See `docs/sys-admin-panel.md` for full design spec.

### Key Architecture
- **User model**: `is_superadmin` and `is_deactivated` boolean fields
- **Auth config**: `auth_settings` single-row typed table (not generic key-value)
- **Config fallback**: DB row present → use it, else env vars. `AUTH_FORCE_EMAIL_ENABLED` always overrides.
- **First-run setup**: `GET /auth/setup-required` + `POST /auth/setup` (public endpoints)
- **Admin API**: All under `/api/admin/`, gated by `SuperAdmin` dependency
- **Frontend**: Admin panel at `/admin` with 3 tabs (Dashboard, Users, Config), desktop-only

### Admin API Endpoints
- `GET /api/admin/stats` — Dashboard statistics
- `GET/PUT /api/admin/config` — Auth configuration
- `GET /api/admin/users` — Paginated user list (search, filter, sort)
- `GET /api/admin/users/{id}` — User detail with memberships
- `POST /api/admin/users/{id}/deactivate|reactivate|promote-admin|demote-admin`
- `GET /api/admin/organisations` — Org list with member/team counts

## Notes

- See `PRD.md` for full feature specifications
- See `docs/sys-admin-panel.md` for admin panel design spec
- MVP focuses on single organisation, manual assignments
- Phase 2 adds multi-org, auto-scheduling, swap requests
