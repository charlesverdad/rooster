# User Flow: Viewing and Responding to Assignments

**User Role:** Team Member  
**Goal:** View upcoming assignments and respond (accept/decline)  
**Platform:** Mobile-first (iOS/Android), Web-compatible  
**Estimated Time:** 30 seconds - 1 minute

---

## Overview

Team members need a quick, glanceable view of their upcoming commitments and an easy way to respond. This is the most frequently used flow in the app, so it must be fast, clear, and require minimal taps.

---

## User Journey

### Entry Points
1. **Primary:** App launch → Auto-navigate to Home tab (if logged in)
2. **Push notification:** "You have a new assignment" → Opens to Home tab
3. **Email link:** Click assignment link → Opens app to specific assignment

### Success Criteria
- Member sees all upcoming assignments at a glance
- Can accept or decline in 2 taps
- Receives confirmation of action
- Team lead is notified of response

---

## Screen-by-Screen Flow

### Screen 1: Home Dashboard
**Purpose:** Overview of all assignments

**UI Layout (Mobile):**
```
┌─────────────────────────────┐
│ Rooster                  🔔3│
├─────────────────────────────┤
│                             │
│ Welcome back, John! 👋      │
│                             │
│ Your Assignments            │
│                             │
│ ┌─────────────────────────┐ │
│ │ 🔴 PENDING RESPONSE     │ │
│ │                         │ │
│ │ Sunday Service - Media  │ │
│ │ Sun, Jan 21 • 9:00 AM   │ │
│ │                         │ │
│ │ [Decline]    [Accept] ✓ │ │
│ └─────────────────────────┘ │
│                             │
│ ┌─────────────────────────┐ │
│ │ ✅ ACCEPTED             │ │
│ │                         │ │
│ │ Sunday Service - Media  │ │
│ │ Sun, Jan 28 • 9:00 AM   │ │
│ │                         │ │
│ │ Tap to view details     │ │
│ └─────────────────────────┘ │
│                             │
│ ┌─────────────────────────┐ │
│ │ ✅ ACCEPTED             │ │
│ │                         │ │
│ │ Prayer Night - Worship  │ │
│ │ Tue, Jan 23 • 7:00 PM   │ │
│ │                         │ │
│ │ Tap to view details     │ │
│ └─────────────────────────┘ │
│                             │
│ [View All Assignments]      │
│                             │
├─────────────────────────────┤
│ [Home] [Assignments] [🔔]   │
└─────────────────────────────┘
```

**Design Decisions:**
- **Status-first:** Pending assignments at top with red indicator
- **Action buttons visible:** No need to tap into card to respond
- **Visual hierarchy:** 
  - Pending = Red badge + action buttons
  - Accepted = Green checkmark + subtle
  - Declined = Gray + collapsed
- **Key information:** Date, time, and roster name immediately visible
- **Notification badge:** Shows unread count in top right

**Interaction:**
- **Tap card:** Expands to show full details
- **Tap Accept:** Immediate feedback, card turns green, moves to "Accepted" section
- **Tap Decline:** Shows confirmation dialog first
- **Pull to refresh:** Syncs latest assignments

---

### Screen 2: Assignment Detail (Expanded)
**Purpose:** Show full assignment information

**Accessed by:** Tapping on an assignment card

**UI Layout (Mobile):**
```
┌─────────────────────────────┐
│ ← Assignment Details         │
├─────────────────────────────┤
│                             │
│ Sunday Service - Media      │
│ Media Team                  │
│                             │
│ ┌─────────────────────────┐ │
│ │ 📅 Sun, Jan 21, 2026    │ │
│ │ ⏰ 9:00 AM - 11:00 AM   │ │
│ │ 📍 Main Sanctuary       │ │
│ │ 👥 2 volunteers         │ │
│ └─────────────────────────┘ │
│                             │
│ Your Role                   │
│ ┌─────────────────────────┐ │
│ │ Run slides and sound    │ │
│ │ system for service      │ │
│ └─────────────────────────┘ │
│                             │
│ Serving With                │
│ ┌─────────────────────────┐ │
│ │ 👤 Sarah Johnson        │ │
│ │    ✅ Accepted          │ │
│ └─────────────────────────┘ │
│                             │
│ Team Lead                   │
│ ┌─────────────────────────┐ │
│ │ 👤 Mike Chen            │ │
│ │    📞 Contact           │ │
│ └─────────────────────────┘ │
│                             │
│ ⚠️ Can't make it?          │
│ [Request Swap]              │
│                             │
│ [Decline]        [Accept] ✓ │
│                             │
└─────────────────────────────┘
```

**Design Decisions:**
- **All relevant info:** Date, time, location, co-volunteers
- **Social proof:** Show who else is serving (builds commitment)
- **Easy contact:** Quick access to team lead
- **Swap option:** Alternative to declining
- **Persistent actions:** Accept/Decline always visible at bottom

---

### Screen 3: Decline Confirmation
**Purpose:** Confirm decline and optionally provide reason

**UI Layout (Bottom Sheet):**
```
┌─────────────────────────────┐
│ Decline Assignment?         │
├─────────────────────────────┤
│                             │
│ Sunday Service - Media      │
│ Sun, Jan 21, 2026           │
│                             │
│ Your team lead will be      │
│ notified. They may reach    │
│ out to find a replacement.  │
│                             │
│ Reason (optional)           │
│ ┌─────────────────────────┐ │
│ │ ○ Out of town           │ │
│ │ ○ Sick                  │ │
│ │ ○ Work conflict         │ │
│ │ ○ Other                 │ │
│ └─────────────────────────┘ │
│                             │
│ Additional notes            │
│ ┌─────────────────────────┐ │
│ │ (optional)              │ │
│ └─────────────────────────┘ │
│                             │
│ [Cancel]  [Confirm Decline] │
│                             │
└─────────────────────────────┘
```

