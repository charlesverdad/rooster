# Rooster - Church Volunteer Rostering App

## Product Requirements Document

### Overview

Rooster is a volunteer rostering application designed for church communities. It helps volunteers know when they're scheduled to serve and lets them respond quickly. The app prioritizes simplicity—users should spend minimal time in it.

### Problem Statement

Church volunteer coordination is often managed through spreadsheets, WhatsApp groups, or verbal communication. This leads to:
- Missed assignments due to forgotten schedules
- Volunteers not knowing when they're rostered
- Team leads manually chasing people for confirmations

### Design Philosophy

**Notification-first**: Push notifications and email are the primary interface. The app exists to support those, not replace them.

**Get in, get out**: Most interactions should complete in 2 taps. No engagement metrics, no gamification, no reasons to linger.

**Progressive disclosure**: Show team lead features only to team leads, and only when relevant.

---

## Target Users

1. **Volunteers** - Church members who serve on one or more teams
2. **Team Leads** - Responsible for managing their team's roster

Note: Admin role exists for initial setup but is not a primary user experience focus.

---

## User Roles & Permissions

| Capability | Team Lead | Member |
|------------|-----------|--------|
| View own assignments | Yes | Yes |
| Accept/decline assignments | Yes | Yes |
| Mark personal unavailability | Yes | Yes |
| Create rosters | Own teams | No |
| Assign volunteers to slots | Own teams | No |
| Add/remove team members | Own teams | No |
| View team member list | Own teams | Own teams |

---

## Core Concepts

### Team
A group of volunteers serving a specific ministry (e.g., Media Team, Worship Team). Members can belong to multiple teams.

### Roster
A recurring schedule tied to a team (e.g., "Sunday Service" every Sunday). Rosters define when volunteers are needed.

### Assignment
A specific person assigned to serve on a specific date for a roster.

### Unavailability
Dates a member cannot serve. Team leads see this when assigning.

---

## Features

### F1: Authentication
- Email/password login
- Simple registration (name, email, password)
- No onboarding wizard—go straight to home screen

### F2: Home Screen
- **For members**: Show pending assignments (need response) and upcoming accepted assignments
- **For team leads**: Add "Needs Attention" section showing unfilled slots
- Single adaptive screen, not separate dashboards per role

### F3: Assignments
- View assignment details (date, time, location, co-volunteers)
- Accept or decline with 1-2 taps
- Decline includes optional reason (for team lead awareness)
- Team lead notified of responses

### F4: Team Management
- View teams user belongs to
- View team members and upcoming roster dates
- Team leads can add/remove members

### F5: Roster Management (Team Leads)
- Create rosters with recurring patterns:
  - Weekly
  - Bi-weekly
  - Monthly
- Define volunteers needed per occurrence
- Assign specific members to specific dates

### F6: Unavailability
- Members mark specific dates as unavailable
- Unavailable members shown separately when team lead assigns

### F7: Notifications
- **Push notification triggers**:
  - New assignment created
  - Reminder: 1 day before assignment
  - Assignment declined (to team lead)
- **Email triggers**:
  - Weekly digest of upcoming assignments
  - New assignment notification

---

## MVP Scope

### Included in MVP
- [x] Email/password authentication
- [x] Single organization (multi-org deferred)
- [x] Create teams and add members
- [x] Create weekly rosters with manual assignments
- [x] Home screen with pending and upcoming assignments
- [x] Accept/decline assignments
- [x] Mark unavailability (specific dates)
- [x] Basic push notifications
- [x] Team lead "Needs Attention" section

### Deferred (Maybe Later)
- [ ] Google OAuth
- [ ] Invite links for joining teams
- [ ] Auto-rotate assignment suggestions
- [ ] Swap requests between members
- [ ] Calendar view
- [ ] Analytics/reporting
- [ ] Service history tracking
- [ ] Browse/discover teams

---

## Technical Architecture

### Tech Stack

| Layer | Technology |
|-------|------------|
| **Backend** | Python, FastAPI |
| **Database** | PostgreSQL |
| **Frontend** | Flutter (Web + iOS + Android) |
| **Authentication** | JWT tokens |
| **Notifications** | Firebase Cloud Messaging (FCM) |

### Data Model (Simplified)

```
User
├── id, email, name, password_hash

Team
├── id, name

TeamMember
├── user_id, team_id, role (lead/member)

Roster
├── id, team_id, name, recurrence_pattern, slots_needed

Assignment
├── id, roster_id, date, user_id
├── status (pending/accepted/declined)

Unavailability
├── id, user_id, date

Notification
├── id, user_id, type, message, read_at
```

---

## User Flows

### Flow 1: Member Responds to Assignment
1. Push notification arrives: "New assignment: Sunday Service"
2. Member taps notification
3. App opens to assignment detail
4. Member taps "Accept"
5. Toast confirms, team lead notified
6. Done

### Flow 2: Team Lead Fills Empty Slot
1. Team lead opens app
2. Home shows "Needs Attention: 1 unfilled slot"
3. Taps "[+ Assign]"
4. Quick assign sheet shows available members
5. Taps member name
6. Toast confirms, member notified
7. Done

### Flow 3: Team Lead Creates Roster
1. Team lead goes to team detail
2. Taps "[+ Create Roster]"
3. Enters name, selects recurrence, sets volunteers needed
4. Taps "Create"
5. Returns to team detail with roster visible
6. Can now assign members to dates

---

## Success Criteria

Simple, binary measures:
- Do people know when they're scheduled? (Measured by: assignments not missed)
- Can they respond easily? (Measured by: responses happen, support tickets low)

We intentionally do not track:
- Response rates
- Average response times
- Engagement metrics
- Service history leaderboards

---

## What We're NOT Building

To keep the app focused, we explicitly exclude:

- **Analytics dashboards**: No charts, graphs, or metrics views
- **Gamification**: No streaks, badges, or service history displays
- **Social features**: No team chat, appreciation features, or profiles
- **Discovery**: No browse teams or explore features
- **Calendar views**: List view only (simpler, sufficient)
- **Complex onboarding**: Just login and see your assignments

---

## Open Questions

1. Should team leads be able to message individual members through the app, or rely on external contact?
2. How do new members join a team? Team lead adds them vs. invite links?
3. What happens when someone leaves mid-roster? Manual cleanup by team lead?

---

## Glossary

| Term | Definition |
|------|------------|
| **Roster** | A recurring schedule (e.g., "Sunday Service" every Sunday) |
| **Assignment** | A person assigned to a roster on a specific date |
| **Slot** | A position that needs filling on a roster date |
