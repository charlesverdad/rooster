# User Flow: Creating a Roster Schedule

**User Role:** Team Lead  
**Goal:** Create a recurring roster schedule and assign team members  
**Platform:** Mobile-first (iOS/Android), Web-compatible  
**Estimated Time:** 2-3 minutes

---

## Overview

Team leads need to create roster schedules for recurring events (e.g., "Sunday Service - Media Team"). This flow should be intuitive, minimize cognitive load, and make it easy to set up complex recurring patterns without overwhelming the user.

---

## User Journey

### Entry Points
1. **Primary:** From Team Detail screen → FAB "Create Roster"
2. **Secondary:** From empty Rosters tab → "Create Your First Roster" CTA
3. **Quick action:** From dashboard → "Manage Rosters" → Team selection → Create

### Success Criteria
- Roster created with clear recurrence pattern
- Team members assigned to slots
- First few occurrences generated
- Team members notified

---

## Screen-by-Screen Flow

### Screen 1: Roster Basics
**Purpose:** Capture essential roster information

**UI Layout (Mobile):**
```
┌─────────────────────────────┐
│ ← Create Roster             │
├─────────────────────────────┤
│                             │
│ Roster Name *               │
│ ┌─────────────────────────┐ │
│ │ Sunday Service - Media  │ │
│ └─────────────────────────┘ │
│                             │
│ Team                        │
│ ┌─────────────────────────┐ │
│ │ Media Team          ▼   │ │
│ └─────────────────────────┘ │
│                             │
│ Description (optional)      │
│ ┌─────────────────────────┐ │
│ │ Run slides and sound    │ │
│ │ for Sunday service      │ │
│ └─────────────────────────┘ │
│                             │
│                             │
│         [Continue]          │
│                             │
└─────────────────────────────┘
```

**Design Decisions:**
- **Auto-fill team name:** Pre-select if coming from team context
- **Smart defaults:** Suggest roster name based on team (e.g., "[Team Name] - Sunday")
- **Progressive disclosure:** Don't show all options at once
- **Clear hierarchy:** Required fields marked with *, optional clearly labeled

**Validation:**
- Roster name: 3-50 characters, required
- Team: Must be selected, required
- Description: Optional, max 200 characters

---

### Screen 2: Recurrence Pattern
**Purpose:** Define when the roster repeats

**UI Layout (Mobile):**
```
┌─────────────────────────────┐
│ ← Recurrence Pattern        │
├─────────────────────────────┤
│                             │
│ How often does this repeat? │
│                             │
│ ┌─────────────────────────┐ │
│ │ ● Weekly                │ │
│ │ ○ Bi-weekly             │ │
│ │ ○ Monthly               │ │
│ │ ○ Custom                │ │
│ └─────────────────────────┘ │
│                             │
│ Which day?                  │
│ ┌─────────────────────────┐ │
│ │ Sun Mon Tue Wed Thu Fri │ │
│ │ [●] [ ] [ ] [ ] [ ] [ ] │ │
│ │                    Sat  │ │
│ │                    [ ]  │ │
│ └─────────────────────────┘ │
│                             │
│ Start Date                  │
│ ┌─────────────────────────┐ │
│ │ Jan 21, 2026        📅  │ │
│ └─────────────────────────┘ │
│                             │
│ Generate schedule for       │
│ ┌─────────────────────────┐ │
│ │ Next 3 months       ▼   │ │
│ └─────────────────────────┘ │
│                             │
│         [Continue]          │
│                             │
└─────────────────────────────┘
```

**Design Decisions:**
- **Visual day selector:** Tap to select, more intuitive than dropdown
- **Smart defaults:** 
  - Weekly is most common, pre-selected
  - Sunday pre-selected for church context
  - Start date = next occurrence
  - Generate 3 months by default
- **Progressive complexity:** "Custom" option reveals advanced settings
- **Clear preview:** Show "Next occurrence: Sunday, Jan 21" below selections

**Interaction Details:**
- Tapping a day toggles selection (for multi-day rosters)
- Monthly option reveals: "Which week?" (1st, 2nd, 3rd, 4th, Last)
- Custom option reveals: "Every [X] [weeks/months]"

---

### Screen 3: Slot Configuration
**Purpose:** Define how many people are needed

