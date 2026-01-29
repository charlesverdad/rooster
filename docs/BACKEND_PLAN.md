# Backend Implementation Plan

**Created:** January 2026
**Approach:** Implement missing features to support frontend, skip migrations (recreate DB)

---

## Current State

The backend has a solid foundation with:
- Auth (register, login, JWT) - **Working**
- Organisation/Team CRUD - **Working**
- Roster/Assignment CRUD - **Working**
- Availability tracking - **Working**
- Notifications - **Working**
- Dashboard views - **Working**

---

## Gaps Between Backend and Frontend

### 1. Placeholder Users (HIGH PRIORITY)
**Frontend expects:** Team leads can add members by name only, invite later
**Backend has:** Users require email for registration

**Needed:**
- [ ] Add `is_placeholder` field to User model
- [ ] Add `invited_by`, `invited_at` fields to User model
- [ ] Allow creating placeholder users (name only, no email/password)
- [ ] Update team member endpoints to support placeholders

### 2. Invite System (HIGH PRIORITY)
**Frontend expects:** Send email invites to placeholders, they click link and create account
**Backend has:** Nothing

**Needed:**
- [ ] Create Invite model (id, team_id, user_id, email, token, created_at, accepted_at)
- [ ] POST `/api/teams/{team_id}/members/{user_id}/invite` - Send invite
- [ ] GET `/api/invites/{token}` - Validate invite token
- [ ] POST `/api/invites/{token}/accept` - Accept invite & set password

### 3. Roster Events (MEDIUM PRIORITY)
**Frontend expects:** Rosters generate events (occurrences), assign volunteers to events
**Backend has:** Assignments tied directly to roster + date

**Needed:**
- [ ] Create RosterEvent model (id, roster_id, date_time, volunteers_needed)
- [ ] Generate events when roster is created
- [ ] GET `/api/rosters/{roster_id}/events` - List events with assignments
- [ ] POST `/api/rosters/{roster_id}/events/generate` - Generate more events
- [ ] Update assignment to link to event instead of roster+date

### 4. Enhanced Assignment Response (MEDIUM PRIORITY)
**Frontend expects:** Assignment includes roster_name, team_name, location, notes
**Backend has:** Basic assignment with roster_id

**Needed:**
- [ ] Add eager loading of roster → team in assignment queries
- [ ] Extend AssignmentResponse schema with roster_name, team_name
- [ ] Add location, notes fields to Roster model

### 5. Team Members with Status (LOW PRIORITY)
**Frontend expects:** Member list shows placeholder status, invite status
**Backend has:** Basic team member list

**Needed:**
- [ ] Extend TeamMemberResponse with is_placeholder, is_invited fields
- [ ] Include user details in member response

---

## Implementation Order (Prioritized)

### Phase 1: Placeholder Users & Invites
These are core to the "start with names, invite later" philosophy.

1. Update User model with placeholder fields
2. Update TeamMember creation to support placeholders
3. Create Invite model
4. Implement invite endpoints
5. Implement accept invite flow

### Phase 2: Roster Events
Enable the roster → events → assignments flow.

1. Create RosterEvent model
2. Add event generation logic
3. Update assignment to use events
4. Implement event endpoints

### Phase 3: Enhanced Responses
Polish the API responses for frontend consumption.

1. Add location/notes to Roster
2. Enhance assignment response with related data
3. Enhance team member response with status

---

## Database Changes Summary

### New Models
```python
# Invite
class Invite(Base):
    id: UUID
    team_id: UUID (FK)
    user_id: UUID (FK)  # The placeholder user being invited
    email: str
    token: str (unique, indexed)
    created_at: datetime
    accepted_at: datetime (nullable)

# RosterEvent
class RosterEvent(Base):
    id: UUID
    roster_id: UUID (FK)
    date_time: datetime
    volunteers_needed: int
    created_at: datetime
```

### Modified Models
```python
# User - add fields
is_placeholder: bool = False
invited_by: UUID (FK, nullable)
invited_at: datetime (nullable)

# Roster - add fields
location: str (nullable)
notes: str (nullable)
start_date: date (nullable)
end_date: date (nullable)
end_after_occurrences: int (nullable)

# Assignment - modify
roster_event_id: UUID (FK)  # Instead of roster_id + date
```

---

## API Endpoints Summary

### New Endpoints
| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/teams/{team_id}/members/placeholder` | Add placeholder member |
| POST | `/api/teams/{team_id}/members/{user_id}/invite` | Send invite to placeholder |
| GET | `/api/invites/{token}` | Validate invite token |
| POST | `/api/invites/{token}/accept` | Accept invite |
| GET | `/api/rosters/{roster_id}/events` | List roster events |
| POST | `/api/rosters/{roster_id}/events/generate` | Generate more events |

### Modified Endpoints
| Method | Path | Change |
|--------|------|--------|
| GET | `/api/teams/{team_id}/members` | Include placeholder/invite status |
| GET | `/api/rosters/assignments/my` | Include roster_name, team_name |
| POST | `/api/rosters/` | Support start_date, end conditions |

---

## Success Criteria

- Team lead can add member by name only
- Team lead can send invite email to placeholder
- Placeholder can accept invite and see existing assignments
- Rosters generate events based on recurrence
- Volunteers are assigned to specific events
- Frontend receives all needed data without extra API calls
