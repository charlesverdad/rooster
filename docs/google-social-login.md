# Google Social Login - Implementation Plan

## Context

Rooster currently only supports email/password auth. We need to add Google OAuth login with env vars to enable/disable each auth method independently, so admins can force Google-only login.

**Flow**: Flutter `google_sign_in` package gets a Google ID token → sends to backend → backend verifies with `google-auth` library → creates/links user → returns same JWT as email/password flow.

---

## Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `AUTH_EMAIL_ENABLED` | `true` | Enable email/password login & registration |
| `AUTH_GOOGLE_ENABLED` | `false` | Enable Google OAuth login |
| `GOOGLE_CLIENT_ID` | `""` | Google OAuth client ID |

To force Google-only: `AUTH_EMAIL_ENABLED=false AUTH_GOOGLE_ENABLED=true GOOGLE_CLIENT_ID=xxx`

---

## Phase 1: Backend

### 1a. Config (`backend/app/core/config.py`)
Add to `Settings` class:
```python
auth_email_enabled: bool = True
auth_google_enabled: bool = False
google_client_id: str = ""
```

### 1b. User model (`backend/app/models/user.py`)
Add column:
```python
google_id: Mapped[str | None] = mapped_column(String(255), unique=True, index=True, nullable=True)
```

### 1c. Migration
`just db-migration "add google_id to users"` — adds nullable `google_id` column with unique index.

### 1d. Dependency (`backend/pyproject.toml`)
Add: `"google-auth>=2.25.0"`

### 1e. Schemas (`backend/app/schemas/user.py`)
Add:
```python
class GoogleLoginRequest(BaseModel):
    id_token: str

class AuthConfigResponse(BaseModel):
    email_enabled: bool
    google_enabled: bool
    google_client_id: str | None = None
```

### 1f. Google auth service (NEW `backend/app/services/google_auth.py`)
- `verify_google_id_token(token: str) -> dict` — uses `google.oauth2.id_token.verify_oauth2_token()`, validates issuer and `email_verified`, raises `GoogleAuthError` on failure.

### 1g. Auth service (`backend/app/services/auth.py`)
- Add `get_user_by_google_id(google_id)` method
- Add `authenticate_or_create_google_user(google_id, email, name)` with 4 cases:
  1. Already linked by `google_id` → return existing
  2. Existing registered user by email, no `google_id` → link and return
  3. Placeholder user by email → convert to full user with Google, return
  4. No user exists → create new (no password_hash)
- Fix `authenticate_user()` to explicitly reject users with no `password_hash`

### 1h. Auth endpoints (`backend/app/api/auth.py`)
- **`GET /auth/config`** (public, no auth) — returns `AuthConfigResponse`
- **`POST /auth/google`** — verifies Google ID token, calls `authenticate_or_create_google_user`, handles pending invites, returns JWT `Token`
- **Guard `POST /auth/register`** — return 403 if `auth_email_enabled=false`
- **Guard `POST /auth/login`** — return 403 if `auth_email_enabled=false`; also detect Google-only users trying email login → return helpful error message

### 1i. Tests (`backend/tests/test_auth.py`)
- Test `/auth/config` returns correct flags
- Test `/auth/google` disabled → 403
- Test `/auth/login` disabled → 403
- Test `/auth/register` disabled → 403
- Test Google login creates new user (mock `verify_google_id_token`)
- Test Google login links existing email user
- Test Google-only user can't email login → helpful error

---

## Phase 2: Frontend

### 2a. Dependency (`frontend/rooster_app/pubspec.yaml`)
Add: `google_sign_in: ^6.2.1`

### 2b. Config (`frontend/rooster_app/lib/config/api_config.dart`)
Add:
```dart
static const String googleClientId = String.fromEnvironment('GOOGLE_CLIENT_ID', defaultValue: '');
```

### 2c. Auth config model (NEW `frontend/rooster_app/lib/models/auth_config.dart`)
```dart
class AuthConfig {
  final bool emailEnabled;
  final bool googleEnabled;
  final String? googleClientId;
  // fromJson, defaults factory
}
```

