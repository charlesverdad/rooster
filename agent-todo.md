# Rooster - Prioritized TODO List

**Last Updated:** January 2026  
**Status:** MVP feature set implemented; polish + operational gaps remain

---

## Summary

Core backend and frontend flows are implemented end-to-end: authentication, teams, rosters, assignments, invites (including accept flow), availability, and notifications. The remaining work is mostly polish and operational readiness: wiring a few UI screens to existing APIs, adding unavailability intelligence, and standing up push notifications.

---

## Priority 1: UX Wiring Gaps (Must Have)

### 1.1 Send Invite Screen (Frontend)
**Status:** UI exists, not wired to API
**Effort:** Low

- [ ] Call `TeamProvider.sendInvite()` from `SendInviteScreen`
- [ ] Show loading + error states
- [ ] Update member status to invited on success
- [ ] Support resend flow (optional button for already-invited members)

### 1.2 Member Detail Assignments (Team Lead View)
**Status:** Not implemented
**Effort:** Medium

- [ ] Add backend endpoint: `GET /teams/:id/members/:userId/assignments`
- [ ] Return upcoming assignments with status
- [ ] Wire `MemberDetailScreen` to fetch and display list
- [ ] Show count in invite CTA when placeholders have assignments

### 1.3 Quick Assign Unavailability
**Status:** Partial (UI sections exist)
**Effort:** Medium

- [ ] Use `/availability/conflicts` for unavailable members
- [ ] Show reason in UI (unavailable vs already assigned)
- [ ] Prevent assignment for unavailable members

---

## Priority 2: Notifications Infrastructure (Should Have)

### 2.1 Push Notifications (FCM)
**Status:** Not implemented
**Effort:** High

Backend:
- [ ] Add FCM admin SDK dependency
- [ ] Create `backend/app/services/push_notification.py`
- [ ] Store device tokens per user
- [ ] Send pushes for new assignment, reminder, decline

Frontend:
- [ ] Add `firebase_messaging` package
- [ ] Register FCM token on login
- [ ] Handle foreground/background notifications
- [ ] Settings toggle for notifications

### 2.2 Email Deliverability
**Status:** Implemented but requires configuration
**Effort:** Medium

- [ ] Configure SMTP settings in environment
- [ ] Validate email templates for branding
- [ ] Add rate limiting / monitoring

---

## Priority 3: Polish & Admin UX (Nice to Have)

### 3.1 Team Settings
**Status:** Not implemented
**Effort:** Low

- [ ] Add team settings screen (rename team, manage roles)
- [ ] Move placeholder TODO out of team detail

### 3.2 Browse Teams
**Status:** Not implemented
**Effort:** Low

- [ ] Add browse teams list (if supported by backend)
- [ ] Hook My Teams “Browse All Teams” button

### 3.3 Roster Event Detail
**Status:** Not implemented
**Effort:** Medium

- [ ] Add event detail screen
- [ ] Show assignment list + slot-level actions
- [ ] Link from roster detail event cards

### 3.4 Error Handling Improvements
**Status:** Partial
**Effort:** Medium

- [ ] 401 redirect to login (already in ApiClient)
- [ ] 403/404 error views
- [ ] Offline states with retry
- [ ] Disable buttons during form submissions

---

## Completed Features ✅

### Backend
- [x] User authentication (register, login, JWT)
- [x] Team CRUD with membership management
- [x] Placeholder users and invite system
- [x] Roster creation with recurrence patterns
- [x] Event generation from rosters
- [x] Event assignments (create, update status)
- [x] Availability/unavailability tracking
- [x] In-app notifications
- [x] Invite validation + acceptance
- [x] Email service for invites + assignment notifications
- [x] Granular team permissions
- [x] Comprehensive unit tests for all services

### Frontend
- [x] Login and Register screens
- [x] Home screen with team lead "Needs Attention" section
- [x] Assignment detail with accept/decline + co-volunteer status
- [x] Contact team lead flow
- [x] My Teams list + create team dialog
- [x] Team Detail with members and rosters
- [x] Add Member (placeholder) flow
- [x] Member Detail with placeholder status
- [x] Create Roster with recurrence, time, location, notes
- [x] Roster Detail with event list + assign actions
- [x] Assign Volunteers sheet with search + placeholder labels
- [x] Availability screen (mark unavailable dates)
- [x] Notifications screen with navigation + swipe to delete
- [x] Accept Invite screen + deep link routing
- [x] Settings screen with logout
- [x] Pull-to-refresh on list screens

---

## File References

Key files for upcoming work:

```
# Send invite wiring
frontend/rooster_app/lib/screens/teams/send_invite_screen.dart
frontend/rooster_app/lib/providers/team_provider.dart

# Member assignment endpoint (backend)
backend/app/api/assignments.py

# Quick assign availability
frontend/rooster_app/lib/screens/roster/assign_volunteers_sheet.dart
backend/app/api/availability.py

# Push notifications
backend/app/services/push_notification.py (new)
```

---

## Notes

- Invite email delivery is implemented but requires SMTP config to enable.
- Push notifications are still missing despite being in the MVP scope.
- Remaining gaps are mostly UX wiring and operational readiness.
