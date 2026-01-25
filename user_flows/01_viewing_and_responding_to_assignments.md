# User Flow: Viewing and Responding to Assignments

**User Role:** Team Member
**Goal:** View upcoming assignments and respond (accept/decline)
**Primary Interface:** Push notification → App

---

## Overview

This is the most common flow in the app. A volunteer receives a notification about an assignment and responds. The goal is **2 taps** from notification to done.

---

## Entry Points

1. **Push notification** (primary) - "New assignment: Sunday Service"
2. **App launch** - Home screen shows pending assignments
3. **Email link** - Opens app to assignment detail

---

## The Flow

### Step 1: Notification Arrives

```
┌─────────────────────────────┐
│ 🔔 Rooster                  │
│ New assignment              │
│ Sunday Service - Media Team │
│ Sun, Jan 21 • 9:00 AM       │
└─────────────────────────────┘
```

User taps notification → App opens to Assignment Detail

---

### Step 2: Assignment Detail

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

**Key information shown:**
- Date, time, location
- Role/notes (what they'll be doing)
- Who else is serving (social accountability)
- Team lead contact (if they have questions)

---

### Step 3a: Accept

User taps **[Accept]**

```
┌─────────────────────────────┐
│                             │
│  ✅ Accepted                │
│  Team lead notified         │
│                             │
└─────────────────────────────┘
```

Toast appears for 3 seconds. User can close app or continue browsing.

**Backend actions:**
- Assignment status → "accepted"
- Notification sent to team lead
- Assignment moves to "Upcoming" on home screen

---

### Step 3b: Decline

User taps **[Decline]** → Bottom sheet appears

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

User taps **[Confirm Decline]**

```
┌─────────────────────────────┐
│                             │
│  Declined                   │
│  Team lead notified         │
│                             │
└─────────────────────────────┘
```

**Backend actions:**
- Assignment status → "declined"
- Notification sent to team lead with reason
- Assignment removed from user's list

---

## Alternative: Respond from Home Screen

If user opens app directly (not from notification):

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
│ │ ✅ Prayer Night         │ │
│ │ Worship Team            │ │
│ │ In 3 days • 7:00 PM     │ │
│ └─────────────────────────┘ │
│                             │
└─────────────────────────────┘
```

User can:
- Tap **[Accept]** directly on card (1 tap)
- Tap **[Decline]** → confirmation sheet (2 taps)
- Tap card body → opens Assignment Detail for more info

---

## Notification Schedule

| Trigger | Timing | Channel |
|---------|--------|---------|
| New assignment | Immediate | Push + Email |
| Reminder (if pending) | 1 day before | Push |
| Day-of reminder | Morning of | Push |

---

## Edge Cases

### Past Assignment

If assignment date has passed:

```
┌─────────────────────────────┐
│ This assignment has passed  │
│                             │
│ [Dismiss]                   │
└─────────────────────────────┘
```

### Already Responded

If user has already accepted/declined:

- Show current status
- No action buttons
- Just informational view

---

## Success Criteria

- **Total taps to accept:** 2 (notification → accept)
- **Total taps to decline:** 3 (notification → decline → confirm)
- **Time to complete:** Under 10 seconds

---

## What's NOT in This Flow

- Swap requests (deferred)
- Calendar integration (deferred)
- Bulk accept/decline (unnecessary complexity)
- Response time tracking (no gamification)
