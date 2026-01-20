# Rooster App - Information Architecture

**Version:** 2.1
**Last Updated:** January 2026
**Platform:** Mobile-first (iOS/Android), Web-compatible
**Design Philosophy:** Notification-first, minimal screens, get in and get out

---

## Core Principle

Rooster is a **reminder tool**, not an engagement platform. Users should spend minimal time in the app. The primary interface is push notifications and email—the app exists to support those.

**Start with names, invite later**: Team leads can roster people by name without requiring signups. Invite them when ready—they auto-join with assignments intact.

---

## Navigation Structure

### Header Bar (All Screens)

```
┌─────────────────────────────────────┐
│ Rooster                    🔔 ⚙️    │
└─────────────────────────────────────┘
```

- **🔔 Notifications**: Opens notification list
- **⚙️ Settings**: Opens settings screen

No bottom navigation. Home is the app.

---

## Screen Inventory (14 Screens)

### 1. Authentication

#### 1.1 Login
**Route:** `/login`
**Access:** Public

```
┌─────────────────────────────┐
│                             │
│         Rooster             │
│   Volunteer Scheduling      │
│                             │
│  Email                      │
│  ┌───────────────────────┐  │
│  │                       │  │
│  └───────────────────────┘  │
│                             │
│  Password                   │
│  ┌───────────────────────┐  │
│  │                       │  │
│  └───────────────────────┘  │
│                             │
│  [Login]                    │
│                             │
│  Don't have an account?     │
│  [Register]                 │
│                             │
└─────────────────────────────┘
```

**Links to:** Register (1.2), Home (2.1) on success

---

#### 1.2 Register
**Route:** `/register`
**Access:** Public

```
┌─────────────────────────────┐
│ ← Create Account            │
├─────────────────────────────┤
│                             │
│  Full Name                  │
│  ┌───────────────────────┐  │
│  │                       │  │
│  └───────────────────────┘  │
│                             │
│  Email                      │
│  ┌───────────────────────┐  │
│  │                       │  │
│  └───────────────────────┘  │
│                             │
│  Password                   │
│  ┌───────────────────────┐  │
│  │                       │  │
│  └───────────────────────┘  │
│                             │
│  [Create Account]           │
│                             │
│  Already have an account?   │
│  [Login]                    │
│                             │
└─────────────────────────────┘
```

**Links to:** Login (1.1), Home (2.1) on success

---

#### 1.3 Accept Invite (Special Registration)
**Route:** `/invite/:token`
**Access:** Public (with valid invite token)

When a placeholder user is invited, they receive this link.

```
┌─────────────────────────────┐
│                             │
│         Rooster             │
│                             │
│  You've been invited to     │
│  join Media Team            │
│                             │
│  Hi John! Create your       │
│  account to see your        │
│  assignments.               │
│                             │
│  Email                      │
│  ┌───────────────────────┐  │
│  │ john@email.com        │  │
│  └───────────────────────┘  │
│  (pre-filled from invite)   │
│                             │
│  Password                   │
│  ┌───────────────────────┐  │
│  │                       │  │
│  └───────────────────────┘  │
│                             │
│  [Join Team]                │
│                             │
└─────────────────────────────┘
```

**On success:**
- Placeholder user becomes registered user
- All existing assignments remain linked
- Redirects to Home with assignments visible

---

### 2. Home

#### 2.1 Home (Adaptive)
**Route:** `/home`
**Access:** All authenticated users

This is the only main screen. It adapts based on role.

