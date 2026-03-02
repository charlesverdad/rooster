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
- **System Admin Panel** - Dashboard with system stats, user management, and runtime auth configuration
- **First-Run Onboarding** - Self-bootstrapping setup flow creates the first admin account

## Tech Stack

| Layer | Technology |
|-------|------------|
| **Backend** | Python 3.12, FastAPI, SQLAlchemy, PostgreSQL |
| **Frontend** | Flutter (Web, iOS, Android) |
| **Authentication** | JWT tokens, Google OAuth (optional), runtime-configurable |
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

### Authentication

By default, Rooster uses email/password authentication. You can also enable Google OAuth login, or disable email login entirely to force Google-only authentication.

Auth methods can be configured in two ways:
1. **Environment variables** (default) - Used as initial defaults
2. **Runtime admin panel** - Sys admins can toggle auth methods at `/admin/settings` without restarting the server. Runtime settings override env var defaults.

| Variable | Default | Description |
|----------|---------|-------------|
| `AUTH_EMAIL_ENABLED` | `true` | Enable email/password login and registration |
| `AUTH_GOOGLE_ENABLED` | `false` | Enable Google OAuth login |
| `GOOGLE_CLIENT_ID` | `""` | Google OAuth client ID (required when Google auth is enabled) |
| `AUTH_FORCE_EMAIL_ENABLED` | `false` | Emergency override: forces email login on regardless of runtime config (prevents lockout) |

**Setting up Google Sign-In:**

1. Go to the [Google Cloud Console](https://console.cloud.google.com/)
2. Create a project (or use an existing one)
3. Navigate to **APIs & Services > Credentials**
4. Click **Create Credentials > OAuth 2.0 Client ID**
5. For web apps, set the **Authorized JavaScript origins** to your frontend URL (e.g., `https://rooster.example.com`)
6. Copy the **Client ID** (looks like `123456789-abc.apps.googleusercontent.com`)
7. No client secret is needed — the backend verifies Google ID tokens using Google's public keys

**Common configurations:**

```bash
# Email only (default)
AUTH_EMAIL_ENABLED=true
AUTH_GOOGLE_ENABLED=false

# Both email and Google
AUTH_EMAIL_ENABLED=true
AUTH_GOOGLE_ENABLED=true
GOOGLE_CLIENT_ID=123456789-abc.apps.googleusercontent.com

# Google only (no email/password)
AUTH_EMAIL_ENABLED=false
AUTH_GOOGLE_ENABLED=true
GOOGLE_CLIENT_ID=123456789-abc.apps.googleusercontent.com
```

When building the frontend for Docker deployment with Google login, also pass the client ID as a build arg:
```bash
docker compose build --build-arg GOOGLE_CLIENT_ID=123456789-abc.apps.googleusercontent.com
```

### First-Run Setup

When Rooster starts with an empty database, it shows a **setup screen** instead of the login page. This creates the first system administrator account without any env var configuration:

1. Navigate to your Rooster instance
2. Fill in admin name, email, password, and optionally your church/organisation name
3. Click "Create my admin account"
4. You're signed in as a system administrator and land on the home screen

The setup screen only appears once. After the first user is created, it redirects to the normal login page. To access admin features after setup, go to **Settings > System Admin**.

### System Administration

System admins have access to the admin panel at `/admin` (accessible from Settings). The panel provides:

- **Dashboard** - System-wide stats (users, orgs, teams, assignments, push subscriptions)
- **User Management** - List, search, filter, deactivate/reactivate users, promote/demote admins
- **Config** - Toggle auth methods (email/Google) at runtime, manage Google Client ID

**How someone becomes a sys admin:**
- The first user created via the setup flow is automatically a sys admin
- Existing sys admins can promote other users from the admin panel
- At least one sys admin must always exist (last-admin guard)

**Account deactivation:**
- Sys admins can deactivate user accounts (soft-disable, preserves data)
- Deactivated users are immediately blocked from authenticated endpoints
- Accounts can be reactivated at any time

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
│   │   ├── api/              # API route handlers (auth, admin, teams, etc.)
│   │   ├── core/             # Config, security, database
│   │   ├── models/           # SQLAlchemy models (user, system_config, etc.)
│   │   ├── schemas/          # Pydantic schemas
│   │   └── services/         # Business logic
│   ├── alembic/              # Database migrations
│   └── tests/
├── frontend/
│   └── rooster_app/          # Flutter project
│       ├── lib/
│       │   ├── models/       # Data models
│       │   ├── providers/    # State management (auth, admin, etc.)
│       │   ├── screens/      # UI screens
│       │   │   ├── admin/    # System admin panel (dashboard, users, config)
│       │   │   ├── auth/     # Login, register, first-run setup
│       │   │   └── ...
│       │   ├── services/     # API services
│       │   └── widgets/      # Reusable widgets
│       └── web/              # Web-specific files
├── docs/                     # Feature design documents
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
   - [ ] Consider setting `AUTH_FORCE_EMAIL_ENABLED=true` as a lockout safety net

2. **First Run**
   - [ ] Navigate to the app after deployment — setup screen will appear
   - [ ] Create the first admin account (this becomes the system administrator)
   - [ ] Configure auth methods from the admin panel (`/admin/settings`) if needed

3. **Authentication**
   - [ ] Choose auth method: email, Google, or both (see [Authentication](#authentication))
   - [ ] Auth methods can be configured via env vars OR the admin panel at runtime
   - [ ] If using Google: set `GOOGLE_CLIENT_ID` via env var or admin panel
   - [ ] If Google-only: disable email login from admin panel (not recommended without `AUTH_FORCE_EMAIL_ENABLED`)

3. **Email**
   - [ ] Configure email provider (SMTP or Resend)
   - [ ] Set `EMAIL_ENABLED=true`
   - [ ] Verify emails are sending correctly

4. **Push Notifications**
   - [ ] Generate VAPID keys
   - [ ] Configure `VAPID_PUBLIC_KEY`, `VAPID_PRIVATE_KEY`, `VAPID_SUBJECT`

5. **Database**
   - [ ] Use a strong database password
   - [ ] Configure database backups

### Deploying with Docker

1. **Build with production settings:**
   ```bash
   docker compose build \
     --build-arg API_BASE_URL=https://api.yourdomain.com/api \
     --build-arg GOOGLE_CLIENT_ID=your-client-id.apps.googleusercontent.com  # optional
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
