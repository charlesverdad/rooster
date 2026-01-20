# Rooster Frontend Implementation Plan

**Created:** January 2026
**Approach:** Frontend-first development for UI/UX testing
**Target:** 14 core screens as defined in Information Architecture v2.1

---

## Current State Summary

### Implemented (15 screen files)
| Screen | Status | Notes |
|--------|--------|-------|
| Login | Done | Real API integration |
| Register | Done | Real API integration |
| Home | Partial | Missing "Needs Attention" section, placeholder indicators |
| Assignment Detail | Done | Accept/decline with change response |
| My Teams | Done | Basic list view |
| Team Detail | Partial | Missing placeholder indicators, roster list |
| Add Member | Done | Bottom sheet |
| Member Detail | Partial | Missing placeholder-specific UI |
| Send Invite | Done | Email invite flow |
| Create Roster | Done | Full recurrence options |
| Roster Detail | Done | Event list with assignment |
| Assign Volunteers | Done | Bottom sheet |
| Availability | Done | Date-based unavailability |
| Notifications | Done | Mock data |
| Settings | Done | Basic profile/logout |

### Not Yet Implemented
| Screen | Priority | Notes |
|--------|----------|-------|
| Accept Invite (1.3) | High | Placeholder user registration via invite link |
| Create Team | High | Team leads need to create teams |
| Contact Team Lead | Low | Simple contact options |

### Data Layer Status
| Provider | Data Source | Notes |
|----------|-------------|-------|
| AuthProvider | Real API | Working |
| AvailabilityProvider | Real API | Working |
| RosterProvider | Mock Data | Needs API wiring |
| TeamProvider | Mock Data | Needs API wiring |
| AssignmentProvider | Mock Data | Needs API wiring |
| NotificationProvider | Mock Data | Needs API wiring |

---

## Implementation Phases

### Phase 1: Core Member Experience
**Goal:** Complete the member-facing flows for viewing and responding to assignments

#### 1.1 Home Screen Enhancements
- [ ] Add "Needs Attention" section for team leads
  - Show unfilled slots with [+ Assign] button
  - Link to Quick Assign sheet
- [ ] Add placeholder indicators (circle icon) for placeholders in co-volunteer lists
- [ ] Improve date formatting consistency (use `date_display.md` guidelines)
- [ ] Add empty state when no pending/upcoming assignments
- [ ] Add pull-to-refresh functionality

#### 1.2 Assignment Detail Polish
- [x] Accept/decline functionality
- [x] Change response after confirming
- [ ] Show co-volunteers with proper status indicators:
  - `checkmark` = Accepted
  - `clock` = Pending (registered user)
  - `circle` = Placeholder (not invited)
  - `envelope` = Invited (awaiting response)
- [ ] Dynamic team name (currently hardcoded)
- [ ] Dynamic location/notes from roster data
- [ ] Contact Team Lead button with action options

#### 1.3 Notification Improvements
- [ ] Link notifications to relevant screens (tap → assignment detail)
- [ ] Different notification types with appropriate icons
- [ ] Swipe to dismiss

---

### Phase 2: Team Lead - Team Management
**Goal:** Enable team leads to create and manage teams

#### 2.1 Create Team Screen (New)
```
Route: /teams/create
Access: All authenticated users (anyone can become a team lead)
```
- [ ] Simple form: Team name only
- [ ] On create → navigate to Team Detail
- [ ] Toast: "Team created"

#### 2.2 Team Detail Enhancements
- [ ] Show member count with "(X not invited)" suffix
- [ ] Placeholder indicators next to member names
- [ ] [Invite] button next to placeholder members
- [ ] Show team's rosters section
- [ ] Quick navigation to roster detail
- [ ] Role badge for team lead

#### 2.3 Member Detail Enhancements
- [ ] Different views for registered vs placeholder members
- [ ] For placeholders: Show "Not yet invited" status
- [ ] For placeholders: Show assigned dates with "(assigned)" label
- [ ] For placeholders: Prominent "Invite via Email" button
- [ ] For registered: Show email, upcoming assignments with status

#### 2.4 Invite Flow Improvements
- [ ] Show assignment count in invite sheet ("John has 2 upcoming assignments")
- [ ] After invite sent, update member status to "Invited"
- [ ] Handle re-invite scenario (wrong email)

---

### Phase 3: Team Lead - Roster Management
**Goal:** Enable team leads to create rosters and assign volunteers

#### 3.1 Create Roster Polish
- [x] Basic form with recurrence options
- [x] One-time event support
- [x] Start date selection
- [x] End conditions (never/on-date/after-occurrences)
- [ ] Pre-fill team when navigating from Team Detail
- [ ] Time selection for events
- [ ] Location field

#### 3.2 Roster Detail Enhancements
- [ ] Show roster info card (recurrence, day, slots needed)
- [ ] Event list with assignment status per slot
- [ ] Per-slot [+ Assign] buttons for unfilled slots
- [ ] Visual indicators:
  - Green = fully filled
  - Orange = partially filled
  - Red = unfilled
- [ ] "Generate more dates" button
- [ ] Edit roster (name, slots needed)
- [ ] Delete roster with confirmation