**Member View:**
```
┌─────────────────────────────┐
│ Rooster              🔔  ⚙️  │
├─────────────────────────────┤
│                             │
│ Hi John                     │
│                             │
│ Action Required             │
│ ┌─────────────────────────┐ │
│ │ 🔴 Sunday Service       │ │
│ │ Media Team              │ │
│ │ Tomorrow • 9:00 AM      │ │
│ │                         │ │
│ │ [Decline]    [Accept]   │ │
│ └─────────────────────────┘ │
│                             │
│ Upcoming                    │
│ ┌─────────────────────────┐ │
│ │ ✅ Sunday Service       │ │
│ │ Media Team              │ │
│ │ In 8 days • 9:00 AM     │ │
│ └─────────────────────────┘ │
│                             │
│ My Teams                    │
│ Media Team • Worship Team   │
│                             │
└─────────────────────────────┘
```

**Team Lead View (same screen, extra section):**
```
┌─────────────────────────────┐
│ Rooster              🔔  ⚙️  │
├─────────────────────────────┤
│                             │
│ Hi Mike                     │
│                             │
│ ⚠️ Needs Attention          │
│ ┌─────────────────────────┐ │
│ │ Media Team              │ │
│ │ Sun, Jan 28 • 1 unfilled│ │
│ │ [+ Assign]              │ │
│ └─────────────────────────┘ │
│                             │
│ Action Required             │
│ (personal pending items)    │
│                             │
│ Upcoming                    │
│ (personal upcoming items)   │
│                             │
│ My Teams                    │
│ Media Team (Lead)           │
│                             │
└─────────────────────────────┘
```

**Components:**
- Greeting (just name)
- Needs Attention section (team leads only, collapsible)
- Action Required (pending assignments)
- Upcoming (accepted assignments, next 4 weeks)
- My Teams (tap to view team)

**Links to:**
- Assignment Detail (3.1) - tap any assignment card
- Team Detail (4.1) - tap team name
- Quick Assign (5.2) - tap "[+ Assign]"
- Notifications (7.1) - bell icon
- Settings (7.2) - gear icon

---

### 3. Assignments

#### 3.1 Assignment Detail
**Route:** `/assignments/:id`
**Access:** Assigned user

```
┌─────────────────────────────┐
│ ← Assignment                │
├─────────────────────────────┤
│                             │
│ Sunday Service              │
│ Media Team                  │
│                             │
│ ┌─────────────────────────┐ │
│ │ 📅 Sun, Jan 21, 2026    │ │
│ │ ⏰ 9:00 AM - 11:00 AM   │ │
│ │ 📍 Main Sanctuary       │ │
│ └─────────────────────────┘ │
│                             │
│ Notes                       │
│ ┌─────────────────────────┐ │
│ │ Run slides and sound    │ │
│ │ system for service      │ │
│ └─────────────────────────┘ │
│                             │
│ Also Serving                │
│ ┌─────────────────────────┐ │
│ │ Sarah Johnson ✅        │ │
│ │ Tom Wilson (invited)    │ │
│ └─────────────────────────┘ │
│                             │
│ Team Lead                   │
│ ┌─────────────────────────┐ │
│ │ Mike Chen               │ │
│ │ [Contact]               │ │
│ └─────────────────────────┘ │
│                             │
│ [Decline]        [Accept]   │
│                             │
└─────────────────────────────┘
```

**Note:** Co-volunteers may include placeholders, shown with "(invited)" or "(not yet invited)" indicator.

**Links to:**
- Decline Confirmation (3.2) - tap Decline
- Contact options - tap Contact
- Back to Home

---

#### 3.2 Decline Confirmation
**Route:** Bottom sheet over Assignment Detail
**Access:** Assigned user

```
┌─────────────────────────────┐
│ Decline this assignment?    │
├─────────────────────────────┤
│                             │
│ Sunday Service • Jan 21     │
│                             │
│ Your team lead will be      │
│ notified.                   │
│                             │
│ Reason (optional)           │
│ ┌─────────────────────────┐ │
│ │ ○ Can't make it         │ │
│ │ ○ Schedule conflict     │ │
│ │ ○ Other                 │ │
│ └─────────────────────────┘ │
│                             │
│ [Cancel]  [Confirm Decline] │
│                             │
└─────────────────────────────┘
```

---

### 4. Teams

