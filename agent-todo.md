# Rooster - Prioritized TODO List

**Last Updated:** January 2026
**Status:** MVP ~85% complete

---

## Summary

The core backend and frontend are functional. Users can register, create teams, add members, create rosters, assign volunteers, and accept/decline assignments. The main gaps are the invite acceptance flow and notifications infrastructure.

---

## Priority 1: Critical MVP Features (Must Have)

### 1.1 Accept Invite Screen (Frontend)
**Status:** Not implemented
**Backend:** ✅ Ready (`POST /invites/accept/{token}`, `GET /invites/validate/{token}`)
**Effort:** Medium

Create `lib/screens/auth/accept_invite_screen.dart`:
- [ ] Parse invite token from URL/deep link
- [ ] Call `GET /invites/validate/{token}` to get team name and invitee info
- [ ] Display: "You've been invited to join [Team Name]"
- [ ] Show pre-filled email (readonly) from invite
- [ ] Password field for account creation
- [ ] Call `POST /invites/accept/{token}` with password
- [ ] On success: Store access token, navigate to Home
- [ ] Handle invalid/expired token errors

### 1.2 Deep Link Handling
**Status:** Not implemented
**Effort:** Medium

- [ ] Configure URL scheme `rooster://invite/:token` for mobile
- [ ] Configure web URL handling for `/invite/:token`
- [ ] Add route in `main.dart` to handle invite deep links
- [ ] Test on web, iOS, and Android

### 1.3 Email Sending for Invites
**Status:** Not implemented (TODOs in backend code)
**Effort:** Medium

- [ ] Choose email provider (SendGrid, AWS SES, or similar)
- [ ] Create email templates for invite
- [ ] Implement `send_invite_email()` in `backend/app/services/invite.py`
- [ ] Include invite link with token in email
- [ ] Add environment variables for email configuration

---

## Priority 2: Important MVP Features (Should Have)

### 2.1 Push Notifications (FCM)
**Status:** Not implemented
**Effort:** High

Backend:
- [ ] Add FCM admin SDK dependency
- [ ] Create `backend/app/services/push_notification.py`
- [ ] Store FCM tokens per user/device
- [ ] Send push on: new assignment, reminder (1 day before), assignment declined

Frontend:
- [ ] Add `firebase_messaging` package
- [ ] Request notification permissions
- [ ] Register FCM token with backend on login
- [ ] Handle foreground/background notifications

### 2.2 Assignment Detail Enhancements
**Status:** Partially done
**Effort:** Low

- [ ] Show co-volunteer status indicators:
  - ✅ = Accepted
  - ⏳ = Pending (registered user)
  - ○ = Placeholder (not invited)
  - ✉️ = Invited (awaiting response)
- [ ] Add "Contact Team Lead" button with actions (email, phone)
- [ ] Show location/notes from roster data (if available)

### 2.3 Create Roster Improvements
**Status:** Basic form done
**Effort:** Low

- [ ] Add time selection for events
- [ ] Add location field
- [ ] Add notes/description field

---

## Priority 3: Polish & Edge Cases (Nice to Have)

### 3.1 Error Handling Improvements
**Status:** Basic try-catch exists
**Effort:** Medium

- [ ] Handle 401 (unauthorized) - redirect to login, clear stored token
- [ ] Handle 403 (forbidden) - show permission denied message
- [ ] Handle 404 (not found) - show not found screen/message
- [ ] Handle network errors - show offline state with retry button
- [ ] Disable buttons during form submissions to prevent double-taps

### 3.2 Roster Detail Enhancements
**Status:** Basic list done
**Effort:** Medium

- [ ] Show roster info card (recurrence, day, slots needed)
- [ ] Visual slot status indicators (green=filled, orange=partial, red=empty)
- [ ] "Generate more dates" button for ongoing rosters
- [ ] Edit roster (name, slots needed)
- [ ] Delete roster with confirmation

### 3.3 Quick Assign Improvements
**Status:** Basic assignment works
**Effort:** Low

- [ ] Search/filter members in assign sheet
- [ ] Show "Unavailable" section with reasons
- [ ] Toast variants based on user type:
  - Registered: "Emma assigned. Notification sent."
  - Placeholder: "Tom assigned. Invite them to notify."

### 3.4 Member Detail Improvements
**Status:** Basic view done
**Effort:** Low

- [ ] Show upcoming assignments for the member
- [ ] Show assignment count in invite prompt ("John has 2 upcoming assignments")
- [ ] Fetch real team data instead of hardcoded "Media Team"

---

## Priority 4: Deferred (Post-MVP)

These are explicitly out of scope for MVP per PRD.md:

- [ ] Google OAuth login
- [ ] Auto-rotate assignment suggestions
- [ ] Swap requests between members
- [ ] Calendar view
- [ ] Analytics/reporting
- [ ] Multiple organizations
- [ ] Offline support with data caching
- [ ] Weekly email digest

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
- [x] Granular team permissions
- [x] Comprehensive unit tests for all services

### Frontend
- [x] Login and Register screens
- [x] Home screen with adaptive layout (member vs team lead)
- [x] "Needs Attention" section for team leads with unfilled slots
- [x] Assignment detail with accept/decline
- [x] Change response after confirming
- [x] My Teams screen with create team
- [x] Team Detail with members and rosters
- [x] Add Member (placeholder) flow
- [x] Send Invite flow
- [x] Member Detail with placeholder indicators
- [x] Create Roster with recurrence options
- [x] Roster Detail with event list
- [x] Assign Volunteers sheet
- [x] Availability screen (mark unavailable dates)
- [x] Notifications screen with navigation
- [x] Settings screen with logout
- [x] Pull-to-refresh on all list screens
- [x] Full API integration (no mock data)

---

## File References

Key files for upcoming work:

```
# Accept Invite Screen (to create)
frontend/rooster_app/lib/screens/auth/accept_invite_screen.dart

# Deep link configuration
frontend/rooster_app/lib/main.dart

# Email sending (to implement)
backend/app/services/invite.py:74  # TODO comment
backend/app/services/invite.py:155 # TODO comment

# Push notifications (to create)
backend/app/services/push_notification.py

# Assignment detail enhancements
frontend/rooster_app/lib/screens/assignments/assignment_detail_screen.dart

# Invite service (frontend - has acceptInvite method ready)
frontend/rooster_app/lib/services/invite_service.dart
```

---

## Notes

- Backend invite endpoints are fully functional and tested
- Frontend `InviteService` already has `validateToken()` and `acceptInvite()` methods
- The accept invite screen is the last critical piece for the full invite flow
- Push notifications require Firebase project setup
- Email requires third-party service account