**UI Layout (Mobile):**
```
┌─────────────────────────────┐
│ ← Volunteers Needed          │
├─────────────────────────────┤
│                             │
│ How many volunteers needed  │
│ per occurrence?             │
│                             │
│ ┌─────────────────────────┐ │
│ │      [-]  2  [+]        │ │
│ └─────────────────────────┘ │
│                             │
│ Assignment Method           │
│ ┌─────────────────────────┐ │
│ │ ● Manual Assignment     │ │
│ │   You assign people     │ │
│ │                         │ │
│ │ ○ Auto-Rotate (Pro)     │ │
│ │   System rotates fairly │ │
│ │                         │ │
│ │ ○ Random (Pro)          │ │
│ │   Random from available │ │
│ └─────────────────────────┘ │
│                             │
│ ℹ️ You can assign people   │
│   after creating the roster │
│                             │
│         [Create Roster]     │
│                             │
└─────────────────────────────┘
```

**Design Decisions:**
- **Large touch targets:** +/- buttons easy to tap
- **Visual feedback:** Number updates with animation
- **Contextual help:** Explain what each method means
- **Upgrade path:** Show Pro features but keep them accessible
- **Reassurance:** Let users know they can assign later

**Validation:**
- Slots needed: 1-10 (reasonable limit)
- Assignment method: Required selection

---

### Screen 4: Review & Confirm
**Purpose:** Review roster before creation

**UI Layout (Mobile):**
```
┌─────────────────────────────┐
│ ← Review Roster              │
├─────────────────────────────┤
│                             │
│ Sunday Service - Media      │
│ Media Team                  │
│                             │
│ ┌─────────────────────────┐ │
│ │ 📅 Every Sunday         │ │
│ │ 👥 2 volunteers needed  │ │
│ │ 📝 Manual assignment    │ │
│ │ 🗓️  Starts Jan 21, 2026 │ │
│ │ 📊 12 occurrences       │ │
│ └─────────────────────────┘ │
│                             │
│ Next 3 Occurrences:         │
│ ┌─────────────────────────┐ │
│ │ • Sun, Jan 21, 2026     │ │
│ │ • Sun, Jan 28, 2026     │ │
│ │ • Sun, Feb 4, 2026      │ │
│ └─────────────────────────┘ │
│                             │
│ [Edit]      [Create Roster] │
│                             │
└─────────────────────────────┘
```

**Design Decisions:**
- **Visual summary:** Icons make it scannable
- **Preview dates:** Show actual dates to catch errors
- **Easy editing:** Back button or Edit to fix mistakes
- **Clear CTA:** Green "Create Roster" button stands out

---

### Screen 5: Success & Next Steps
**Purpose:** Confirm creation and guide next action

**UI Layout (Mobile):**
```
┌─────────────────────────────┐
│                             │
│         ✅                  │
│                             │
│   Roster Created!           │
│                             │
│ Sunday Service - Media      │
│ has been created with       │
│ 12 occurrences              │
│                             │
│ What's next?                │
│                             │
│ ┌─────────────────────────┐ │
│ │ 📝 Assign Volunteers    │ │
│ │ Fill the first few slots│ │
│ └─────────────────────────┘ │
│                             │
│ ┌─────────────────────────┐ │
│ │ 👀 View Roster          │ │
│ │ See all occurrences     │ │
│ └─────────────────────────┘ │
│                             │
│ ┌─────────────────────────┐ │
│ │ ✨ Create Another       │ │
│ │ Add more rosters        │ │
│ └─────────────────────────┘ │
│                             │
│        [Done]               │
│                             │
└─────────────────────────────┘
```

**Design Decisions:**
- **Celebration:** Success icon and positive message
- **Guided next steps:** Clear options for what to do next
- **Primary action:** "Assign Volunteers" is most common next step
- **Flexibility:** Allow viewing or creating another
- **Easy exit:** "Done" returns to roster list

---

## Assignment Sub-Flow

### Screen 6: Assign Volunteers (Accessed from Success screen or Roster detail)
**Purpose:** Assign team members to specific dates

**UI Layout (Mobile):**
```
┌─────────────────────────────┐
│ ← Assign Volunteers          │
├─────────────────────────────┤
│ Sunday Service - Media      │
│ 2 volunteers needed         │
│                             │
│ ┌─────────────────────────┐ │
│ │ Sun, Jan 21, 2026       │ │
│ │ ┌─────────────────────┐ │ │
│ │ │ + Add volunteer     │ │ │
│ │ │ + Add volunteer     │ │ │
│ │ └─────────────────────┘ │ │
│ └─────────────────────────┘ │
│                             │
│ ┌─────────────────────────┐ │
│ │ Sun, Jan 28, 2026       │ │
│ │ ┌─────────────────────┐ │ │
│ │ │ + Add volunteer     │ │ │
│ │ │ + Add volunteer     │ │ │
│ │ └─────────────────────┘ │ │
│ └─────────────────────────┘ │
│                             │
│ ┌─────────────────────────┐ │
│ │ Sun, Feb 4, 2026        │ │
│ │ ┌─────────────────────┐ │ │
│ │ │ + Add volunteer     │ │ │
│ │ │ + Add volunteer     │ │ │
│ │ └─────────────────────┘ │ │
│ └─────────────────────────┘ │
│                             │
│ [Assign All] [Save & Close] │
└─────────────────────────────┘
```

