# Phase 2 Plan: Wire All User Flows End-to-End

**Branch**: `feat/phase-2-wired-flows` (from `main`)

**Goal**: Every screen, button, and tap target leads somewhere meaningful. No floating TODOs or dead-end navigation.

---

## Identified Gaps (from code review)

| # | Location | Issue |
|---|----------|-------|
| 1 | `roster_detail_screen.dart:174` | `// TODO: Navigate to event detail` - event cards do nothing |
| 2 | `team_detail_screen.dart:54` | `// TODO: Team settings` - gear icon does nothing |
| 3 | `my_teams_screen.dart:53` | `// TODO: Browse teams` - button does nothing |
| 4 | `assign_volunteers_sheet.dart:98` | `// TODO: Add unavailability logic` - unavailable list always empty |
| 5 | `accept_invite_screen.dart:106` | After invite accept, navigates to `/home` but no team context passed |
| 6 | No `EventDetailScreen` exists | Events can't be viewed or managed individually |
| 7 | No member assignment visibility | MemberDetailScreen doesn't show assignments |

---

## Implementation Tasks (in order)

### Task 1: Create Event Detail Screen
**New file**: `frontend/.../screens/roster/event_detail_screen.dart`

- Shows: event date, roster name, slot status (X/Y filled), assignment list with status badges
- Actions: assign volunteer (reuse `AssignVolunteersSheet`), remove volunteer, cancel event
- Permission-gated: only team leads see management actions

**Modify**:
- `roster_detail_screen.dart:174` - wire event card tap to navigate to event detail
- `main.dart` - add `/event-detail` route
- `providers/roster_provider.dart` - add `fetchEventDetail()`, `removeEventAssignment()`, `cancelEvent()` methods
- `services/roster_service.dart` - add corresponding API calls

**Backend**: All endpoints already exist (`GET/PATCH/DELETE` on roster events and event assignments). No backend changes needed.

**Tests**: Backend tests for event endpoints (verify existing coverage in `test_rosters.py`). Frontend widget test for EventDetailScreen.

---

### Task 2: Team Settings Screen
**New file**: `frontend/.../screens/teams/team_settings_screen.dart`

- Edit team name (`PATCH /teams/{team_id}`)
- Member permissions management (`PATCH /teams/{team_id}/members/{user_id}/permissions`)
- Delete team with confirmation (`DELETE /teams/{team_id}`)
- Only accessible to users with `manage_team` permission

**Modify**:
- `team_detail_screen.dart:54` - wire gear icon to navigate to settings
- `main.dart` - add `/team-settings` route
- `providers/team_provider.dart` - add `updateTeam()`, `updateMemberPermissions()`, `deleteTeam()`
- `services/team_service.dart` - add corresponding API calls

**Backend**: All endpoints already exist. No backend changes needed.

**Tests**: Backend permission tests (verify existing in `test_teams.py` and `test_permissions.py`). Frontend widget test.

---

### Task 3: Unavailability-Aware Assign Volunteers
**Backend change needed**: New endpoint `GET /api/dashboard/teams/{team_id}/availability?date=YYYY-MM-DD` - already exists at `/api/dashboard/teams/{team_id}/availability` but needs to support a specific date filter.

**Modify**:
- `backend/app/api/dashboard.py` - add `date` query param to team availability endpoint
- `backend/app/services/dashboard.py` - filter unavailability by date
- `assign_volunteers_sheet.dart` - accept `eventDate` param, fetch unavailabilities, split members into available/unavailable with reasons, disable unavailable member selection
- `providers/availability_provider.dart` or `team_provider.dart` - add team availability fetch

**Tests**: Backend test for date-filtered availability. Frontend widget test confirming split.

---

### Task 4: Replace "Browse Teams" with "Join via Invite Link"
The "Browse All Teams" concept doesn't fit a church app. Replace with invite-link entry. The invite URL always contains the token (e.g. `https://rooster.app/invite/TOKEN` or `rooster://invite/TOKEN`). Auto-extract the token from the pasted URL.

**Modify**:
- `my_teams_screen.dart:51-57` - replace "Browse All Teams" button with "Have an invite link?" that opens a dialog with a text field. Parse the pasted URL to extract the token automatically (support both full URL and bare token).
- `home_screen.dart:224-261` - add "Have an invite link?" secondary button to the first-time empty state
- Add a helper function `extractTokenFromInviteUrl(String input)` that handles: full HTTPS URLs, app scheme URLs, and bare tokens
- On token extraction, navigate to `AcceptInviteScreen(token: token)`

**No backend changes needed** - invite validation/acceptance endpoints already exist.

**Tests**: Unit test for `extractTokenFromInviteUrl` with various URL formats. Frontend widget test for invite link entry flow.

---

### Task 5: Post-Invite Navigation to Team
After accepting an invite, the user should land on their new team's detail page, not just `/home`.

**Backend change**:
- `backend/app/schemas/invite.py` - add `team_id` and `team_name` to `InviteAcceptResponse`
- `backend/app/services/invite.py` - include team_id in accept response
- `backend/app/api/invites.py` - pass through team_id

**Frontend change**:
- `accept_invite_screen.dart:89-106` - extract `team_id` from response, navigate to `/team-detail` with team_id instead of `/home`
- `services/invite_service.dart` - parse team_id from response

