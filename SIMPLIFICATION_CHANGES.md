# Rooster App Simplification Changes

**Date:** January 2026
**Purpose:** Streamline the app to focus on its core mission: helping volunteers get reminded about their assignments.

---

## Philosophy

The previous design was overbuilt for the core use case. Rooster's goal is **not** to keep users engaged—it's to remind them of their commitments and let them respond quickly. Users should spend minimal time in the app.

### Guiding Principles

1. **Notification-first**: Push notifications and email are the primary interface, not the app
2. **Minimum viable screens**: Cut anything that doesn't serve reminders
3. **One home, progressive disclosure**: Single home screen that adapts to role, not three separate experiences
4. **No vanity metrics**: Remove analytics, response rates, and service history that don't help reminders
5. **Direct paths**: Most tasks should complete in 1-2 taps

---

## What Was Removed

### Entire Sections Cut

| Section | Reason |
|---------|--------|
| **Team Analytics (7.1)** | Doesn't serve reminder purpose. Creates social pressure. |
| **Organization Analytics (7.2)** | Admin overhead, not core functionality. |
| **Member Profile with stats** | "95% response rate" and service history creates unnecessary gamification. |
| **Browse Teams (4.5)** | Discovery isn't needed—team leads add members directly. |
| **5-step onboarding flow** | Too much friction. Just login and see assignments. |
| **Three separate home dashboards** | Replaced with single adaptive home screen. |

### Features Simplified

| Feature | Before | After |
|---------|--------|-------|
| **Bottom navigation** | 4 tabs (Home, Assignments, Teams, More) | 2 primary views (Home, Settings via icon) |
| **Notification preferences** | 10+ toggleable options | Simple on/off with "reduce notifications" option |
| **Assignment views** | Calendar view, List view, Stats view | List view only |
| **Roster detail** | Calendar, List, Stats tabs | Simple list of upcoming dates |
| **Team detail** | Members, Rosters, About tabs | Single scrollable page |

### Screens Removed

- Organization Overview Dashboard (Admin)
- All Teams management view
- Browse Teams
- Team Analytics
- Organization Analytics
- Member Profile (replaced with simple contact card)
- Separate Team Lead Dashboard (merged into adaptive home)

---

## New Simplified Architecture

### Screen Count

| Before | After |
|--------|-------|
| 30+ screens | 12 core screens |

### Navigation Structure

**Before:**
```
Bottom Nav: [Home] [Assignments] [Teams] [More]
           + role-specific variations
```

**After:**
```
Home (with notifications bell + settings icon in header)
└── Pending assignments (action cards)
└── Upcoming assignments (next 4 weeks)
└── Team lead section (if applicable, collapsible)
```

### Core Screens (12 total)

1. **Login** - Email/password
2. **Register** - Name, email, password
3. **Home** - Adaptive single screen for all roles
4. **Assignment Detail** - Full info + accept/decline
5. **My Teams** - Simple list of teams user belongs to
6. **Team Detail** - Members + upcoming roster dates
7. **Create Roster** - Simplified 3-step flow (basics, schedule, slots)
8. **Assign Volunteers** - Quick assign interface
9. **Notifications** - In-app notification list
10. **Settings** - Profile, notification toggle, logout
11. **Decline Confirmation** - Bottom sheet with optional reason
12. **Contact Team Lead** - Simple contact options

---

## User Flow Changes

### Member Flow (unchanged in spirit, fewer taps)

```
Notification arrives
    ↓
Tap notification → Opens Assignment Detail
    ↓
Tap Accept/Decline
    ↓
Done (app closes or returns to home)
```

### Team Lead Flow (simplified)

```
Home shows:
- "Needs Attention" section (unfilled slots)
- Tap "[+ Assign]" → Quick assign bottom sheet
- Done
```

No separate dashboard. No analytics. Just fill the gaps.

---

## PRD Changes

### MVP Scope Adjustments

**Removed from MVP:**
- Calendar view (list view is simpler and sufficient)
- Organization-wide calendar
- Member directory as separate view
- Analytics of any kind
- Multi-step onboarding

**Kept in MVP:**
- Email/password auth
- Single organization
- Teams and members
- Rosters with manual assignment
- Accept/decline assignments
- Basic notifications
- Unavailability marking

**Moved to "Maybe Later" (not Phase 2):**
- Analytics and reporting
- Browse/discover teams
- Service history tracking
- Response rate metrics

### Data Model Simplification

**Removed fields:**
- `Assignment.acknowledged_at` - Just use accept/decline
- `User.response_rate` - Not tracking this
- `Team.health_score` - Not calculating this

---

## User Flow Document Changes

### 01_viewing_and_responding_to_assignments.md
- Simplified to focus on the 2-tap accept/decline flow
- Removed bulk response feature
- Removed analytics tracking section
- Removed gamification features (streaks, appreciation)

### 00_creating_a_schedule.md
- Reduced from 6 screens to 3 screens
- Removed Review & Confirm screen (just create directly)
- Removed Success & Next Steps screen (return to roster)
- Simplified slot configuration

### 02_team_lead_dashboard.md
- **Deleted entirely**
- Content merged into main home screen documentation
- Team leads see same home with additional "Needs Attention" section

---

## Design System Changes

### Removed Components
- Analytics charts
- Health score indicators
- Leaderboards
- Service history graphs
- Multiple view toggles (Calendar/List/Stats)

### Simplified Components
- Assignment cards: Just status, title, date, action buttons
- Team cards: Just name, member count, next date
- Notifications: Just type, message, timestamp

---

## Migration Notes

If existing code references removed features:

1. **Analytics endpoints** - Can be removed or stubbed
2. **Multiple dashboard routes** - Redirect to single `/home`
3. **Browse teams** - Remove route entirely
4. **Member stats** - Remove from profile views

---

## Success Criteria (Revised)

**Old metrics (removed):**
- Response rate percentage
- Average response time
- Member engagement scores
- Coverage rate trends

**New metrics (simple):**
- Are assignments getting filled? (binary)
- Are people showing up? (feedback from team leads)
- Do users complain about missing notifications? (support tickets)

---

## Summary

This simplification removes approximately 60% of the planned screens and features. The app becomes a focused tool for one job: making sure volunteers know when they're scheduled and can respond easily.

Users should think of Rooster like a smart calendar reminder, not a social platform or management dashboard.
