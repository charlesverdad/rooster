# Frontend-Backend Integration TODO

## Overview
Connect the Flutter frontend to the FastAPI backend, replacing all mock data with real API calls.

**STATUS: COMPLETED**

---

## Phase 1: Core Infrastructure (HIGH PRIORITY) ✅

### 1.1 Update Data Models
- [x] Update `RosterEvent` model to match backend `RosterEventResponse`
- [x] Create `EventAssignment` model to match backend `EventAssignmentResponse`
- [x] Create `EventAssignmentDetail` model for detailed assignment view
- [x] Update `Roster` model - verified `startDate` serialization
- [x] Add `TeamMember` model to replace Map<String, dynamic>
- [x] Update `Team` model with `role` field for current user's role

### 1.2 API Service Layer
- [x] Create `team_service.dart` for team API calls
- [x] Create `roster_service.dart` for roster/event API calls
- [x] Create `assignment_service.dart` for event-assignment API calls
- [x] Create `notification_service.dart` for notification API calls
- [x] Create `invite_service.dart` for invite API calls
- [x] Add consistent error handling across all services (ApiException class)

---

## Phase 2: Provider Integration (HIGH PRIORITY) ✅

### 2.1 TeamProvider - Full API Integration
- [x] `fetchMyTeams()` → GET `/teams`
- [x] `fetchTeamDetail()` → GET `/teams/{teamId}`
- [x] `fetchTeamMembers()` → GET `/teams/{teamId}/members`
- [x] `addPlaceholderMember()` → POST `/teams/{teamId}/members/placeholder`
- [x] `sendInvite()` → POST `/invites/team/{teamId}/user/{userId}`
- [x] Remove mock data usage

### 2.2 RosterProvider - Full API Integration
- [x] `fetchTeamRosters()` → GET `/rosters/team/{teamId}`
- [x] `fetchRosterDetail()` → GET `/rosters/{rosterId}`
- [x] `fetchRosterEvents()` → GET `/rosters/{rosterId}/events`
- [x] `createRoster()` → POST `/rosters` (with start_date, end conditions)
- [x] `generateMoreEvents()` → POST `/rosters/{rosterId}/events/generate`
- [x] `assignVolunteerToEvent()` → POST `/rosters/events/{eventId}/assignments`
- [x] Remove mock data and local event generation