**Tests**: Backend test verifying accept response includes team_id. Frontend navigation test.

---

### Task 6: Member Assignment Visibility (Team Lead View)
Backend endpoint already exists: `GET /api/teams/{team_id}/members/{user_id}/assignments`

**Modify**:
- `frontend/.../screens/teams/member_detail_screen.dart` - add assignments section showing upcoming assignments with status
- `providers/team_provider.dart` - add `fetchMemberAssignments()` method
- `services/team_service.dart` - add `getMemberAssignments()` API call

**Tests**: Backend test for member assignments endpoint. Frontend widget test.

---

### Task 7: Notification Settings Toggle + Local Push Attempt
Try PWA-style web push notifications via the Notifications API on localhost. If browser push requires a production HTTPS domain or service worker setup that can't work locally, fall back to logging "push notification sent" to the console and defer real push to Phase 3.

**Approach**:
1. Add a Flutter web service worker + web manifest to enable "Add to Home Screen" (PWA)
2. Try `dart:html` Notification API or `flutter_local_notifications` for web
3. If local push works: fire a browser notification when an assignment is created
4. If not feasible: log to console and add a `// PHASE 3: Replace with real push` comment

**Modify**:
- `frontend/.../screens/settings/settings_screen.dart` - wire notification toggle to SharedPreferences
- `providers/notification_provider.dart` - respect enabled flag, attempt browser notification on new notification
- `frontend/rooster_app/web/manifest.json` - PWA manifest if needed
- `frontend/rooster_app/web/index.html` - service worker registration if needed

**Tests**: Widget test for toggle persistence. Manual verification of browser notification prompt.

---

### Task 8: UX Polish Pass
- Consistent error banners with retry on all list screens
- Loading skeletons instead of bare `CircularProgressIndicator`
- Ensure all form buttons disabled during submission
- Pull-to-refresh on `NotificationsScreen` if missing

**Screens to audit**: home, my_teams, team_detail, roster_detail, notifications, availability, settings

---

### Task 9: End-to-End Navigation Audit
Final sweep after all above tasks complete:
- Walk every screen, verify every tap target navigates correctly
- Verify back navigation from all screens
- Test deep link flow: invite link -> AcceptInviteScreen -> team detail
- Test first-time flow: register -> create team -> add member -> create roster -> assign

---

## Execution Strategy

**Sprint 1** (foundation - can be parallel):
- Task 1: Event Detail Screen
- Task 2: Team Settings Screen
- Task 3: Unavailability-Aware Assign
- Task 4: Join via Invite Link

**Sprint 2** (wiring - Task 7 depends on nothing, Tasks 5-6 independent):
- Task 5: Post-Invite Navigation
- Task 6: Member Assignment Visibility
- Task 7: Notification Toggle

**Sprint 3** (polish - sequential, after all above):
- Task 8: UX Polish Pass
- Task 9: Navigation Audit

---

## Verification

After all tasks complete, run these end-to-end flows:

1. **New user flow**: Register -> see welcome card -> create team -> add placeholder member -> create roster -> generate events -> assign volunteer to event -> view event detail
2. **Invite flow**: Send invite to placeholder -> accept invite (paste token or deep link) -> land on team detail -> see teammates and rosters
3. **Assignment flow**: Get assigned -> see notification -> view assignment detail -> accept/decline -> see updated status on home
4. **Team lead flow**: View team -> see members -> tap member -> see their assignments -> tap event -> manage assignments -> remove volunteer -> unavailable members shown correctly
5. **Settings flow**: Toggle notifications -> verify respected -> edit team name -> delete team

Run backend tests: `cd backend && uv run pytest`
Run frontend: `cd frontend/rooster_app && flutter run -d chrome`

---

## Known Issues (to fix)

### 1. Self-assign notification noise
When a lead assigns **themselves** to an event, the UI shows "Notification sent to [person]". Since they are the person, no notification should be sent or displayed. Fix: skip notification creation when the assigning user and assigned user are the same.

### 2. Homepage upcoming events not refreshing on navigation back
Navigating back to the homepage after making changes (e.g. volunteering, assigning) does not refresh the upcoming events list. The home screen needs to re-fetch data when it becomes visible again (e.g. via `didChangeDependencies`, `RouteAware`, or re-fetching in `initState` each time the widget is built).

### 3. SPA state not refreshing; browser refresh loses view
The Flutter app uses Navigator 1.0 — the browser URL never updates when navigating between views. This causes two problems:
- **No in-app refresh**: There is no pull-to-refresh or auto-refresh when returning to a screen, so stale data persists until a manual action triggers a fetch.
- **Browser refresh resets to home**: Hitting the browser refresh button always returns to the homepage (or login) because the URL has no route information. Fixing this properly requires migrating to `go_router` (Navigator 2.0) with URL-synced routes, which is scoped to Phase 3.

**Short-term mitigations** (Phase 2):
- Add data re-fetching when screens become visible (e.g. home screen re-fetches on build/resume).
- Ensure `AuthWrapper` correctly restores login state on refresh (already implemented via `SharedPreferences` token + `fetchCurrentUser`).

**Long-term fix** (Phase 3):
- Migrate to `go_router` with path parameters (`/team/:id`, `/roster/:id`, etc.) so the URL reflects the current view and browser refresh restores the correct screen.
