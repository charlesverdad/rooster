# Rooster

[![Backend Lint](https://github.com/charlesverdad/rooster/actions/workflows/lint-backend.yml/badge.svg)](https://github.com/charlesverdad/rooster/actions/workflows/lint-backend.yml)
[![Frontend Lint](https://github.com/charlesverdad/rooster/actions/workflows/lint-frontend.yml/badge.svg)](https://github.com/charlesverdad/rooster/actions/workflows/lint-frontend.yml)
[![Backend Tests](https://github.com/charlesverdad/rooster/actions/workflows/test-backend.yml/badge.svg)](https://github.com/charlesverdad/rooster/actions/workflows/test-backend.yml)
[![Frontend Tests](https://github.com/charlesverdad/rooster/actions/workflows/test-frontend.yml/badge.svg)](https://github.com/charlesverdad/rooster/actions/workflows/test-frontend.yml)

A volunteer rostering application designed for church communities. Rooster helps volunteers know when they're scheduled to serve and lets them respond quickly — prioritizing simplicity so users spend minimal time in the app.

## Tech Stack

| Layer | Technology |
|-------|------------|
| **Backend** | Python, FastAPI, PostgreSQL |
| **Frontend** | Flutter (Web, iOS, Android) |
| **Authentication** | JWT tokens |
| **Package Management** | uv (Python), pub (Dart) |

## Prerequisites

- [Nix](https://nixos.org/download.html) — provides all development dependencies (Python, PostgreSQL, Flutter, uv, just)

## Getting Started

```bash
# Enter the development environment
nix-shell

# First-time setup (install deps + git hooks)
just setup

# Start PostgreSQL
start_db

# Run database migrations
just db-migrate

# Run both backend and frontend
just dev
```

## Development Commands

All commands use [just](https://github.com/casey/just) (available inside `nix-shell`). Run `just` to see the full list.

```bash
# Dev servers
just backend                           # Run backend (FastAPI on :8000)
just frontend                          # Run frontend (Flutter on Chrome)
just dev                               # Run both

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

# Dependencies
uv sync --project backend              # Sync Python dependencies
uv add <package> --project backend     # Add Python dependency
```

## Project Structure

```
rooster/
├── backend/
│   ├── app/
│   │   ├── main.py           # FastAPI app entry
│   │   ├── api/              # Route handlers
│   │   ├── models/           # SQLAlchemy models
│   │   ├── schemas/          # Pydantic schemas
│   │   ├── services/         # Business logic
│   │   └── core/             # Config, security, deps
│   ├── alembic/              # Database migrations
│   ├── tests/
│   └── pyproject.toml
├── frontend/
│   └── rooster_app/          # Flutter project
├── .github/workflows/        # CI pipelines
├── shell.nix                 # Nix development environment
├── Justfile                  # Development commands
├── PRD.md                    # Product requirements
└── CLAUDE.md                 # AI coding guidelines
```

## Contributing

1. Create a feature branch: `git checkout -b feat/<feature-name>`
2. Enter the dev environment: `nix-shell`
3. Make your changes, keeping commits atomic and focused
4. Run checks before pushing: `just check`
5. Run tests: `just test`
6. Open a pull request against `main`

### Commit Messages

Use the format `<type>: <description>`:

- `feat:` — new feature
- `fix:` — bug fix
- `refactor:` — code restructuring
- `docs:` — documentation changes
- `test:` — adding or updating tests
- `chore:` — maintenance tasks

See [CLAUDE.md](CLAUDE.md) for detailed development conventions and [PRD.md](PRD.md) for product specifications.