#### 4.1 Team Detail
**Route:** `/teams/:id`
**Access:** Team members

```
┌─────────────────────────────┐
│ ← Media Team                │
├─────────────────────────────┤
│                             │
│ 12 members (3 not invited)  │
│                             │
│ Upcoming                    │
│ ┌─────────────────────────┐ │
│ │ Sun, Jan 21             │ │
│ │ Sunday Service • 9 AM   │ │
│ │ John Smith ✅           │ │
│ │ Sarah Johnson ✅        │ │
│ └─────────────────────────┘ │
│                             │
│ ┌─────────────────────────┐ │
│ │ Sun, Jan 28             │ │
│ │ Sunday Service • 9 AM   │ │
│ │ Mike Chen ✅            │ │
│ │ Tom Wilson ○            │ │
│ └─────────────────────────┘ │
│                             │
│ Members                     │
│ ┌─────────────────────────┐ │
│ │ Mike Chen (Lead)        │ │
│ │ John Smith              │ │
│ │ Sarah Johnson           │ │
│ │ Tom Wilson ○ [Invite]   │ │
│ │ + 8 more                │ │
│ └─────────────────────────┘ │
│                             │
│ [+ Add Member]              │
│ [+ Create Roster]           │
│ (Team leads only)           │
│                             │
└─────────────────────────────┘
```

