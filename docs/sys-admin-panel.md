# Sys Admin Panel -- Feature Design Document

> **Status**: Draft / Awaiting Approval
> **Date**: 2026-03-01
> **Contributors**: UX Designer, Tech Architect, Devil's Advocate (agent team review)

---

## Table of Contents

1. [Overview](#1-overview)
2. [UX Design](#2-ux-design)
3. [Technical Architecture](#3-technical-architecture)
4. [Critical Review & Risk Analysis](#4-critical-review--risk-analysis)
5. [Recommended Implementation Plan](#5-recommended-implementation-plan)
6. [File Change Summary](#6-file-change-summary)

---

## 1. Overview

### Problem

Rooster's system configuration (auth methods, Google client ID) is managed entirely through environment variables, requiring server restarts for changes. There is no visibility into system-wide statistics (user counts, org counts, teams) and no way to manage users across the platform.

### Goals

- Allow a sys admin to toggle auth methods (email/password, Google OAuth) at runtime
- Provide a dashboard with key system metrics
- Enable user management (view all users, deactivate accounts, promote admins)
- View organisation overview across the platform

### Non-Goals (deferred)

- Email delivery statistics and tracking
- Audit logging
- Mobile-optimised admin views
- Generic key-value configuration system
- Organisation/team CRUD from admin panel (orgs have their own settings screens)

---

## 2. UX Design

### 2.1 Navigation & Access

The sys admin panel is a **separate top-level section** at `/admin`, not nested under existing Settings or Org Settings. Rationale: sys admin operates across ALL organisations, which is orthogonal to the per-org/per-team hierarchy.

**Entry point**: A new `ListTile` in the Settings screen (`/settings`), visible ONLY to sys admins. Icon: `Icons.admin_panel_settings`, label: "System Admin". Taps to `/admin`.

**Route guard**: GoRouter redirect checks `is_superadmin` on the user. Non-admins navigating to `/admin/*` are redirected to `/`.

### 2.2 First-Run Onboarding Flow

When Rooster is started for the very first time (no users in the database), the app shows a **setup screen** instead of the normal login screen. This is how the first sys admin account is created.

#### Setup Status Detection

The frontend fetches `GET /auth/setup-required` on startup (in parallel with `/auth/config`). This returns `{ "setup_required": true }` when no users exist. The result is stored as `setupRequired` in `AuthProvider`.

**Router logic**:
```
if not initialized           → show loading
if setupRequired             → redirect everything to /setup
if not authenticated         → redirect to /login
else                         → allow through
```

Once `setupRequired` is false, navigating to `/setup` redirects to `/login` (unauthenticated) or `/` (authenticated). The setup screen is never shown again.

#### Setup Screen Layout (`/setup`)

Single screen, no wizard steps. Same visual style as the login screen (centered card, max-width ~480px, Rooster logo above).

```
┌─────────────────────────────────────────┐
│                                         │
│          [Rooster logo]                 │
│                                         │
│       Welcome to Rooster                │
│  Let's get your church set up.          │
│                                         │
│  ┌───────────────────────────────────┐  │
│  │ Your name                         │  │
│  │ [________________________]        │  │
│  └───────────────────────────────────┘  │
│                                         │
│  ┌───────────────────────────────────┐  │
│  │ Email address                     │  │
│  │ [________________________]        │  │
│  └───────────────────────────────────┘  │
│                                         │
│  ┌───────────────────────────────────┐  │
│  │ Password                          │  │
│  │ [________________________]        │  │
│  └───────────────────────────────────┘  │
│                                         │
│  ────────────── Optional ──────────────  │
│                                         │
│  ┌───────────────────────────────────┐  │
│  │ Church / organisation name        │  │
│  │ [________________________]        │  │
│  └───────────────────────────────────┘  │
│  You can change this later in settings. │
│                                         │
│  ┌───────────────────────────────────┐  │
│  │      Create my admin account      │  │
│  └───────────────────────────────────┘  │
│                                         │
│  You'll be signed in as a system        │
│  administrator.                         │
│                                         │
└─────────────────────────────────────────┘
```

**Fields**:
- Name: required
- Email: required, valid format
- Password: required, minimum 8 characters, visibility toggle
- Organisation name: optional (admin can create it later in the admin panel)

**Validation**: Inline on blur (not on submit). Same pattern as login/register screens.

#### What Happens After Submit

1. `POST /auth/setup` with name, email, password, and optionally org name
2. Backend creates the user with `is_superadmin=true`, creates the organisation if name was provided, and returns a JWT (same shape as `/auth/login`)
3. `AuthProvider` receives the token, sets `setupRequired = false`, marks user as authenticated
4. Router redirects to home. Snackbar: "You're all set. Welcome to Rooster."

**No Google sign-in on the setup screen**. The first admin must use email/password -- it serves as the recovery path if OAuth is later misconfigured. Google login is configured afterwards in the admin panel.

#### Edge Cases

| Scenario | Behaviour |
|----------|-----------|
| Setup already complete, user navigates to `/setup` | Router redirects to `/login` (never renders setup screen) |
| Browser refresh mid-setup (form half-filled) | Form resets. No partial data stored -- acceptable for a one-time flow |
| Two tabs submit setup simultaneously | Second `POST /auth/setup` returns 409 Conflict. Message: "Setup is already complete. Redirecting to sign in..." |
| Slow network, double-click submit | Button disabled on first click (shows CircularProgressIndicator) |
| `GET /auth/setup-required` fails (network error) | Fail safe: treat as `setup_required: false`, fall through to login screen |

#### How Someone Becomes a Sys Admin (After Setup)

- The first user is created as sys admin via the onboarding flow above
- Existing sys admins can promote/demote other users from the admin Users screen
- At least one sys admin must always exist (last-admin guard)
- No self-service path to become sys admin after initial setup

### 2.3 Screen Structure

Three tabs on desktop (`TabBar`), with a back arrow to Settings:

| Tab | Icon | Label | Route |
|-----|------|-------|-------|
| 1 | `Icons.dashboard_outlined` | Dashboard | `/admin` |
| 2 | `Icons.people_outlined` | Users | `/admin/users` |
| 3 | `Icons.settings_outlined` | Config | `/admin/settings` |

**Mobile**: Show a "Please use a desktop browser for admin settings" message. Admin configuration is not a quick mobile interaction -- this avoids doubling frontend effort for a marginal use case.

### 2.4 Dashboard Tab (`/admin`)

Vertical scroll with card-based sections. Read-only.

**Section 1: Key Metrics** -- Responsive grid of metric cards (4 columns on desktop):

| Card | Metric | Subtitle |
|------|--------|----------|
| Total Users | Count of registered users | "+X this month" |
| Organisations | Count of non-personal orgs | "+X this month" |
| Teams | Total teams across all orgs | -- |
| Assignments | Active (pending + confirmed) | "X pending response" |

Each card: icon in tinted `CircleAvatar`, large number (28sp bold), label (14sp grey), delta subtitle (12sp green).

**Section 2: Auth Status** -- Compact summary showing which auth methods are active (green/grey chips). Tapping navigates to Config tab.

**Section 3: Organisation Overview** -- Condensed list showing each org with name, member count, team count, created date. Sorted by member count descending.

### 2.5 Users Tab (`/admin/users`)

**Search + Filter Bar**: `TextField` with search icon (name/email), `FilterChip` row: All, Sys Admins, Org Admins, Placeholders.

**User List**: `DataTable` with sortable columns on desktop:

| Column | Description |
|--------|-------------|
| Name | User's display name |
| Email | Email address |
| Organisations | Comma-separated org names |
| Role Badges | Chips: "Sys Admin" (purple), "Org Admin" (blue), "Team Lead" (teal) |
| Registered | Date |
| Status | "Active" / "Placeholder" / "Deactivated" |

**User Detail** (tap a row): Side panel showing:
1. Profile: name, email, registration date, auth method (email/Google)
2. Organisation memberships with roles
3. Team memberships with roles
4. Actions: "Make/Remove Sys Admin" toggle, "Deactivate User" button

**Constraints**:
- Cannot remove sys admin from yourself
- Cannot remove the last sys admin
- Cannot deactivate yourself
- Deactivation warning: "This user will be unable to log in. Their data will be preserved."

### 2.6 Config Tab (`/admin/settings`)

**Card 1: Authentication Methods**

```
Authentication Methods
---
Email / Password Login      [Toggle: ON]
Google Sign-In              [Toggle: OFF]

  Google Client ID
  [________________________]  (disabled when Google toggle is off)

  [Save Changes]  (enabled only when form is dirty)
```

Behaviour:
- `SwitchListTile` widgets for toggles
- Google Client ID field required when Google toggle is ON
- Save button shows loading indicator, then success snackbar
- Warning banner if ALL auth methods disabled: "Warning: All authentication methods are disabled. Users will be unable to log in."
- Toggling email OFF shows confirmation dialog
- **Safety**: disabling an auth method requires re-entering admin password

**Card 2: Email Configuration** (read-only)

```
Email Delivery
---
Provider:     Resend (or "SMTP")
Status:       [Configured] / [Not Configured]
From Address: noreply@rooster.app

Note: Email configuration is managed via environment variables.
```

**Card 3: Push Notifications** (read-only)

```
Push Notifications
---
VAPID Keys:   [Configured] / [Not Configured]
Active Subscriptions: 47

Note: VAPID keys are managed via environment variables.
```

### 2.7 State Management

New `AdminProvider` (extends `ChangeNotifier`), lazy-loaded only when navigating to `/admin`:
- `fetchDashboardStats()` -- metrics, auth status
- `fetchAllUsers({search, filter, page})` -- paginated user list
- `updateAuthConfig({emailEnabled, googleEnabled, googleClientId})`
- `updateUserSysAdmin(userId, isSysAdmin)`
- `deactivateUser(userId)` / `reactivateUser(userId)`

---

## 3. Technical Architecture

### 3.1 Data Model Changes

#### User Model: New Columns

```python
# In app/models/user.py - add to User class:

# Sys admin flag
is_superadmin: Mapped[bool] = mapped_column(
    Boolean, default=False, server_default="false", nullable=False
)

# Soft-disable (prevents login, preserves data)
is_deactivated: Mapped[bool] = mapped_column(
    Boolean, default=False, server_default="false", nullable=False
)
```

#### Auth Config Table (Minimal, Not Generic Key-Value)

Instead of a generic `system_config` key-value table, use a **single-row typed table** for auth settings. This avoids overengineering a config system for three values:

```python
# app/models/system_config.py

class AuthSettings(Base, TimestampMixin):
    """Single-row table for runtime auth configuration."""

    __tablename__ = "auth_settings"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, default=1)
    email_enabled: Mapped[bool] = mapped_column(Boolean, default=True)
    google_enabled: Mapped[bool] = mapped_column(Boolean, default=False)
    google_client_id: Mapped[str | None] = mapped_column(String(500), nullable=True)
    updated_by_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
```

**Config resolution**: If the `auth_settings` row exists, use it. Otherwise fall through to env var defaults from `get_settings()`. This is a simple `SELECT` on a one-row table -- no caching needed.

**Emergency override**: New env var `AUTH_FORCE_EMAIL_ENABLED=true` -- if set, email login is always available regardless of DB state. This prevents lockout scenarios where an admin accidentally disables all auth methods.

### 3.2 API Endpoints

All admin endpoints under `/api/admin/`, gated by `SuperAdmin` dependency.

#### Dashboard Stats

```
GET /api/admin/stats
```

Response:
```json
{
  "users": {
    "total": 142,
    "active": 130,
    "placeholder": 12,
    "superadmin": 2,
    "created_last_30_days": 18
  },
  "organisations": {
    "total": 8,
    "personal": 5,
    "named": 3
  },
  "teams": {
    "total": 24
  },
  "assignments": {
    "total": 340,
    "pending": 45,
    "confirmed": 280,
    "declined": 15
  },
  "push_subscriptions": {
    "total": 89
  },
  "auth_config": {
    "email_enabled": true,
    "google_enabled": false,
    "email_provider": "resend",
    "email_configured": true,
    "push_configured": true
  }
}
```

Implementation: ~6 simple `COUNT(*)` queries. No caching needed at Rooster's scale.

#### User Management

```
GET    /api/admin/users?page=1&per_page=20&search=john&status=active&sort=created_at&order=desc
GET    /api/admin/users/{user_id}
POST   /api/admin/users/{user_id}/deactivate
POST   /api/admin/users/{user_id}/reactivate
POST   /api/admin/users/{user_id}/promote-admin
POST   /api/admin/users/{user_id}/demote-admin
```

List response:
```json
{
  "users": [...],
  "total": 142,
  "page": 1,
  "per_page": 20,
  "pages": 8
}
```

User detail includes organisation and team memberships with roles.

#### Auth Config Management

```
GET  /api/admin/config
PUT  /api/admin/config
```

GET returns current auth settings (from DB if row exists, else env vars).
PUT updates the `auth_settings` row. Validates:
- Cannot disable all auth methods (unless `AUTH_FORCE_EMAIL_ENABLED` is set)
- Enabling Google requires non-empty `google_client_id`

#### Organisation Overview

```
GET /api/admin/organisations?page=1&per_page=20&search=church
```

Read-only. Returns orgs with member count, team count, created date.

### 3.3 Permission Model

New FastAPI dependency following existing `CurrentUser` pattern:

```python
# In app/api/deps.py:

async def require_superadmin(current_user: CurrentUser) -> User:
    if not current_user.is_superadmin:
        raise HTTPException(status_code=403, detail="Superadmin access required")
    return current_user

SuperAdmin = Annotated[User, Depends(require_superadmin)]
```

Add deactivation check to existing `get_current_user`:

```python
if user.is_deactivated:
    raise HTTPException(status_code=403, detail="Account has been deactivated")
```

Add `"superadmin"` to roles in `AuthService.get_user_roles()` so the frontend receives it in the user response.

### 3.4 First-Run Setup Endpoints

Two new public endpoints handle the onboarding flow:

#### `GET /auth/setup-required`

No authentication required. Returns:

```json
{ "setup_required": true }
```

Implementation: `SELECT COUNT(*) FROM users WHERE is_placeholder = false`. Returns `true` if count is 0. Minimal payload -- no user counts or details exposed.

#### `POST /auth/setup`

No authentication required. Creates the first user as sys admin.

Request:
```json
{
  "name": "Charles Verdad",
  "email": "charles@example.com",
  "password": "mysecurepassword",
  "organisation_name": "St. Mary's Anglican"
}
```

Response: Same shape as `/auth/login` (JWT token + user object).

**Guards**:
- Returns **409 Conflict** if any non-placeholder users exist. This is the real protection -- the frontend check is just UX.
- `organisation_name` is optional. If provided, creates an organisation with the user as admin.
- Password minimum 8 characters.
- The created user has `is_superadmin=true`.

**Why not `SUPERADMIN_EMAIL` env var?** The onboarding flow is superior because:
- No env var to configure before first deploy
- No mismatch between env var email and actual registration email
- Self-contained: the app bootstraps itself without external configuration
- Better UX: admin sees a welcome screen, not a generic login form

### 3.5 Integration with Existing `/auth/config`

The existing `GET /auth/config` endpoint (used by the login screen) must read from the `auth_settings` table instead of `get_settings()`:

```python
@router.get("/config", response_model=AuthConfigResponse)
async def get_auth_config(db: DbSession) -> AuthConfigResponse:
    # Check DB first, fall back to env vars
    row = await db.execute(select(AuthSettings).where(AuthSettings.id == 1))
    auth = row.scalar_one_or_none()
    settings = get_settings()

    email_enabled = auth.email_enabled if auth else settings.auth_email_enabled
    google_enabled = auth.google_enabled if auth else settings.auth_google_enabled
    google_client_id = (auth.google_client_id if auth else settings.google_client_id) if google_enabled else None

    # Emergency override
    if settings.auth_force_email_enabled:
        email_enabled = True

    return AuthConfigResponse(
        email_enabled=email_enabled,
        google_enabled=google_enabled,
        google_client_id=google_client_id,
    )
```

Same pattern applies to the login/register endpoint guards.

### 3.6 Migration

Single Alembic migration:

```python
"""Add sys admin support"""

def upgrade():
    # 1. Add columns to users
    op.add_column('users', sa.Column('is_superadmin', sa.Boolean(),
                  nullable=False, server_default='false'))
    op.add_column('users', sa.Column('is_deactivated', sa.Boolean(),
                  nullable=False, server_default='false'))

    # 2. Create auth_settings table
    op.create_table('auth_settings',
        sa.Column('id', sa.Integer(), primary_key=True),
        sa.Column('email_enabled', sa.Boolean(), nullable=False, server_default='true'),
        sa.Column('google_enabled', sa.Boolean(), nullable=False, server_default='false'),
        sa.Column('google_client_id', sa.String(500), nullable=True),
        sa.Column('updated_by_id', sa.Uuid(),
                  sa.ForeignKey('users.id', ondelete='SET NULL'), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
    )

def downgrade():
    op.drop_table('auth_settings')
    op.drop_column('users', 'is_deactivated')
    op.drop_column('users', 'is_superadmin')
```

**Zero breaking changes**: empty `auth_settings` table falls through to env var defaults.

---

## 4. Critical Review & Risk Analysis

### 4.1 Concerns (by severity)

#### HIGH: Auth Lockout Risk

**Problem**: Runtime auth toggles can lock everyone out. Admin disables email, Google breaks -- nobody can log in.

**Mitigations**:
- `AUTH_FORCE_EMAIL_ENABLED=true` env var always overrides DB state
- UI prevents disabling all auth methods simultaneously
- Auth config changes require re-entering admin password
- Env vars continue to work as defaults (DB is purely additive)

#### HIGH: Scope vs Launch Priority

**Problem**: The PRD deferred admin features. This is substantial new scope.

**Resolution**: Phase the implementation (see Section 5). Phase 1 is minimal: user model changes, stats endpoint, config endpoint, basic user list. The dashboard UI is simple cards, not complex charts.

#### MEDIUM: Token Validity After Deactivation

**Problem**: Deactivated users keep existing JWTs valid for up to 7 days.

**Mitigation**: Check `is_deactivated` on every authenticated request in `get_current_user`. This ensures deactivation takes effect immediately, not just at next login.

#### MEDIUM: Org Admin vs Sys Admin Confusion

**Problem**: Single-church deployments will have the same person as both org admin and sys admin, seeing two different admin interfaces.

**Mitigation**: Clear labelling. Sys admin is for "system configuration" (auth, infrastructure). Org admin is for "organisation management" (members, teams). Settings screen groups them clearly. For many deployments, only the sys admin panel entry point is visible (org settings is accessed from the org header on My Teams screen).

#### LOW: Audit Logging Deferred

**Decision**: Defer audit logs to Phase 2. Standard FastAPI application logs are sufficient for debugging at current scale. Adding audit infrastructure pre-launch is premature.

#### LOW: Email Statistics Deferred

**Decision**: No email tracking infrastructure. Config tab shows read-only status (configured/not configured, provider name). Delivery tracking requires webhook handlers and a new table -- out of scope.

### 4.2 Key Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Admin role | `is_superadmin` bool on User | Simple, no extra JOINs, matches `is_placeholder` pattern |
| Config storage | Single-row typed `auth_settings` table | Avoids overengineering a generic key-value store for 3 values |
| Config fallback | DB row present -> use it, else env vars | Zero breaking changes for existing deployments |
| Emergency override | `AUTH_FORCE_EMAIL_ENABLED` env var | Prevents lockout regardless of DB state |
| Bootstrap | First-run onboarding flow at `/setup` | Self-contained, no env vars needed, better UX than CLI or env var |
| Stats | Single aggregated endpoint | Fewer round trips, simpler frontend |
| User deactivation | `is_deactivated` bool, checked every request | Soft-delete preserves history, immediate effect |
| Mobile admin | Desktop only for MVP | Admin dashboards are bad on mobile, doubles effort |
| Audit logs | Deferred to Phase 2 | Premature for pre-launch church app |
| Email stats | Deferred to Phase 2 | Requires new infrastructure (webhooks, log table) |

---

## 5. Recommended Implementation Plan

### Phase 1: MVP Admin Panel

**Backend**:
1. Add `is_superadmin` and `is_deactivated` to User model + migration
2. Create `auth_settings` table + migration
3. Add `auth_force_email_enabled` to Settings
4. Add `GET /auth/setup-required` endpoint (public, checks if any users exist)
5. Add `POST /auth/setup` endpoint (public, creates first user as superadmin, returns JWT, 409 if users exist)
6. Add `require_superadmin` dependency + deactivation check in `get_current_user`
7. Add `"superadmin"` to user roles in `get_user_roles()`
8. Create admin API: `GET /admin/stats`, `GET/PUT /admin/config`
9. Create admin user API: list, detail, deactivate, reactivate, promote, demote
10. Create admin org API: list with counts (read-only)
11. Update `GET /auth/config` to read from `auth_settings` table
12. Update login/register guards to read from `auth_settings` table
13. Add tests for all new endpoints (including setup flow)

**Frontend**:
1. Add `isSuperadmin` and `setupRequired` to User model / AuthProvider
2. Create setup screen (`/setup`) with name, email, password, optional org name
3. Update AuthProvider to fetch `/auth/setup-required` on init
4. Update GoRouter to redirect to `/setup` when `setupRequired` is true
5. Create `AdminProvider`
6. Create admin service (API calls)
7. Create Dashboard screen (metric cards + auth status + org list)
8. Create Users screen (DataTable, search, filter, detail panel)
9. Create Config screen (auth toggles + read-only email/push status)
10. Add admin routes to GoRouter with guard
11. Add "System Admin" entry in Settings screen

### Phase 2: Polish (post-launch)
- Audit log table + recent activity feed on dashboard
- Email delivery tracking (log table, webhook handler, stats)
- User activity metrics (last login, assignment response rates)
- Mobile-responsive admin views
- Org detail drill-down from dashboard
- Export user list as CSV
- Config change history

---

## 6. File Change Summary

| File | Action | Description |
|------|--------|-------------|
| `backend/app/models/user.py` | Edit | Add `is_superadmin`, `is_deactivated` |
| `backend/app/models/system_config.py` | Create | `AuthSettings` model |
| `backend/app/models/__init__.py` | Edit | Export new model |
| `backend/alembic/versions/<new>.py` | Create | Migration for new columns + table |
| `backend/app/core/config.py` | Edit | Add `auth_force_email_enabled` |
| `backend/app/api/deps.py` | Edit | Add `require_superadmin`, deactivation check |
| `backend/app/services/auth.py` | Edit | Add `superadmin` to roles |
| `backend/app/services/admin.py` | Create | AdminService (stats, user mgmt) |
| `backend/app/schemas/admin.py` | Create | Admin request/response schemas |
| `backend/app/api/admin.py` | Create | Admin router (`/api/admin/*`) |
| `backend/app/api/auth.py` | Edit | Add setup endpoints, read config from `auth_settings` table |
| `backend/app/schemas/user.py` | Edit | Add `SetupRequest` schema |
| `backend/app/main.py` | Edit | Include admin router |
| `backend/tests/test_admin.py` | Create | Tests for admin endpoints |
| `backend/tests/test_auth.py` | Edit | Add tests for setup flow |
| `frontend/.../models/user.dart` | Edit | Add `isSuperadmin` |
| `frontend/.../providers/auth_provider.dart` | Edit | Add `setupRequired` flag, fetch `/auth/setup-required` |
| `frontend/.../screens/auth/setup_screen.dart` | Create | First-run onboarding screen |
| `frontend/.../services/admin_service.dart` | Create | Admin API service |
| `frontend/.../providers/admin_provider.dart` | Create | Admin state management |
| `frontend/.../screens/admin/admin_dashboard.dart` | Create | Dashboard screen |
| `frontend/.../screens/admin/admin_users.dart` | Create | Users screen |
| `frontend/.../screens/admin/admin_config.dart` | Create | Config screen |
| `frontend/.../screens/admin/admin_shell.dart` | Create | Tab scaffold |
| `frontend/.../screens/settings/settings_screen.dart` | Edit | Add admin entry point |
| `frontend/.../router/app_router.dart` | Edit | Add `/setup` route + admin routes with guards |
