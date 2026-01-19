# Rooster - Church Volunteer Rostering App

## Product Requirements Document

### Overview

Rooster is a volunteer rostering application designed for church communities. It helps coordinate volunteer schedules across multiple teams (media, praise & worship, cleaning, ushering, etc.), sends timely notifications, and provides team leads with tools to manage their rosters efficiently.

### Problem Statement

Church volunteer coordination is often managed through spreadsheets, WhatsApp groups, or verbal communication. This leads to:
- Missed assignments due to forgotten schedules
- Difficulty tracking availability and conflicts
- No centralized view for volunteers serving on multiple teams
- Manual effort to ensure fair rotation of duties

### Target Users

1. **Volunteers** - Church members who serve on one or more teams
2. **Team Leads** - Responsible for managing their team's roster
3. **Admins** - Church staff who oversee all teams and schedules

---

## User Roles & Permissions

| Capability | Admin | Team Lead | Member |
|------------|-------|-----------|--------|
| Create/manage organisations | Yes | No | No |
| Create/delete teams | Yes | No | No |
| View all teams & rosters | Yes | Own teams | Assigned teams |
| Create/edit rosters | Yes | Own teams | No |
| Add/remove team members | Yes | Own teams | No |
| Assign volunteers to roster slots | Yes | Own teams | No |
| Mark personal unavailability | Yes | Yes | Yes |
| Request assignment swaps | Yes | Yes | Yes |
| View notification read/acknowledgment status | Yes | Own teams | No |
| Switch between organisations | Yes | Yes | Yes |

---

## Core Concepts

### Organisation
A church or church campus. Members can belong to multiple organisations and switch between them.

### Team
A group of volunteers serving a specific ministry (e.g., Media Team, Praise & Worship, House Church Alpha). Teams belong to one organisation.

### Roster
A schedule template tied to a team and a recurring event pattern. Examples:
- "Media Team - Sunday Service" (weekly on Sundays)
- "Media Team - Prayer Night" (2nd Tuesday monthly)
- "House Church Alpha - Cleaning" (weekly on Sundays)

### Assignment
A specific roster slot assigning either:
- **Individual assignment**: A specific member to serve on a date
- **Team-level assignment**: An entire team/house church assigned (all members notified)

### Availability
Members can mark dates they are unavailable. This information is visible to team leads and highlighted as conflicts if assignments overlap.

---

## Features

### F1: Authentication & Onboarding
- Google OAuth login
- Email/password authentication (for development/testing)
- Invite links for joining organisations and teams
- Profile setup (name, contact preferences)

### F2: Organisation Management
- Create and manage organisations
- Invite members via shareable links
- Members can belong to multiple organisations
- Easy organisation switcher in the UI

### F3: Team Management
- Create teams within an organisation
- Add/remove members from teams
- Designate team leads
- View team member list and their availability

### F4: Roster & Schedule Management
- Create rosters with recurring patterns:
  - Weekly (e.g., every Sunday)
  - Bi-weekly
  - Monthly on specific day (e.g., 2nd Tuesday)
  - Custom patterns
- Define number of volunteers needed per roster slot
- Assignment modes:
  - **Manual**: Team lead assigns specific people
  - **Auto-rotate**: System suggests fair rotation based on past assignments
  - **Random**: System randomly assigns from available pool
- Support for team-level assignments (entire team assigned, not individuals)
- Schedule up to 12 months in advance

### F5: Availability Management
- Members mark specific dates as unavailable
- Optional: Recurring unavailability (e.g., "unavailable every 1st Sunday")
- Conflicts highlighted to team leads when:
  - Member is assigned but marked unavailable
  - Member has overlapping assignments across teams (within 30-day window)

### F6: Swap & Substitution Requests
- Member requests swap with another team member
- Swap request notification sent to the other member
- Team lead notified of pending/approved swaps
- Team lead can manually reassign if needed

### F7: Notifications & Acknowledgments
- **Notification triggers**:
  - 7 days before assignment (weekly reminder)
  - 1 day before assignment (day-before reminder)
  - New assignment created
  - Swap request received
  - Swap request approved/declined
  - Conflict detected (to team lead)
- **Acknowledgment types**:
  - "Seen" - passive read receipt
  - "Confirm/Decline" - explicit response required (configurable per roster)
- Team leads can view acknowledgment status for upcoming assignments

### F8: Dashboard & Views
- **Member home view**:
  - "Your next assignments" - simplified list of upcoming duties
  - Quick actions: mark unavailable, request swap
- **Calendar view**:
  - Monthly calendar showing all assignments
  - Filter by team
- **Team lead view**:
  - Roster management interface
  - Member availability overview
  - Conflict alerts
  - Acknowledgment status dashboard
- **Admin view**:
  - All teams overview
  - Organisation-wide calendar
  - Member directory

---

## MVP Scope (Phase 1)

The minimum viable product focuses on core scheduling and viewing functionality:

