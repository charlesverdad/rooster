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
│   │   ├── api/              # Route handlers
│   │   ├── models/           # SQLAlchemy models
│   │   ├── schemas/          # Pydantic schemas
│   │   ├── services/         # Business logic
│   │   └── core/             # Config, security, deps
│   ├── alembic/              # Database migrations
│   ├── tests/
│   └── pyproject.toml        # Python dependencies (uv)
├── frontend/
│   └── rooster_app/          # Flutter project
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

```bash
# Enter development environment
nix-shell

# Backend
cd backend
uv run uvicorn app.main:app --reload

# Install/sync dependencies
uv sync --project backend            # Install dependencies
uv add <package> --project backend   # Add new dependency
uv add --dev <package> --project backend  # Add dev dependency

# Run migrations
uv run alembic upgrade head

# Create new migration
uv run alembic revision --autogenerate -m "description"

# Backend tests
uv run pytest

# Frontend
cd frontend/rooster_app
flutter run -d chrome    # Web
flutter run              # Mobile

# Flutter tests
flutter test
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

## Notes

- See `PRD.md` for full feature specifications
- MVP focuses on single organisation, manual assignments
- Phase 2 adds multi-org, auto-scheduling, swap requests
