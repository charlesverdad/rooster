# Plan: Production-Level Notifications

## Requirements Restatement

Upgrade notifications from basic to production-level:
1. Push notifications with **actionable buttons** (Accept/Decline, Acknowledge)
2. In-app notification bell with **unread badge** (already exists, verify working)
3. Notification list styled like Instagram/Facebook — unread items highlighted, highlight clears on read
4. Cover **all important user flows** with appropriate notification types
5. Each notification type has the right **action semantics** (accept/decline vs acknowledge)

## Current State

**Working:**
- `ASSIGNMENT_CREATED` -> in-app + email + push (no push actions)
- `TEAM_JOINED` -> in-app only (no push, no email)
- Notification bell with unread badge count
- Notification list with swipe-to-delete, mark-all-read
- Unread highlight (light blue background)
- Service worker handles push `notificationclick` with generic Open/Dismiss

**Missing / Incomplete:**
- Push notifications have no accept/decline action buttons
- `ASSIGNMENT_REMINDER` type exists but is never triggered (no scheduler)
- No notification when assignment is accepted/declined (team lead never knows)
- No notification when a member is removed from a team
- No notification when invited to a team (only email, no in-app/push)
- `CONFLICT_DETECTED` helper exists but is never called
- Service worker actions are hardcoded to Open/Dismiss

## Notification Matrix

| Event | Recipient | Type | In-App | Push | Push Actions | Email |
|-------|-----------|------|--------|------|-------------|-------|
| New assignment | Assignee | `ASSIGNMENT_CREATED` | Yes | Yes | Accept / Decline | Yes |
| Assignment accepted | Team lead | `ASSIGNMENT_CONFIRMED` | Yes | Yes | Acknowledge | No |
| Assignment declined | Team lead | `ASSIGNMENT_DECLINED` | Yes | Yes | Reassign / Acknowledge | No |
| Reminder: 1 day before | Assignee | `ASSIGNMENT_REMINDER` | Yes | Yes | Acknowledge | No |
| Invited to team | Invitee | `TEAM_INVITE` | Yes | Yes | Acknowledge | Yes (existing) |
| Member joined team | Team lead | `TEAM_JOINED` | Yes | Yes | Acknowledge | No |
| Removed from team | Member | `TEAM_REMOVED` | Yes | No | Acknowledge | No |

### Action Semantics
- **Accept / Decline** -- two-button push for assignment offers. Accept confirms, Decline opens app to the decline flow (needs reason).
- **Reassign / Acknowledge** -- for declined assignments. "Reassign" opens the event page; "Acknowledge" dismisses.
- **Acknowledge** -- single informational notification. Tap opens relevant page.

## Implementation Phases

### Phase 1: Backend -- New Notification Types & Triggers

**`backend/app/models/notification.py`**
- Add to `NotificationType` enum: `ASSIGNMENT_CONFIRMED`, `ASSIGNMENT_DECLINED`, `TEAM_INVITE`, `TEAM_REMOVED`

**`backend/app/services/notification.py`**
- Add helper methods:
  - `notify_assignment_confirmed(assignment, team_lead_user_id)` -- in-app + push to team lead
  - `notify_assignment_declined(assignment, team_lead_user_id)` -- in-app + push to team lead
  - `notify_team_invite(user_id, team_name, team_id)` -- in-app + push to invitee
  - `notify_team_removed(user_id, team_name, team_id)` -- in-app only
- Update `notify_assignment_created_with_email()` push payload to include action data

**`backend/app/services/push.py`**
- Update `send_to_user()` to accept optional `actions` list and `tag` for notification grouping/replacement
- Pass actions through to the push payload so the service worker can render them

**`backend/app/api/rosters.py`**
- In `update_event_assignment()`: when status changes to `confirmed` or `declined`, notify the team lead

**`backend/app/api/invites.py`**
- In the send-invite endpoint: call `notify_team_invite()` if the user has an account

**`backend/app/services/team.py`**
- In `remove_member()`: call `notify_team_removed()`

### Phase 2: Backend -- Push Action Endpoints

**`backend/app/api/rosters.py`**
- Add `POST /event-assignments/{id}/accept` -- lightweight endpoint for push action (confirms assignment)
- Add `POST /event-assignments/{id}/decline` -- lightweight endpoint for push action (declines assignment)

These enable the service worker to call the API directly when the user taps Accept/Decline without opening the app.

### Phase 3: Service Worker -- Actionable Push Notifications

**`frontend/rooster_app/web/service-worker.js`**
- Parse `actions` array from push payload and pass to `showNotification()`
- Handle action-specific clicks:
  - `accept` action -> fetch POST to `/api/event-assignments/{id}/accept` with credentials
  - `decline` action -> open the app to `/assignments/{id}` (decline needs a reason via UI)
  - `reassign` action -> open the app to `/events/{id}`
  - Default tap -> open the app to the notification URL
- Add `tag` support so updated notifications replace previous ones

### Phase 4: Frontend -- Notification UI Polish

**`frontend/rooster_app/lib/models/notification.dart`**
- Add type normalization for new types: `assignment_confirmed` -> `response`, `assignment_declined` -> `alert`, `team_invite` -> `team`, `team_removed` -> `team`

**`frontend/rooster_app/lib/screens/notifications/notifications_screen.dart`**
- Add icons/colors for new types (`alert` type with red/warning icon for declines)
- Verify unread highlight styling matches requirement (highlighted until read)

### Phase 5: Database Migration

- The `NotificationType` enum is stored as `VARCHAR` in PostgreSQL -- no migration needed for new string values. Verify column type.

### Phase 6: PRD Update

**`PRD.md`**
- Update F8: Notifications section with the full notification matrix
- Note that `ASSIGNMENT_REMINDER` is deferred (requires scheduler)

## Files to Modify

| File | Change |
|------|--------|
| `backend/app/models/notification.py` | Add 4 new NotificationType enum values |
| `backend/app/services/notification.py` | Add 4 notify_* helpers, update push payloads with actions |
| `backend/app/services/push.py` | Support `actions` and `tag` in push payload |
| `backend/app/api/rosters.py` | Trigger notifications on accept/decline, add accept/decline endpoints |
| `backend/app/api/invites.py` | Trigger team invite notification |
| `backend/app/services/team.py` | Trigger team removed notification |
| `frontend/rooster_app/web/service-worker.js` | Handle action buttons, API callbacks |
| `frontend/rooster_app/lib/models/notification.dart` | Normalize new types |
| `frontend/rooster_app/lib/screens/notifications/notifications_screen.dart` | Icons/colors for new types |
| `PRD.md` | Update F8 notification spec |

## Risks

- **MEDIUM**: Service worker accept action requires fetching the API with auth credentials from the SW context. The SW can use `fetch` with `credentials: 'include'` if cookies are used, or we store the auth token in IndexedDB. Current auth uses JWT in SharedPreferences -- will need to bridge this for SW access.
- **LOW**: Push payload size limit (4KB) -- our payloads are small text, well within limits.
- **DEFERRED**: `ASSIGNMENT_REMINDER` requires a background scheduler (cron/Celery). Out of scope for this PR.

## Out of Scope

- Assignment reminder (1 day before) -- requires background scheduler
- Weekly digest email -- requires background scheduler
- Conflict detection notifications -- requires availability checking at assignment time