**Legend:**
- ✅ = Accepted
- ⏳ = Pending (registered user, hasn't responded)
- ○ = Placeholder (not yet invited)
- [Invite] button appears next to placeholders for team leads

**Links to:**
- Quick Assign (5.2) - tap "[+ Assign]"
- Create Roster (5.1) - tap "[+ Create Roster]"
- Add Member (4.2) - tap "[+ Add Member]"
- Member Detail (4.3) - tap member name
- Invite flow (6.1) - tap "[Invite]"

---

#### 4.2 Add Member (Bottom Sheet)
**Route:** Bottom sheet
**Access:** Team Lead

```
┌─────────────────────────────┐
│ Add Team Member             │
├─────────────────────────────┤
│                             │
│ Name                        │
│ ┌───────────────────────┐   │
│ │ John Smith            │   │
│ └───────────────────────┘   │
│                             │
│ You can invite them via     │
│ email later.                │
│                             │
│ [Cancel]        [Add]       │
│                             │
└─────────────────────────────┘
```

**On Add:**
- Creates placeholder user with just the name
- Adds to team
- Can be assigned to rosters immediately
- Toast: "John Smith added to team"

---

#### 4.3 Member Detail
**Route:** `/teams/:id/members/:userId`
**Access:** Team Lead

**For registered member:**
```
┌─────────────────────────────┐
│ ← John Smith                │
├─────────────────────────────┤
│                             │
│       👤                    │
│    John Smith               │
│    john@email.com           │
│                             │
│ Upcoming Assignments        │
│ ┌─────────────────────────┐ │
│ │ Sun, Jan 21 ✅          │ │
│ │ Sun, Jan 28 ⏳          │ │
│ └─────────────────────────┘ │
│                             │
│ [Contact]                   │
│                             │
└─────────────────────────────┘
```

**For placeholder member:**
```
┌─────────────────────────────┐
│ ← Tom Wilson                │
├─────────────────────────────┤
│                             │
│       ○                     │
│    Tom Wilson               │
│    Not yet invited          │
│                             │
│ Upcoming Assignments        │
│ ┌─────────────────────────┐ │
│ │ Sun, Jan 28 (assigned)  │ │
│ │ Sun, Feb 4 (assigned)   │ │
│ └─────────────────────────┘ │
│                             │
│ Invite Tom to let them      │
│ see their assignments and   │
│ respond.                    │
│                             │
│ [Invite via Email]          │
│                             │
└─────────────────────────────┘
```

**Links to:** Invite Flow (6.1) - tap "[Invite via Email]"

---

### 5. Roster Management (Team Leads)

#### 5.1 Create Roster
**Route:** `/rosters/create`
**Access:** Team Lead

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
│                             │
│ Repeats                     │
│ ┌───────────────────────┐   │
│ │ ● Weekly              │   │
│ │ ○ Bi-weekly           │   │
│ │ ○ Monthly             │   │
│ └───────────────────────┘   │
│                             │
│ Day                         │
│ [S] M  T  W  T  F  S        │
│  ●                          │
│                             │
│ Volunteers needed           │
│       [-]  2  [+]           │
│                             │
│          [Create]           │
│                             │
└─────────────────────────────┘
```

**On Create:** Returns to Team Detail with new roster visible

---

#### 5.2 Quick Assign
**Route:** Bottom sheet
**Access:** Team Lead

```
┌─────────────────────────────┐
│ Assign Volunteer            │
│ Sunday Service • Jan 28     │
├─────────────────────────────┤
│                             │
│ 🔍 Search...                │
│                             │
│ Available                   │
│ ┌─────────────────────────┐ │
│ │ Emma Davis              │ │
│ │ Tom Wilson ○            │ │
│ │ Lisa Brown              │ │
│ │ David Lee ○             │ │
│ └─────────────────────────┘ │
│                             │
│ Unavailable                 │
│ ┌─────────────────────────┐ │
│ │ John Smith (Away)       │ │
│ │ Sarah J. (Assigned)     │ │
│ └─────────────────────────┘ │
│                             │
└─────────────────────────────┘
```

**Legend:**
- ○ = Placeholder (no account yet)
- Members without ○ are registered users

**Interaction:** Tap name → Assigns immediately → Shows toast → Closes sheet

**Toast messages:**
- For registered user: "Emma Davis assigned. Notification sent."
- For placeholder: "Tom Wilson assigned. Invite them to notify."

---

### 6. Invite Flow

#### 6.1 Send Invite
**Route:** Bottom sheet (from Member Detail or Team Detail)
**Access:** Team Lead

```
┌─────────────────────────────┐
│ Invite Tom Wilson           │
├─────────────────────────────┤
│                             │
│ Tom has 2 upcoming          │
│ assignments. Once invited,  │
│ they can see and respond.   │
│                             │
│ Email                       │
│ ┌───────────────────────┐   │
│ │ tom@email.com         │   │
│ └───────────────────────┘   │
│                             │
│ [Cancel]    [Send Invite]   │
│                             │
└─────────────────────────────┘
```

**On Send:**
- Invite email sent with unique link
- Toast: "Invite sent to tom@email.com"
- Member shown as "Invited" in UI

**Invite states:**
- ○ Not invited (placeholder)
- ✉️ Invited (email sent, not accepted)
- ✓ Registered (has account)

---

### 7. Settings & Notifications

#### 7.1 Notifications
**Route:** `/notifications`
**Access:** All users

```
┌─────────────────────────────┐
│ ← Notifications             │
├─────────────────────────────┤
│                             │
│ ┌─────────────────────────┐ │
│ │ 🔴 New Assignment       │ │
│ │ Sunday Service - Media  │ │
│ │ Sun, Jan 21 • 9:00 AM   │ │
│ │ 2 hours ago             │ │
│ └─────────────────────────┘ │
│                             │
│ ┌─────────────────────────┐ │
│ │ ✅ Tom accepted         │ │
│ │ Sunday Service • Jan 28 │ │
│ │ Yesterday               │ │
│ └─────────────────────────┘ │
│                             │
│ ┌─────────────────────────┐ │
│ │ Reminder                │ │
│ │ Sunday Service tomorrow │ │
│ │ 2 days ago              │ │
│ └─────────────────────────┘ │
│                             │
└─────────────────────────────┘
```

**Links to:** Assignment Detail - tap notification

---

#### 7.2 Settings
**Route:** `/settings`
**Access:** All users

```
┌─────────────────────────────┐
│ ← Settings                  │
├─────────────────────────────┤
│                             │
│ Profile                     │
│ ┌─────────────────────────┐ │
│ │ John Smith              │ │
│ │ john@email.com          │ │
│ │ [Edit]                  │ │
│ └─────────────────────────┘ │
│                             │
│ Notifications               │
│ ┌─────────────────────────┐ │
│ │ Push notifications  [✓] │ │
│ │ Email reminders     [✓] │ │
│ └─────────────────────────┘ │
│                             │
│ About                       │
│ ┌─────────────────────────┐ │
│ │ Help & Support          │ │
│ │ Version 1.0.0           │ │
│ └─────────────────────────┘ │
│                             │
│ [Logout]                    │
│                             │
└─────────────────────────────┘
```

---

## User Journeys

### Team Lead: First Time Setup

```
Create account
    ↓
Home (empty)
    ↓
"Create your first team" prompt
    ↓
Create team: "Media Team"
    ↓
Add members by name:
  - John Smith
  - Sarah Johnson
  - Tom Wilson
    ↓
Create roster: "Sunday Service"
    ↓
Assign John & Sarah to Jan 21
Assign Tom to Jan 28
    ↓
Done! (Can invite people later)
```

**Total time:** Under 5 minutes to have a working roster

---

### Team Lead: Invite a Placeholder

```
Team Detail → See Tom Wilson ○
    ↓
Tap Tom → Member Detail
    ↓
Tap "Invite via Email"
    ↓
Enter tom@email.com
    ↓
Tap "Send Invite"
    ↓
Toast: "Invite sent"
```

**Total taps:** 4

---

### New Member: Accept Invite

```
Email: "You've been invited to Media Team"
    ↓
Click link
    ↓
Accept Invite screen (name pre-filled)
    ↓
Enter email + password
    ↓
Tap "Join Team"
    ↓
Home screen with assignments visible
```

**Total taps:** 3 (link → fill form → join)

---

### Member: Respond to Assignment

```
Push notification: "New assignment: Sunday Service"
    ↓
Tap notification
    ↓
Assignment Detail screen
    ↓
Tap [Accept]
    ↓
Done
```

**Total taps:** 2

---

## Design System

### Colors

| Use | Color | Hex |
|-----|-------|-----|
| Primary action | Purple | #673AB7 |
| Success/Accepted | Green | #4CAF50 |
| Warning/Pending | Orange | #FF9800 |
| Error/Declined | Red | #F44336 |
| Placeholder indicator | Gray | #9E9E9E |
| Background | White | #FFFFFF |
| Text | Dark gray | #212121 |
| Secondary text | Gray | #757575 |

### Member Status Indicators

| Symbol | Meaning |
|--------|---------|
| ✅ | Accepted assignment |
| ⏳ | Pending response (registered user) |
| ○ | Placeholder (not yet invited) |
| ✉️ | Invited (email sent) |

### Typography

| Style | Size | Weight |
|-------|------|--------|
| Page title | 24px | Bold |
| Section header | 18px | Semibold |
| Card title | 16px | Medium |
| Body | 16px | Regular |
| Caption | 14px | Regular |

### Spacing

- Base unit: 8px
- Card padding: 16px
- Section gap: 24px
- Screen margin: 16px

---

## Accessibility

- Touch targets: 44x44pt minimum
- Contrast: 4.5:1 for text
- Screen reader labels on all interactive elements
- Placeholder status announced for screen readers

---

## Performance

- Home screen load: < 1 second
- Action response: < 200ms (optimistic UI)
- Offline: Show cached data, queue actions

---

## What's NOT Included

The following features were intentionally excluded to keep the app focused:

- Admin role / organization management
- Analytics dashboards
- Response rate tracking
- Service history
- Calendar view
- Browse/discover teams
- Member profiles with stats
- Complex onboarding flows
- Gamification (streaks, badges)

These may be reconsidered if user feedback indicates genuine need.