**Design Decisions:**
- **Soft confirmation:** Not too aggressive, but prevents accidents
- **Optional reason:** Helps team lead understand patterns
- **Quick select:** Common reasons as radio buttons
- **Free text:** For specific situations
- **Clear consequences:** Explain what happens next

---

### Screen 4: Success Feedback
**Purpose:** Confirm action taken

**UI (Toast/Snackbar):**
```
┌─────────────────────────────┐
│                             │
│  ✅ Assignment Accepted     │
│  Mike Chen has been notified│
│                             │
│  [Undo]                     │
│                             │
└─────────────────────────────┘
```

**Design Decisions:**
- **Non-intrusive:** Toast appears at bottom, auto-dismisses
- **Undo option:** 5-second window to reverse action
- **Social feedback:** Mention who was notified
- **Positive reinforcement:** Green color, checkmark

---

## Alternative Flows

### Flow A: Accepting from Notification
**Scenario:** User taps push notification

```
Push Notification:
┌─────────────────────────────┐
│ 🔔 New Assignment           │
│ Sunday Service - Media      │
│ Sun, Jan 21 • 9:00 AM       │
│                             │
│ [Decline]        [Accept]   │
└─────────────────────────────┘
```

**Tap notification body:**
- Opens app to assignment detail screen
- Can accept/decline from there

**Tap "Accept" in notification:**
- Accepts immediately
- Opens app to show confirmation
- No additional taps needed

---

### Flow B: Bulk Response
**Scenario:** User has multiple pending assignments

**UI Enhancement:**
```
┌─────────────────────────────┐
│ 3 Pending Assignments       │
│                             │
│ [Accept All]  [Review Each] │
└─────────────────────────────┘
```

**Design Decisions:**
- **Quick path:** "Accept All" for committed members
- **Careful path:** "Review Each" for those who need to check
- **Smart default:** Only show if 3+ pending assignments

---

## Mobile Optimizations

### Gestures
- **Swipe right on card:** Quick accept
- **Swipe left on card:** Quick decline (with confirmation)
- **Long press:** Show quick actions menu
- **Pull down:** Refresh assignments

### Haptic Feedback
- **Light tap:** On button press
- **Success haptic:** On accept
- **Warning haptic:** On decline confirmation

### Offline Support
- **Cache assignments:** Show last known state
- **Queue actions:** Accept/decline syncs when online
- **Offline indicator:** Show when not connected

---

## Accessibility

### Screen Reader
```
"Assignment card. Sunday Service, Media Team.
Sunday, January 21st, 2026 at 9 AM.
Status: Pending response.
Accept button. Decline button."
```

### Voice Control
- "Accept assignment"
- "Decline assignment"
- "Show assignment details"

### Visual
- **High contrast mode:** Stronger colors for status
- **Large text:** Scales up to 200%
- **Reduced motion:** No animations if preferred

---

## Edge Cases

### Case 1: Assignment in the Past
```
┌─────────────────────────────┐
│ ⏰ PAST ASSIGNMENT          │
│                             │
│ Sunday Service - Media      │
│ Sun, Jan 14 • 9:00 AM       │
│                             │
│ This assignment has passed  │
│ [Mark as Completed]         │
└─────────────────────────────┘
```

### Case 2: Conflicting Assignment
```
┌─────────────────────────────┐
│ ⚠️ CONFLICT DETECTED        │
│                             │
│ Sunday Service - Media      │
│ Sun, Jan 21 • 9:00 AM       │
│                             │
│ You're also assigned to:    │
│ Worship Team at 9:00 AM     │
│                             │
│ [Decline One] [Contact Lead]│
└─────────────────────────────┘
```

### Case 3: Last-Minute Assignment
```
┌─────────────────────────────┐
│ 🔴 URGENT                   │
│                             │
│ Sunday Service - Media      │
│ Tomorrow • 9:00 AM          │
│                             │
│ Sarah Johnson can't make it │
│ Can you fill in?            │
│                             │
│ [Sorry, No]      [Yes! 👍]  │
└─────────────────────────────┘
```

---

## Notification Strategy

### Timing
- **New assignment:** Immediate
- **Reminder:** 7 days before (if not responded)
- **Final reminder:** 24 hours before
- **Day-of:** Morning of assignment

### Content
```
📱 Push: "New assignment: Sunday Service - Jan 21"
📧 Email: Full details + calendar invite
💬 SMS: (Optional) For urgent assignments
```

### Frequency Control
- **Quiet hours:** No notifications 10 PM - 7 AM
- **Batch mode:** Group multiple assignments
- **Snooze:** "Remind me tomorrow"

---

## Performance Targets

- **Load time:** < 1 second for assignment list
- **Action response:** < 200ms perceived (optimistic UI)
- **Offline mode:** Full functionality except sync
- **Battery impact:** < 2% per day with background sync

---

## Analytics to Track

- **Response rate:** % of assignments accepted
- **Response time:** How quickly members respond
- **Decline reasons:** Most common reasons
- **Notification effectiveness:** Which notifications drive responses
- **Drop-off points:** Where users abandon the flow

---

## Future Enhancements

### Smart Features
- **Predictive accept:** "You usually accept Sunday mornings"
- **Auto-decline:** Set recurring unavailability
- **Calendar integration:** Sync with Google/Apple Calendar

### Social Features
- **Team chat:** Message co-volunteers
- **Appreciation:** Thank teammates after serving
- **Streaks:** Gamify consistent service

### Personalization
- **Preferred roles:** Highlight matching assignments
- **Custom notifications:** Choose which alerts to receive
- **Home screen widgets:** Quick glance at next assignment
