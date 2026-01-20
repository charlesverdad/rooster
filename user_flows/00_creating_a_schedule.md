# User Flow: Creating a Roster

**User Role:** Team Lead
**Goal:** Create a recurring roster and assign volunteers
**Entry Point:** Team Detail → [+ Create Roster]

---

## Overview

Team leads create rosters to define recurring schedules (e.g., "Sunday Service" every week). This is a **single-screen form** that creates the roster immediately.

---

## The Flow

### Step 1: Navigate to Team

From Home, team lead taps their team name → Team Detail screen

```
┌─────────────────────────────┐
│ ← Media Team                │
├─────────────────────────────┤
│                             │
│ 12 members                  │
│                             │
│ Upcoming                    │
│ (existing roster dates)     │
│                             │
│ Members                     │
│ (team member list)          │
│                             │
│ [+ Create Roster]           │
│                             │
└─────────────────────────────┘
```

Team lead taps **[+ Create Roster]**

---

### Step 2: Create Roster Form

Single screen with all fields:

```
┌─────────────────────────────┐
│ ← New Roster                │
├─────────────────────────────┤
│                             │
│ Roster Name                 │
│ ┌───────────────────────┐   │
│ │ Sunday Service        │   │
│ └───────────────────────┘   │
│                             │
│ Team                        │
│ ┌───────────────────────┐   │
│ │ Media Team        ▼   │   │
│ └───────────────────────┘   │
│ (pre-filled if from team)   │
│                             │
│ Repeats                     │
│ ┌───────────────────────┐   │
│ │ ● Weekly              │   │
│ │ ○ Bi-weekly           │   │
│ │ ○ Monthly             │   │
│ └───────────────────────┘   │
│                             │
│ Day                         │
│  S   M   T   W   T   F   S  │
│ [●] [ ] [ ] [ ] [ ] [ ] [ ] │
│                             │
│ Volunteers needed           │
│       [-]  2  [+]           │
│                             │
│ Generate for next           │
│ ┌───────────────────────┐   │
│ │ 3 months          ▼   │   │
│ └───────────────────────┘   │
│                             │
│          [Create]           │
│                             │
└─────────────────────────────┘
```

**Fields:**
- **Roster Name**: Required, 3-50 characters
- **Team**: Pre-selected if navigated from team
- **Repeats**: Weekly (default), Bi-weekly, Monthly
- **Day**: Day(s) of week (Sunday default for church context)
- **Volunteers needed**: 1-10, stepper control
- **Generate for**: 1, 3, or 6 months ahead

---

### Step 3: Create and Return

Team lead taps **[Create]**

- Roster is created
- Occurrences are generated
- Returns to Team Detail
- New roster appears in "Upcoming" section

```
┌─────────────────────────────┐
│                             │
│  ✅ Roster created          │
│  12 occurrences generated   │
│                             │
└─────────────────────────────┘
```

Toast appears briefly, then Team Detail shows:

```
┌─────────────────────────────┐
│ ← Media Team                │
├─────────────────────────────┤
│                             │
│ 12 members                  │
│                             │
│ Upcoming                    │
│ ┌─────────────────────────┐ │
│ │ Sun, Jan 21             │ │
│ │ Sunday Service • 9 AM   │ │
│ │ [+ Assign]              │ │
│ │ [+ Assign]              │ │
│ └─────────────────────────┘ │
│                             │
│ ┌─────────────────────────┐ │
│ │ Sun, Jan 28             │ │
│ │ Sunday Service • 9 AM   │ │
│ │ [+ Assign]              │ │
│ │ [+ Assign]              │ │
│ └─────────────────────────┘ │
│                             │
│ Members                     │
│ ...                         │
│                             │
└─────────────────────────────┘
```

---

## Assigning Volunteers

After roster is created, team lead assigns volunteers by tapping **[+ Assign]** on any slot.

### Quick Assign Sheet

```
┌─────────────────────────────┐
│ Assign Volunteer            │
│ Sunday Service • Jan 21     │
├─────────────────────────────┤
│                             │
│ 🔍 Search...                │
│                             │
│ Available                   │
│ ┌─────────────────────────┐ │
│ │ Emma Davis              │ │
│ │ Tom Wilson              │ │
│ │ Lisa Brown              │ │
│ │ David Lee               │ │
│ └─────────────────────────┘ │
│                             │
│ Unavailable                 │
│ ┌─────────────────────────┐ │
│ │ John Smith (Away)       │ │
│ └─────────────────────────┘ │
│                             │
└─────────────────────────────┘
```

Team lead taps a name → Assigned immediately → Notification sent

```
┌─────────────────────────────┐
│                             │
│  ✅ Emma Davis assigned     │
│  Notification sent          │
│                             │
└─────────────────────────────┘
```

Sheet closes, slot now shows assigned person.

---

## Validation

| Field | Rule |
|-------|------|
| Roster name | Required, 3-50 characters |
| Team | Required |
| Recurrence | Required (default: Weekly) |
| Day | At least one selected |
| Volunteers needed | 1-10 |

---

## Error Handling

### Validation Error

```
┌─────────────────────────────┐
│ Roster Name                 │
│ ┌───────────────────────┐   │
│ │ Su                    │   │
│ └───────────────────────┘   │
│ ⚠️ Name must be at least    │
│    3 characters             │
└─────────────────────────────┘
```

### Network Error

```
┌─────────────────────────────┐
│     ⚠️ Couldn't create      │
│                             │
│ Check your connection and   │
│ try again.                  │
│                             │
│ [Retry]                     │
└─────────────────────────────┘
```

---

## Success Criteria

- **Total screens:** 1 (single form)
- **Total taps to create roster:** 3-4 (navigate → fill → create)
- **Total taps to assign volunteer:** 2 (tap slot → tap name)

---

## What's NOT in This Flow

- Review/confirm screen before creation (unnecessary friction)
- Success screen with "next steps" (just return to team)
- AI-powered suggestions (deferred)
- Auto-assign/auto-rotate (deferred)
- Bulk assignment (deferred)