**Tap "+ Add volunteer" opens bottom sheet:**
```
┌─────────────────────────────┐
│ Select Volunteer            │
├─────────────────────────────┤
│ 🔍 Search team members...   │
│                             │
│ ✓ Available                 │
│ ┌─────────────────────────┐ │
│ │ 👤 John Smith           │ │
│ │ 👤 Sarah Johnson        │ │
│ │ 👤 Mike Chen            │ │
│ └─────────────────────────┘ │
│                             │
│ ⚠️ Unavailable              │
│ ┌─────────────────────────┐ │
│ │ 👤 Emma Davis (Away)    │ │
│ └─────────────────────────┘ │
│                             │
│ 📅 Already Assigned         │
│ ┌─────────────────────────┐ │
│ │ 👤 Tom Wilson           │ │
│ │    (Worship Team)       │ │
│ └─────────────────────────┘ │
│                             │
└─────────────────────────────┘
```

**Design Decisions:**
- **Grouped by availability:** Easy to see who can serve
- **Visual indicators:** Icons and colors show status
- **Conflict prevention:** Show if already assigned elsewhere
- **Search:** Quick filter for large teams
- **Batch actions:** "Assign All" for bulk assignment (future feature)

---

## Mobile Optimizations

### Gestures
- **Swipe left/right:** Navigate between dates in assignment view
- **Pull to refresh:** Update availability status
- **Long press:** Quick actions (edit, delete)

### Touch Targets
- **Minimum 44x44pt:** All interactive elements
- **Spacing:** 8pt minimum between tappable areas
- **Thumb zone:** Primary actions in bottom 1/3 of screen

### Performance
- **Lazy loading:** Load dates as user scrolls
- **Optimistic UI:** Show changes immediately, sync in background
- **Offline support:** Cache roster data, sync when online

---

## Accessibility

### Screen Reader Support
- Clear labels for all form fields
- Announce validation errors
- Describe icon meanings

### Visual
- **Contrast ratio:** 4.5:1 minimum for text
- **Font size:** Minimum 16px for body text
- **Color independence:** Don't rely solely on color for meaning

### Motor
- **Large touch targets:** 44x44pt minimum
- **Forgiving gestures:** Wide swipe zones
- **Alternative inputs:** Voice input for text fields

---

## Error Handling

### Validation Errors
```
┌─────────────────────────────┐
│ Roster Name *               │
│ ┌─────────────────────────┐ │
│ │ Su                      │ │
│ └─────────────────────────┘ │
│ ⚠️ Name must be at least   │
│    3 characters             │
└─────────────────────────────┘
```

### Network Errors
```
┌─────────────────────────────┐
│     ⚠️ Connection Lost      │
│                             │
│ Couldn't create roster.     │
│ Check your connection and   │
│ try again.                  │
│                             │
│ [Retry]    [Save as Draft]  │
└─────────────────────────────┘
```

### Conflicts
```
┌─────────────────────────────┐
│ ⚠️ Assignment Conflict      │
│                             │
│ John Smith is already       │
│ assigned to Worship Team    │
│ on Jan 21, 2026             │
│                             │
│ [Choose Someone Else]       │
│ [Assign Anyway]             │
└─────────────────────────────┘
```

---

## Future Enhancements

### Smart Suggestions
- **AI-powered:** Suggest volunteers based on past assignments
- **Load balancing:** Highlight people who haven't served recently
- **Availability prediction:** Learn patterns of when people are available

### Bulk Operations
- **Copy from previous:** Duplicate last month's assignments
- **Template rosters:** Save common patterns
- **Batch notifications:** Send reminders to all assigned volunteers

### Analytics
- **Participation tracking:** See who serves most/least
- **Coverage gaps:** Identify dates needing volunteers
- **Team health:** Monitor burnout risk

---

## Technical Notes

### API Endpoints Used
- `POST /api/rosters` - Create roster
- `GET /api/teams/{team_id}/members` - Get team members
- `POST /api/rosters/assignments` - Create assignment
- `GET /api/availability/conflicts` - Check conflicts

### State Management
- Form state: Local component state
- Roster data: Provider pattern
- Optimistic updates: Update UI before API confirmation

### Performance Targets
- **Time to interactive:** < 2 seconds
- **Form submission:** < 500ms perceived
- **Scroll performance:** 60 FPS
- **Bundle size:** < 2MB for roster feature