#### 3.3 Quick Assign Improvements
- [ ] Search/filter members
- [ ] Show "Available" vs "Unavailable" sections
- [ ] Unavailable reasons (marked unavailable, already assigned)
- [ ] Placeholder indicator on member names
- [ ] Toast variants:
  - Registered: "Emma Davis assigned. Notification sent."
  - Placeholder: "Tom Wilson assigned. Invite them to notify."

---

### Phase 4: Invite Registration Flow
**Goal:** Allow invited placeholders to create accounts and see their assignments

#### 4.1 Accept Invite Screen (New)
```
Route: /invite/:token
Access: Public (with valid invite token)
```
- [ ] Parse token from URL/deep link
- [ ] Display: "You've been invited to join [Team Name]"
- [ ] Show invitee name: "Hi [Name]! Create your account..."
- [ ] Pre-filled email from invite
- [ ] Password field only (email readonly)
- [ ] [Join Team] button
- [ ] On success:
  - Convert placeholder to registered user
  - Navigate to Home with assignments visible
  - Toast: "Welcome to [Team Name]!"

#### 4.2 Deep Link Handling
- [ ] Configure URL scheme for `rooster://invite/:token`
- [ ] Configure web URL handling for `/invite/:token`
- [ ] Handle expired/invalid tokens gracefully

---

### Phase 5: Data Integration
**Goal:** Replace mock data with real API calls

#### 5.1 Team API Integration
- [ ] GET `/teams` - Fetch user's teams
- [ ] POST `/teams` - Create team
- [ ] GET `/teams/:id` - Fetch team detail
- [ ] GET `/teams/:id/members` - Fetch team members
- [ ] POST `/teams/:id/members` - Add placeholder member
- [ ] POST `/teams/:id/invites` - Send invite

#### 5.2 Roster API Integration
- [ ] GET `/teams/:id/rosters` - Fetch team's rosters
- [ ] POST `/rosters` - Create roster
- [ ] GET `/rosters/:id` - Fetch roster detail
- [ ] GET `/rosters/:id/events` - Fetch roster events
- [ ] POST `/rosters/:id/events/:eventId/assign` - Assign volunteer
- [ ] DELETE `/rosters/:id` - Delete roster

#### 5.3 Assignment API Integration
- [ ] GET `/assignments/me` - Fetch user's assignments
- [ ] PATCH `/assignments/:id` - Update status (accept/decline)

#### 5.4 Invite API Integration
- [ ] GET `/invites/:token` - Validate invite token
- [ ] POST `/invites/:token/accept` - Accept invite and create account

---

### Phase 6: Polish & Edge Cases
**Goal:** Handle error states and improve UX

#### 6.1 Error Handling
- [ ] Network error states with retry buttons
- [ ] Empty states for all list views
- [ ] Loading skeletons for better perceived performance
- [ ] Form validation with inline errors

#### 6.2 Offline Support (Deferred)
- [ ] Cache last-fetched data
- [ ] Queue actions when offline
- [ ] Sync indicator

#### 6.3 Accessibility
- [ ] Screen reader labels on all interactive elements
- [ ] Semantic labels for status indicators
- [ ] Minimum touch targets (44x44pt)

---

## Implementation Order (Recommended)

For fastest path to testable UI/UX:

### Sprint 1: Member Flow Complete
1. Home screen "Needs Attention" section
2. Assignment detail co-volunteer status indicators
3. Contact team lead functionality
4. Notification tap-to-navigate

### Sprint 2: Team Lead - Teams
5. Create Team screen
6. Team Detail placeholder indicators
7. Member Detail for placeholders
8. Improved invite flow

### Sprint 3: Team Lead - Rosters
9. Create Roster pre-fill and time/location
10. Roster Detail slot-level assignment
11. Quick Assign improvements

### Sprint 4: Invite Flow
12. Accept Invite screen
13. Deep link handling
14. Token validation

### Sprint 5: API Integration
15. Wire up team APIs
16. Wire up roster APIs
17. Wire up assignment APIs
18. Wire up invite APIs

---

## File Structure for New Screens

```
lib/screens/
├── auth/
│   ├── login_screen.dart
│   ├── register_screen.dart
│   └── accept_invite_screen.dart    # NEW
├── teams/
│   ├── my_teams_screen.dart
│   ├── team_detail_screen.dart
│   ├── create_team_screen.dart      # NEW
│   ├── add_member_sheet.dart
│   ├── member_detail_screen.dart
│   └── send_invite_screen.dart
└── ...
```

---

## Success Criteria

Per PRD, we measure success by:
- Can team leads start rostering immediately (without waiting for signups)? **Yes**
- Do people know when they're scheduled? **Yes, via Home + Notifications**
- Can they respond easily? **Yes, 2 taps to accept**

### UX Benchmarks
- Time to create first roster: < 5 minutes
- Taps to accept assignment: 2
- Taps to decline assignment: 3
- Taps to assign volunteer: 2

---

## Notes

- All mock data continues to work for UI testing
- API integration can happen incrementally per feature
- Focus on the "happy path" first, then edge cases
- Placeholder users are the key differentiator - make this flow smooth