### 2.3 AssignmentProvider - Full API Integration
- [x] Rename to use EventAssignments (backend's current model)
- [x] `fetchMyAssignments()` → GET `/rosters/event-assignments/my`
- [x] `fetchAssignmentDetail()` → GET `/rosters/event-assignments/{id}/detail`
- [x] `updateAssignmentStatus()` → PATCH `/rosters/event-assignments/{id}`
- [x] Remove mock data usage

### 2.4 NotificationProvider - Full API Integration
- [x] `fetchNotifications()` → GET `/notifications`
- [x] `markAsRead()` → POST `/notifications/{id}/read`
- [x] `markAllAsRead()` → POST `/notifications/read-all`
- [x] `deleteNotification()` → DELETE `/notifications/{id}`
- [x] Remove mock data usage

---

## Phase 3: Screen Updates (MEDIUM PRIORITY) ✅

### 3.1 Assignment Detail Screen
- [x] Fetch detail from `/rosters/event-assignments/{id}/detail`
- [x] Use real co-volunteers data from API
- [x] Use real team lead data from API
- [x] Remove hardcoded mock data

### 3.2 Roster Detail Screen
- [x] Update to use new `RosterEvent` model fields
- [x] Handle events without time (date only)
- [x] Updated to use `event.date` instead of `event.dateTime`

### 3.3 Home Screen
- [x] Wire up to real assignment data via AssignmentProvider
- [x] Show actual pending/upcoming assignments

### 3.4 Other Screens Updated
- [x] my_teams_screen.dart - uses TeamProvider
- [x] team_detail_screen.dart - uses TeamProvider + RosterProvider
- [x] availability_screen.dart - uses EventAssignment model
- [x] notifications_screen.dart - fixed navigation to use assignmentId
- [x] create_roster_screen.dart - updated for new Roster model

---

## Phase 4: Error Handling & Polish (MEDIUM PRIORITY) - Partial ✅

### 4.1 Error Handling
- [x] Add try-catch with user-friendly error messages in all providers
- [x] ApiException class for consistent error handling
- [ ] Handle 401 (unauthorized) - redirect to login (TODO: implement in ApiClient)
- [ ] Handle 403 (forbidden) - show permission error
- [ ] Handle 404 (not found) - show not found message
- [ ] Handle network errors - show offline/retry message

### 4.2 Loading States
- [x] Add granular loading states in providers
- [x] Show loading indicators during API calls
- [ ] Disable buttons during submissions (TODO)

### 4.3 Data Refresh
- [x] Pull-to-refresh on list screens
- [x] Auto-refresh after mutations (create, update, delete)

---

## Phase 5: Cleanup (LOW PRIORITY) ✅

### 5.1 Remove Mock Data
- [x] Delete `lib/mock_data/mock_data.dart`
- [x] Remove all MockData imports
- [x] Remove unused mock-related code

### 5.2 Code Quality
- [x] Ensure consistent naming conventions
- [x] Add proper null safety handling
- [x] Review and clean up unused imports

---

## Backend Changes Made

### EventAssignmentResponse Schema Updated
Added fields to include event details for display:
- `event_date: Optional[date]`
- `roster_name: Optional[str]`
- `team_name: Optional[str]`

### API Endpoint Updated
`/rosters/event-assignments/my` now returns event_date and roster_name for each assignment.

---

## Files Created/Modified

### New Files
- `lib/models/event_assignment.dart` - EventAssignment, EventAssignmentDetail, CoVolunteer, TeamLead
- `lib/models/team_member.dart` - TeamMember model
- `lib/services/team_service.dart` - TeamService + ApiException
- `lib/services/roster_service.dart` - RosterService
- `lib/services/assignment_service.dart` - AssignmentService
- `lib/services/notification_service.dart` - NotificationService
- `lib/services/invite_service.dart` - InviteService + Invite model

### Modified Files
- `lib/models/roster_event.dart` - Updated to match backend
- `lib/models/team.dart` - Added role field
- `lib/models/notification.dart` - Fixed fromJson for UUIDs
- `lib/providers/team_provider.dart` - Full API integration
- `lib/providers/roster_provider.dart` - Full API integration
- `lib/providers/assignment_provider.dart` - Full API integration
- `lib/providers/notification_provider.dart` - Full API integration
- `lib/screens/home/home_screen.dart` - Uses EventAssignment
- `lib/screens/assignments/assignment_detail_screen.dart` - Uses EventAssignmentDetail
- `lib/screens/roster/roster_detail_screen.dart` - Uses new RosterEvent fields
- `lib/screens/availability/availability_screen.dart` - Uses EventAssignment
- `lib/screens/notifications/notifications_screen.dart` - Fixed navigation
- `lib/screens/teams/my_teams_screen.dart` - Uses TeamProvider
- `lib/screens/teams/team_detail_screen.dart` - Uses TeamProvider
- `lib/screens/roster/assign_volunteers_sheet.dart` - Uses TeamMember model
- `lib/screens/roster/create_roster_screen.dart` - Updated for new Roster model
- `lib/widgets/team_lead_section.dart` - Uses API for unfilled events
- `lib/widgets/upcoming_assignment_card.dart` - Uses EventAssignment
- `lib/widgets/assignment_action_card.dart` - Uses EventAssignment

### Deleted Files
- `lib/mock_data/mock_data.dart` - Removed

### Backend Changes
- `backend/app/schemas/roster.py` - Added event_date, roster_name, team_name to EventAssignmentResponse
- `backend/app/api/rosters.py` - Updated list_my_event_assignments to include event details
