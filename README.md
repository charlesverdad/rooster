# Rooster

A volunteer rostering application designed for church communities. Rooster helps volunteers know when they're scheduled to serve and lets them respond quickly.

## Features

- **Team Management** - Create teams, add members by name, and invite them later via email
- **Roster Scheduling** - Create recurring rosters (weekly, bi-weekly, monthly) and assign volunteers
- **Assignment Response** - Volunteers can accept or decline assignments with one tap
- **Push Notifications** - Get notified about new assignments instantly (web push)
- **Email Notifications** - Assignment notifications and team invites via email
- **PWA Support** - Install as a standalone app on mobile and desktop
- **Availability Tracking** - Mark dates as unavailable so team leads can plan around you

## Tech Stack

| Layer | Technology |
|-------|------------|
| **Backend** | Python 3.12, FastAPI, SQLAlchemy, PostgreSQL |
| **Frontend** | Flutter (Web, iOS, Android) |
| **Authentication** | JWT tokens |
| **Notifications** | Web Push (VAPID), Email (SMTP/Resend) |

## Quick Start

### Prerequisites

- [Nix](https://nixos.org/download.html) (for development) OR Docker (for deployment)
- Git

### Development Setup (with Nix)

1. **Clone and enter the development shell:**
   ```bash
   git clone https://github.com/your-org/rooster.git
   cd rooster
   nix-shell
   ```

2. **First-time setup:**
   ```bash
   just setup
   ```

3. **Start the database:**
   ```bash
   start_db
   just db-migrate
   ```

4. **Run the development servers:**
   ```bash
   just dev
   ```

   Or run backend and frontend separately:
   ```bash
   just backend   # API at http://localhost:8000
   just frontend  # App at http://localhost:3000
   ```

### Docker Deployment

1. **Copy the environment file:**
   ```bash
   cp .env.example .env
   ```

2. **Configure your environment** (see [Configuration](#configuration) below)

3. **Build and start:**
   ```bash
   docker compose up -d
   ```

   The app will be available at:
   - Frontend: http://localhost:3000
   - Backend API: http://localhost:8000

## Configuration

Copy `.env.example` to `.env` and configure the following:

### Required Settings

| Variable | Description |
|----------|-------------|
| `SECRET_KEY` | JWT signing key. Generate with: `python -c "import secrets; print(secrets.token_urlsafe(32))"` |
| `APP_URL` | Frontend URL for email links (e.g., `https://rooster.example.com`) |
| `API_BASE_URL` | Backend API URL for frontend (e.g., `https://api.rooster.example.com/api`) |

### Database

| Variable | Default | Description |
|----------|---------|-------------|
| `POSTGRES_USER` | `rooster` | Database username |
| `POSTGRES_PASSWORD` | `rooster` | Database password |
| `POSTGRES_DB` | `rooster` | Database name |

### Email (Optional but Recommended)

Choose one email provider:

**Option A: SMTP (Gmail, etc.)**
```bash
EMAIL_ENABLED=true
EMAIL_PROVIDER=smtp
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASSWORD=your-app-password  # Use App Password for Gmail
SMTP_FROM_EMAIL=your-email@gmail.com
SMTP_FROM_NAME=Rooster
SMTP_USE_TLS=true
```

**Option B: Resend**
```bash
EMAIL_ENABLED=true
EMAIL_PROVIDER=resend
RESEND_API_KEY=re_xxxxx
SMTP_FROM_EMAIL=noreply@yourdomain.com
SMTP_FROM_NAME=Rooster
```

### Push Notifications (Optional but Recommended)

Web Push notifications require VAPID keys. Generate them at [vapidkeys.com](https://vapidkeys.com) or with Python:

```bash
python -c "from py_vapid import Vapid; v = Vapid(); v.generate_keys(); print('Public:', v.public_key.urlsafe_b64encode().decode()); print('Private:', v.private_key.urlsafe_b64encode().decode())"
```

```bash
VAPID_PUBLIC_KEY=BLxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
VAPID_PRIVATE_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
VAPID_SUBJECT=mailto:admin@yourdomain.com
```

### CORS

| Variable | Default | Description |
|----------|---------|-------------|
| `CORS_ORIGINS` | `*` | Comma-separated list of allowed origins, or `*` for all |

## Available Commands

All commands use `just` and are available inside `nix-shell`:

```bash
# Development
just dev              # Run backend + frontend
just backend          # Run backend only
just frontend         # Run frontend only

# Database
just db-migrate                    # Run migrations
just db-migration "description"    # Create new migration

# Code Quality
just lint             # Lint everything
just fmt              # Format everything
just check            # Run pre-commit checks
just test             # Run all tests
just test-backend     # Backend tests only
just test-frontend    # Frontend tests only

# Docker
just docker-build     # Build images
just docker-up        # Start services
just docker-down      # Stop services
just docker-logs      # View logs
```

## Project Structure

```
rooster/
├── backend/
│   ├── app/
│   │   ├── api/              # API route handlers
│   │   ├── core/             # Config, security, database
│   │   ├── models/           # SQLAlchemy models
│   │   ├── schemas/          # Pydantic schemas
│   │   └── services/         # Business logic
│   ├── alembic/              # Database migrations
│   └── tests/
├── frontend/
│   └── rooster_app/          # Flutter project
│       ├── lib/
│       │   ├── models/       # Data models
│       │   ├── providers/    # State management
│       │   ├── screens/      # UI screens
│       │   ├── services/     # API services
│       │   └── widgets/      # Reusable widgets
│       └── web/              # Web-specific files
├── docker-compose.yaml
├── .env.example
└── justfile
```

## Deployment Guide

### Production Checklist

1. **Security**
   - [ ] Set a strong, unique `SECRET_KEY`
   - [ ] Set `DEBUG=false`
   - [ ] Configure `CORS_ORIGINS` to your frontend domain only
   - [ ] Use HTTPS for both frontend and backend

2. **Email**
   - [ ] Configure email provider (SMTP or Resend)
   - [ ] Set `EMAIL_ENABLED=true`
   - [ ] Verify emails are sending correctly

3. **Push Notifications**
   - [ ] Generate VAPID keys
   - [ ] Configure `VAPID_PUBLIC_KEY`, `VAPID_PRIVATE_KEY`, `VAPID_SUBJECT`

4. **Database**
   - [ ] Use a strong database password
   - [ ] Configure database backups

### Deploying with Docker

1. **Build with production API URL:**
   ```bash
   API_BASE_URL=https://api.yourdomain.com/api docker compose build
   ```

2. **Run database migrations:**
   ```bash
   docker compose run --rm backend alembic upgrade head
   ```

3. **Start services:**
   ```bash
   docker compose up -d
   ```

### Deploying to Cloud Platforms

#### Railway / Render / Fly.io

1. Deploy the backend as a Python/FastAPI service
2. Deploy the frontend as a static site (build with Flutter)
3. Deploy PostgreSQL as a managed database
4. Set environment variables in your platform's dashboard

#### Kubernetes

Helm charts and Kubernetes manifests are not included but can be created from the Dockerfiles and docker-compose.yaml as a reference.

### Reverse Proxy Setup

Example nginx configuration for production:

```nginx
# Frontend
server {
    listen 80;
    server_name rooster.example.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name rooster.example.com;

    ssl_certificate /etc/letsencrypt/live/rooster.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/rooster.example.com/privkey.pem;

    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}

# Backend API
server {
    listen 443 ssl http2;
    server_name api.rooster.example.com;

    ssl_certificate /etc/letsencrypt/live/api.rooster.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.rooster.example.com/privkey.pem;

    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## Notifications

Rooster supports three types of notifications:

### In-App Notifications
Always enabled. Users see a bell icon with unread count on the home screen.

### Email Notifications
Sent for:
- Team invitations
- New assignment notifications

Configure email in `.env` (see [Email Configuration](#email-optional-but-recommended)).

### Push Notifications (Web)
Real-time browser notifications for:
- New assignment created
- Assignment reminders

**Setup:**
1. Generate VAPID keys (see [Push Notifications Configuration](#push-notifications-optional-but-recommended))
2. Add keys to `.env`
3. Users will be prompted to enable notifications when they first log in

**How it works:**
1. Service worker (`service-worker.js`) handles push events
2. Backend sends notifications via Web Push API when assignments are created
3. Clicking notification opens the assignment in the app

## PWA Installation

Rooster is a Progressive Web App (PWA). Users can install it:

1. **Chrome Desktop**: Click the install icon in the address bar
2. **Chrome Mobile**: Tap "Add to Home Screen" in the menu
3. **Safari iOS**: Tap Share → Add to Home Screen

The app will prompt users to install and enable notifications after first login.

## API Documentation

When running the backend, API documentation is available at:
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feat/my-feature`
3. Make your changes
4. Run checks: `just check`
5. Commit with conventional commits: `git commit -m "feat: add my feature"`
6. Push and create a PR

## License

MIT License - see [LICENSE](LICENSE) for details.