### Included in MVP
- [ ] Email/password authentication
- [ ] Single organisation support (multi-org switching deferred)
- [ ] Create teams and add members
- [ ] Create weekly rosters with manual assignments
- [ ] Individual assignments only (team-level assignments deferred)
- [ ] Member home view with upcoming assignments list
- [ ] Basic calendar view
- [ ] Mark unavailability (specific dates only)
- [ ] Simple conflict highlighting
- [ ] Basic in-app notifications (no push notifications yet)
- [ ] "Seen" read receipts

### Deferred to Phase 2
- [ ] Google OAuth
- [ ] Invite links
- [ ] Multiple organisations & switching
- [ ] Auto-rotate and random assignment modes
- [ ] Team-level assignments
- [ ] Recurring unavailability patterns
- [ ] Swap requests
- [ ] Confirm/decline acknowledgments
- [ ] Push notifications (native app)
- [ ] External notifications (email, SMS, WhatsApp)

### Deferred to Phase 3
- [ ] Reporting & analytics (who served most, fair distribution stats)
- [ ] Export to calendar (iCal, Google Calendar)
- [ ] Bulk import members (CSV)
- [ ] Custom notification schedules

---

## Technical Architecture

### Tech Stack

| Layer | Technology |
|-------|------------|
| **Backend** | Python, FastAPI |
| **Database** | PostgreSQL |
| **Frontend** | Flutter (Web + iOS + Android) |
| **Authentication** | JWT tokens, Google OAuth |
| **Notifications** | Firebase Cloud Messaging (FCM) for push |

### High-Level Architecture

```
┌─────────────────┐     ┌─────────────────┐
│  Flutter App    │────▶│  FastAPI        │
│  (Web/iOS/      │     │  Backend        │
│   Android)      │◀────│                 │
└─────────────────┘     └────────┬────────┘
                                 │
                        ┌────────▼────────┐
                        │   PostgreSQL    │
                        │   Database      │
                        └─────────────────┘
```

### Data Model (Simplified)

```
Organisation
├── id, name, created_at

User
├── id, email, name, password_hash, created_at

OrganisationMember
├── user_id, organisation_id, role (admin/member)

Team
├── id, organisation_id, name, created_at

TeamMember
├── user_id, team_id, role (lead/member)

Roster
├── id, team_id, name, recurrence_pattern, slots_needed
├── assignment_mode (manual/auto/random)
├── is_team_level (boolean)

Assignment
├── id, roster_id, date, user_id (nullable for team-level)
├── assigned_team_id (nullable for individual)
├── status (pending/confirmed/declined)

Unavailability
├── id, user_id, date, reason (optional)

Notification
├── id, user_id, type, message, created_at
├── read_at, acknowledged_at, response (confirm/decline)

SwapRequest
├── id, assignment_id, requester_id, target_user_id
├── status (pending/approved/declined), resolved_at
```

---

## User Flows

### Flow 1: Team Lead Creates Weekly Roster
1. Team lead navigates to their team
2. Clicks "Create Roster"
3. Enters roster name (e.g., "Sunday Service")
4. Selects recurrence: Weekly, Sunday
5. Sets slots needed: 2
6. Saves roster
7. Opens roster to assign members for upcoming dates
8. Selects members from team list for each date
9. Members receive notifications

### Flow 2: Member Views Assignments
1. Member opens app
2. Home screen shows "Your upcoming assignments":
   - "Media Team - Sunday Service: Jan 26"
   - "Cleaning Duty: Feb 2"
3. Member taps assignment to see details
4. Can mark as "seen" or "confirm" attendance

### Flow 3: Member Marks Unavailability
1. Member opens calendar view
2. Taps on a date
3. Selects "Mark as unavailable"
4. Optionally adds reason
5. If already assigned that day, conflict alert shown
6. Team lead notified of conflict

### Flow 4: Swap Request (Phase 2)
1. Member views their assignment
2. Taps "Request Swap"
3. Sees list of eligible team members
4. Selects a member and sends request
5. Target member receives notification
6. Target member accepts/declines
7. If accepted, assignments swap; team lead notified

---

## Success Metrics

- **Adoption**: % of team members actively using the app
- **Notification effectiveness**: % of assignments acknowledged before the date
- **Conflict reduction**: # of scheduling conflicts detected and resolved
- **User satisfaction**: Qualitative feedback from team leads and members

---

## Open Questions

1. Should there be a "sub" role for members who can help manage (not full team lead)?
2. Do we need support for one-off events (not recurring)?
3. Should unavailability have approval workflow or is it self-service?
4. What happens when someone leaves a team mid-roster? Auto-notify lead?

---

## Appendix: Glossary

| Term | Definition |
|------|------------|
| **Roster** | A recurring schedule template (e.g., "Sunday Media Duty") |
| **Assignment** | A specific person or team assigned to a roster on a specific date |
| **Slot** | The number of volunteers needed for a roster on any given date |
| **Conflict** | When a member is double-booked or assigned while marked unavailable |
| **Acknowledgment** | Member's response to a notification (seen, confirmed, declined) |
