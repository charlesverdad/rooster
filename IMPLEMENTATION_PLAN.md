# Rooster Frontend Implementation Plan

**Created:** January 2026  
**Approach:** Frontend-first development for UI/UX testing  
**Target:** 14 core screens as defined in Information Architecture v2.1

---

## Current State Summary

### Implemented Screens & Flows (MVP)
| Screen | Status | Notes |
|--------|--------|-------|
| Login | Done | Real API integration |
| Register | Done | Real API integration |
| Home | Done | Needs Attention, pull-to-refresh, team lead section |
| Assignment Detail | Done | Accept/decline, co-volunteer status, contact team lead, location/notes |
| My Teams | Done | Create team dialog, list, empty state |
| Team Detail | Done | Members + rosters, placeholder indicators, invite buttons |
| Add Member | Done | Bottom sheet |
| Member Detail | Partial | Placeholder status + invite CTA; assignments list not wired |
| Send Invite | Partial | UI complete; API wiring TODO |
| Create Roster | Done | Recurrence, time, location, notes |
| Roster Detail | Done | Info card, slot indicators, assign, edit/delete, generate more |
| Assign Volunteers | Partial | Search + sections; unavailability logic TODO |
| Availability | Done | Date-based unavailability |
| Notifications | Done | API, swipe-to-dismiss, deep-link routing |
| Settings | Done | Basic profile/logout |
| Accept Invite | Done | Token validation + accept flow |

### Not Yet Implemented (Remaining Gaps)
| Item | Priority | Notes |
|------|----------|-------|
| Member assignments for team lead view | Medium | Needs backend endpoint + UI wiring |
| Send Invite API wiring | Medium | Hook screen to TeamProvider.sendInvite |
| Unavailability logic in Quick Assign | Medium | Use availability conflicts API |
| Team settings screen | Low | Placeholder action in team detail |
| Browse teams flow | Low | Placeholder action in My Teams |

### Data Layer Status
| Provider | Data Source | Notes |
|----------|-------------|-------|
| AuthProvider | Real API | Working |
| AvailabilityProvider | Real API | Working |
| RosterProvider | Real API | Working |
| TeamProvider | Real API | Working |
| AssignmentProvider | Real API | Working |
| NotificationProvider | Real API | Working |
| InviteService | Real API | Working |

---

## Implementation Phases

### Phase 1: Core Member Experience (Complete)
**Goal:** Complete the member-facing flows for viewing and responding to assignments

#### 1.1 Home Screen Enhancements
- [x] Add "Needs Attention" section for team leads
- [x] Add placeholder indicators for placeholders in co-volunteer lists
- [x] Improve date formatting consistency
- [x] Add empty state when no pending/upcoming assignments
- [x] Add pull-to-refresh functionality

#### 1.2 Assignment Detail Polish
- [x] Accept/decline functionality
- [x] Change response after confirming
- [x] Show co-volunteers with proper status indicators
- [x] Dynamic team name
- [x] Dynamic location/notes from roster data
- [x] Contact Team Lead button with action options

#### 1.3 Notification Improvements
- [x] Link notifications to relevant screens
- [x] Different notification types with appropriate icons
- [x] Swipe to dismiss

---

### Phase 2: Team Lead - Team Management (Mostly Complete)
**Goal:** Enable team leads to create and manage teams

#### 2.1 Create Team
- [x] Simple form (dialog in My Teams)
- [x] Navigate to Team Detail on create
- [x] Toast confirmation

#### 2.2 Team Detail Enhancements
- [x] Placeholder indicators next to member names
- [x] [Invite] button next to placeholder members
- [x] Show team's rosters section
- [x] Quick navigation to roster detail
- [x] Role badge for team lead
- [ ] Show member count with "(X not invited)" suffix

#### 2.3 Member Detail Enhancements
- [x] Different views for registered vs placeholder members
- [x] Placeholder status labels + invite CTA
- [x] Registered member contact info
- [ ] Registered member upcoming assignments (needs API)

#### 2.4 Invite Flow Improvements
- [x] Invite token validation + accept flow
- [ ] Show assignment count in invite sheet
- [ ] Handle re-invite scenario in UI

---

### Phase 3: Team Lead - Roster Management (Complete)
**Goal:** Enable team leads to create rosters and assign volunteers

#### 3.1 Create Roster Polish
- [x] Basic form with recurrence options
- [x] One-time event support
- [x] Start date selection
- [x] End conditions
- [x] Time selection for events
- [x] Location field

#### 3.2 Roster Detail Enhancements
- [x] Roster info card (recurrence, day, slots needed)
- [x] Event list with assignment status per slot
- [x] Per-slot [+ Assign] buttons for unfilled slots
- [x] Visual indicators for filled/partial/unfilled
- [x] "Generate more dates" button
- [x] Edit roster (name, slots needed)
- [x] Delete roster with confirmation

#### 3.3 Quick Assign Improvements
- [x] Search/filter members
- [x] Show "Available" vs "Placeholders" sections
- [ ] Unavailable reasons (marked unavailable, already assigned)
- [x] Placeholder indicator on member names
- [x] Toast variants (registered vs placeholder)

---

### Phase 4: Invite Registration Flow (Complete)
**Goal:** Allow invited placeholders to create accounts and see their assignments

#### 4.1 Accept Invite Screen
- [x] Parse token from URL/deep link
- [x] Display invite info (team + invitee)
- [x] Pre-filled email (readonly)
- [x] Password field only
- [x] Join Team button
- [x] Success -> login + Home
- [x] Error handling for invalid/expired tokens

#### 4.2 Deep Link Handling
- [x] Configure URL scheme for `rooster://invite/:token`
- [x] Configure web URL handling for `/invite/:token`
- [x] Handle expired/invalid tokens gracefully

---

### Phase 5: Data Integration (Complete)
**Goal:** Replace mock data with real API calls

#### 5.1 Team API Integration
- [x] GET `/teams`
- [x] POST `/teams`
- [x] GET `/teams/:id`
- [x] GET `/teams/:id/members`
- [x] POST `/teams/:id/members`
- [x] POST `/invites/team/:teamId/user/:userId`

#### 5.2 Roster API Integration
- [x] GET `/teams/:id/rosters`
- [x] POST `/rosters`
- [x] GET `/rosters/:id`
- [x] GET `/rosters/:id/events`
- [x] POST `/rosters/:id/events/:eventId/assign`
- [x] DELETE `/rosters/:id`

#### 5.3 Assignment API Integration
- [x] GET `/assignments/me`
- [x] PATCH `/assignments/:id`

#### 5.4 Invite API Integration
- [x] GET `/invites/validate/:token`
- [x] POST `/invites/accept/:token`

---

### Phase 6: Polish & Edge Cases (Remaining)
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

For the next phase (post-MVP polish):

1. Wire Send Invite screen to API
2. Add member assignment view for team leads
3. Add unavailability logic to quick assign
4. Add team settings + browse teams placeholders
5. Error handling + accessibility pass

---

## File Structure for New Screens

```
lib/screens/
├── auth/
│   ├── login_screen.dart
│   ├── register_screen.dart
│   └── accept_invite_screen.dart
├── teams/
│   ├── my_teams_screen.dart
│   ├── team_detail_screen.dart
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

- All core MVP flows are now working end-to-end
- Remaining work focuses on polish, gaps in team-lead tooling, and error handling
- Placeholder users remain the key differentiator; ensure invite UX stays smooth
