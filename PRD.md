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

**Start with names, invite later**: Team leads can create rosters with just names (placeholder users). Invite people when ready—they auto-join with their assignments intact.

---

## Target Users

1. **Volunteers** - Church members who serve on one or more teams
2. **Team Leads** - Responsible for managing their team's roster and members

Note: There is no separate admin role. Team leads manage their own teams. Organization-level administration (if needed later) is out of scope for MVP.

---

## User Roles & Permissions

| Capability | Team Lead | Member |
|------------|-----------|--------|
| View own assignments | Yes | Yes |
| Accept/decline assignments | Yes | Yes |
| Mark personal unavailability | Yes | Yes |
| Create teams | Yes | No |
| Create rosters | Own teams | No |
| Add placeholder members (by name) | Own teams | No |
| Invite members (by email) | Own teams | No |
| Assign volunteers to slots | Own teams | No |
| View team member list | Own teams | Own teams |

---

## Core Concepts

### Team
A group of volunteers serving a specific ministry (e.g., Media Team, Worship Team). Created and managed by a team lead.

### Roster
A recurring schedule tied to a team (e.g., "Sunday Service" every Sunday). Rosters define when volunteers are needed.

### Assignment
A specific person assigned to serve on a specific date for a roster. Can be assigned to:
- A registered user (has an account)
- A placeholder user (just a name, no account yet)

### Placeholder User
A person added by name only, without an email or account. Team leads can:
- Assign them to rosters
- Later invite them via email
- When invited, the placeholder converts to a real user with all assignments intact

### Unavailability
Dates a member cannot serve. Team leads see this when assigning.

---

## Features

### F1: Authentication
- Email/password login
- Simple registration (name, email, password)
- **Invite link registration**: When invited, user clicks link → creates account → auto-joins team with existing assignments

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
- Team leads can create teams
- View team members (both registered and placeholder)
- Add members by name only (placeholder)
- Invite placeholders via email when ready

### F5: Roster Management (Team Leads)
- Create rosters with recurring patterns:
  - Weekly
  - Bi-weekly
  - Monthly
- Define volunteers needed per occurrence
- Assign anyone from the team (registered or placeholder)

### F6: Placeholder Users & Invites
- **Add by name**: Team lead adds "John Smith" to team—no email needed
- **Assign to roster**: John appears in assignment list, can be assigned
- **Invite later**: Team lead enters John's email → invite sent
- **Auto-join**: John clicks invite → creates account → sees his existing assignments
- **Placeholder indicator**: UI shows which members are placeholders (not yet invited)

### F7: Unavailability
- Members mark specific dates as unavailable
- Unavailable members shown separately when team lead assigns
- Placeholders cannot mark unavailability (they don't have accounts)

### F8: Notifications
- **Push notification triggers**:
  - New assignment created (registered users only)
  - Reminder: 1 day before assignment
  - Assignment declined (to team lead)
- **Email triggers**:
  - Invite to join team (for placeholders being invited)
  - Weekly digest of upcoming assignments
  - New assignment notification

---

## MVP Scope

### Included in MVP
- [x] Email/password authentication
- [x] Invite link registration (auto-join team)
- [x] Team leads can create teams
- [x] Add members by name (placeholder users)
- [x] Invite placeholders via email
- [x] Create weekly rosters with manual assignments
- [x] Assign both registered and placeholder users
- [x] Home screen with pending and upcoming assignments
- [x] Accept/decline assignments
- [x] Mark unavailability (specific dates)
- [x] Basic push notifications
- [x] Team lead "Needs Attention" section

### Deferred (Maybe Later)
- [ ] Admin role / organization management
- [ ] Google OAuth
- [ ] Auto-rotate assignment suggestions
- [ ] Swap requests between members
- [ ] Calendar view
- [ ] Analytics/reporting
- [ ] Multiple organizations

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

### Data Model

```
User
├── id, email, name, password_hash
├── is_placeholder (boolean) -- true if just a name, no account
├── invited_by (user_id, nullable) -- who invited them
├── invited_at (timestamp, nullable)

Team
├── id, name, created_by (user_id)

TeamMember
├── user_id, team_id, role (lead/member)

Roster
├── id, team_id, name, recurrence_pattern, slots_needed

Assignment
├── id, roster_id, date, user_id
├── status (pending/accepted/declined)
├── -- Note: placeholder users always have status "pending"

Unavailability
├── id, user_id, date
├── -- Only for registered users (is_placeholder = false)

Notification
├── id, user_id, type, message, read_at

Invite
├── id, team_id, user_id (the placeholder being invited)
├── email, token, created_at, accepted_at
```

**Placeholder → Real User Flow:**
1. Team lead creates placeholder: `User(name="John Smith", is_placeholder=true)`
2. Team lead invites: `Invite(user_id=john, email="john@email.com", token=xyz)`
3. John clicks link, creates account: `User.is_placeholder = false, email = "john@email.com", password_hash = ...`
4. All existing `Assignment` records remain linked to same `user_id`

---

## User Flows

### Flow 1: Team Lead Sets Up Team (First Time)

1. Team lead creates account
2. Creates team: "Media Team"
3. Adds members by name: "John Smith", "Sarah Johnson", "Mike Chen"
4. Creates roster: "Sunday Service", weekly, 2 volunteers needed
5. Assigns John and Sarah to Jan 21
6. Later, invites John via email
7. John gets email, clicks link, creates account
8. John sees his Jan 21 assignment immediately

### Flow 2: Member Responds to Assignment

1. Push notification arrives: "New assignment: Sunday Service"
2. Member taps notification
3. App opens to assignment detail
4. Member taps "Accept"
5. Toast confirms, team lead notified
6. Done

### Flow 3: Team Lead Fills Empty Slot

1. Team lead opens app
2. Home shows "Needs Attention: 1 unfilled slot"
3. Taps "[+ Assign]"
4. Quick assign sheet shows team members (registered and placeholder)
5. Taps member name
6. Toast confirms, member notified (if registered)
7. Done

### Flow 4: Team Lead Invites Placeholder

1. Team lead goes to team detail
2. Sees placeholder indicator next to "John Smith"
3. Taps John → member detail
4. Taps "Invite"
5. Enters email, sends invite
6. John receives email with link
7. John clicks link, creates account
8. John is now a registered member with all his assignments

---

## Success Criteria

Simple, binary measures:
- Can team leads start rostering immediately (without waiting for signups)?
- Do people know when they're scheduled?
- Can they respond easily?

We intentionally do not track:
- Response rates
- Average response times
- Engagement metrics

---

## What We're NOT Building

To keep the app focused, we explicitly exclude:

- **Admin role**: Team leads manage everything. No org-level admin.
- **Analytics dashboards**: No charts, graphs, or metrics views
- **Gamification**: No streaks, badges, or service history displays
- **Social features**: No team chat, appreciation features, or profiles
- **Discovery**: No browse teams or explore features
- **Calendar views**: List view only (simpler, sufficient)

---

## Open Questions

1. Can a person be on multiple teams with different team leads?
2. What if someone is invited but the email is wrong? Allow re-invite?
3. Should placeholders show in "Upcoming" section on team lead's home? (Yes, with indicator)

---

## Glossary

| Term | Definition |
|------|------------|
| **Roster** | A recurring schedule (e.g., "Sunday Service" every Sunday) |
| **Assignment** | A person assigned to a roster on a specific date |
| **Slot** | A position that needs filling on a roster date |
| **Placeholder** | A team member added by name only, not yet invited |
| **Invite** | Email sent to a placeholder to create their account |