### 2d. Auth provider (`frontend/rooster_app/lib/providers/auth_provider.dart`)
- Add `AuthConfig _authConfig` field + getter
- In `init()`: call `_fetchAuthConfig()` before loading token (GET `/auth/config`, no auth needed)
- Add `loginWithGoogle()` method:
  1. `GoogleSignIn(clientId: ..., scopes: ['email', 'profile']).signIn()`
  2. Get `idToken` from `googleAuth.idToken`
  3. POST to `/auth/google` with `{id_token: idToken}`
  4. Save token, fetch user, re-subscribe push

### 2e. Login screen (`frontend/rooster_app/lib/screens/auth/login_screen.dart`)
- Read `authProvider.authConfig` to conditionally show:
  - Google button (when `googleEnabled`)
  - "or" divider (when both enabled)
  - Email/password form (when `emailEnabled`)
  - Register link (when `emailEnabled`)
- Google button: `OutlinedButton` with Google "G" logo asset + "Continue with Google"

### 2f. Register screen (`frontend/rooster_app/lib/screens/auth/register_screen.dart`)
- If `!emailEnabled`: show message "Sign up with Google on the login screen" + back button
- If both enabled: add Google button at top with divider, keep existing form

### 2g. Google logo asset
Add `assets/google_logo.png` (the standard Google "G" icon) and reference in `pubspec.yaml` assets.

### 2h. Build changes (`frontend/Dockerfile`)
Add `GOOGLE_CLIENT_ID` build arg, pass as `--dart-define=GOOGLE_CLIENT_ID=${GOOGLE_CLIENT_ID}`

---

## Edge Cases

| Scenario | Handling |
|----------|----------|
| Email user tries Google with same email | Links accounts — sets `google_id` on existing user |
| Google user tries email login (no password) | Returns helpful error: "This account uses Google sign-in" |
| Placeholder user signs in via Google | Converts placeholder to full user with Google |
| Both auth methods disabled | Startup warning; no one can log in |
| Google ID token expired/invalid | Returns 401 with error message |

---

## File Change Summary

| File | Action |
|------|--------|
| `backend/app/core/config.py` | Edit — add 3 env vars |
| `backend/app/models/user.py` | Edit — add `google_id` column |
| `backend/alembic/versions/<new>.py` | Create — migration |
| `backend/pyproject.toml` | Edit — add `google-auth` |
| `backend/app/schemas/user.py` | Edit — add 2 schemas |
| `backend/app/services/google_auth.py` | Create — token verification |
| `backend/app/services/auth.py` | Edit — add Google user methods |
| `backend/app/api/auth.py` | Edit — add 2 endpoints, guard 2 existing |
| `backend/tests/test_auth.py` | Edit — add tests |
| `frontend/rooster_app/pubspec.yaml` | Edit — add `google_sign_in` |
| `frontend/rooster_app/lib/config/api_config.dart` | Edit — add `googleClientId` |
| `frontend/rooster_app/lib/models/auth_config.dart` | Create — AuthConfig model |
| `frontend/rooster_app/lib/providers/auth_provider.dart` | Edit — add Google login |
| `frontend/rooster_app/lib/screens/auth/login_screen.dart` | Edit — conditional UI |
| `frontend/rooster_app/lib/screens/auth/register_screen.dart` | Edit — conditional UI |
| `frontend/rooster_app/assets/google_logo.png` | Create — Google "G" icon |
| `frontend/Dockerfile` | Edit — add build arg |

---

## Verification

1. `just db-migrate` — migration runs
2. `just test-backend` — all tests pass
3. `flutter analyze` — no errors
4. Manual test with `AUTH_GOOGLE_ENABLED=false` — no Google button shown, email login works as before
5. Manual test with both enabled — Google button + email form shown, both work
6. Manual test with `AUTH_EMAIL_ENABLED=false AUTH_GOOGLE_ENABLED=true` — only Google button shown, `/auth/login` returns 403
