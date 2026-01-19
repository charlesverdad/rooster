# User Flow: Team Lead Dashboard & Management

**User Role:** Team Lead  
**Goal:** Monitor team health, manage assignments, and handle conflicts  
**Platform:** Mobile-first (iOS/Android), Web-compatible  
**Estimated Time:** Ongoing (daily check-in: 2-3 minutes)

---

## Overview

Team leads need a command center to oversee their team's roster, identify gaps, resolve conflicts, and ensure smooth operations. This dashboard should surface the most important information first and make common actions quick.

---

## User Journey

### Entry Points
1. **Primary:** App launch → Team Lead sees enhanced home view
2. **Notification:** "3 pending responses for Sunday" → Opens to team dashboard
3. **Quick action:** From any screen → Tap team name in header

### Success Criteria
- Lead sees team health at a glance
- Can identify and fix problems quickly
- Assignments are filled before deadlines
- Team members are engaged and responsive

---

## Screen-by-Screen Flow

### Screen 1: Team Lead Home Dashboard
**Purpose:** Overview of all teams and urgent items

**UI Layout (Mobile):**
```
┌─────────────────────────────┐
│ Rooster              🔔 5    │
├─────────────────────────────┤
│                             │
│ Welcome back, Mike! 👋      │
│ Team Lead                   │
│                             │
│ ⚠️ Needs Attention (3)      │
│ ┌─────────────────────────┐ │
│ │ 🔴 Media Team           │ │
│ │ 2 unfilled slots        │ │
│ │ Sunday Service • Jan 21 │ │
│ │ [Assign Now]            │ │
│ └─────────────────────────┘ │
│                             │
│ ┌─────────────────────────┐ │
│ │ ⚠️ Worship Team         │ │
│ │ 1 conflict detected     │ │
│ │ John Smith • Jan 21     │ │
│ │ [Resolve]               │ │
│ └─────────────────────────┘ │
│                             │
│ Your Teams                  │
│ ┌─────────────────────────┐ │
│ │ 📹 Media Team           │ │
│ │ 4 rosters • 12 members  │ │
│ │ Next: Sun, Jan 21       │ │
│ │ ✅ 4/4 filled           │ │
│ └─────────────────────────┘ │
│                             │
│ ┌─────────────────────────┐ │
│ │ 🎵 Worship Team         │ │
│ │ 2 rosters • 8 members   │ │
│ │ Next: Sun, Jan 21       │ │
│ │ ⚠️ 2/3 filled           │ │
│ └─────────────────────────┘ │
│                             │
│ [+ Create Roster]           │
│                             │
├─────────────────────────────┤
│ [Home] [Teams] [People] [⚙️]│
└─────────────────────────────┘
```

**Design Decisions:**
- **Alerts first:** Problems surface at top
- **Action-oriented:** Every alert has a clear action button
- **Visual status:** Color coding (red = urgent, yellow = warning, green = good)
- **Quick stats:** Key metrics visible without tapping
- **Team cards:** Tap to drill into specific team

---

### Screen 2: Team Detail View
**Purpose:** Deep dive into one team's roster and members

**UI Layout (Mobile):**
```
┌─────────────────────────────┐
│ ← Media Team            ⚙️   │
├─────────────────────────────┤
│                             │
│ 📊 Team Health              │
│ ┌─────────────────────────┐ │
│ │ Response Rate    85% ✅ │ │
│ │ Avg Response     2.3 hrs│ │
│ │ Active Members   12/15  │ │
│ │ Coverage         92%    │ │
│ └─────────────────────────┘ │
│                             │
│ Upcoming Assignments        │
│ ┌─────────────────────────┐ │
│ │ Sun, Jan 21 • 9:00 AM   │ │
│ │ Sunday Service          │ │
│ │ ✅ 2/2 filled           │ │
│ │ • John Smith ✅         │ │
│ │ • Sarah Johnson ✅      │ │
│ └─────────────────────────┘ │
│                             │
│ ┌─────────────────────────┐ │
│ │ Sun, Jan 28 • 9:00 AM   │ │
│ │ Sunday Service          │ │
│ │ ⚠️ 1/2 filled           │ │
│ │ • Mike Chen ✅          │ │
│ │ • [+ Assign]            │ │
│ └─────────────────────────┘ │
│                             │
│ ┌─────────────────────────┐ │
│ │ Sun, Feb 4 • 9:00 AM    │ │
│ │ Sunday Service          │ │
│ │ 🔴 0/2 filled           │ │
│ │ • [+ Assign]            │ │
│ │ • [+ Assign]            │ │
│ └─────────────────────────┘ │
│                             │
│ [View All] [+ Create Roster]│
│                             │
└─────────────────────────────┘
```

**Design Decisions:**
- **Health metrics:** Quick pulse check on team engagement
- **Timeline view:** Chronological list of upcoming assignments
- **Status indicators:** Visual cues for filled/unfilled slots
- **Inline actions:** Assign directly from this view
- **Expandable cards:** Tap to see more details

---

### Screen 3: Quick Assign (Bottom Sheet)
**Purpose:** Rapidly fill an open slot

**Accessed by:** Tapping "[+ Assign]" button

**UI Layout (Bottom Sheet):**
```
┌─────────────────────────────┐
│ Assign Volunteer            │
│ Sunday Service • Jan 28     │
├─────────────────────────────┤
│ 🔍 Search...                │
│                             │
│ 💡 Suggested                │
│ ┌─────────────────────────┐ │
│ │ ⭐ Emma Davis           │ │
│ │ Last served 3 weeks ago │ │
│ │ ✅ Available            │ │
│ └─────────────────────────┘ │
│                             │
│ ┌─────────────────────────┐ │
│ │ ⭐ Tom Wilson           │ │
│ │ Last served 2 weeks ago │ │
│ │ ✅ Available            │ │
│ └─────────────────────────┘ │
│                             │
│ ✅ Available (8)            │
│ ┌─────────────────────────┐ │
│ │ 👤 Lisa Brown           │ │
│ │ 👤 David Lee            │ │
│ │ 👤 Amy Zhang            │ │
│ │ [Show all]              │ │
│ └─────────────────────────┘ │
│                             │
│ ⚠️ Unavailable (2)          │
│ ┌─────────────────────────┐ │
│ │ 👤 John Smith (Away)    │ │
│ │ 👤 Sarah J. (Conflict)  │ │
│ └─────────────────────────┘ │
│                             │
│ 📅 Already Assigned (2)     │
│ ┌─────────────────────────┐ │
│ │ 👤 Mike Chen            │ │
│ │    (This roster)        │ │
│ └─────────────────────────┘ │
│                             │
└─────────────────────────────┘
```

**Design Decisions:**
- **Smart suggestions:** AI-powered based on:
  - Time since last assignment
  - Historical availability
  - Response rate
  - Skill match
- **Grouped by status:** Easy to see who can serve
- **Context clues:** Show why someone is unavailable
- **Search:** Quick filter for large teams
- **One-tap assign:** Tap name to assign immediately

**Interaction:**
- Tap suggested person → Confirms assignment → Sends notification
- Shows success toast: "Emma Davis assigned. Notification sent."

---

### Screen 4: Conflict Resolution
**Purpose:** Handle scheduling conflicts

**Accessed by:** Tapping conflict alert

**UI Layout (Mobile):**
```
┌─────────────────────────────┐
│ ← Resolve Conflict           │
├─────────────────────────────┤
│                             │
│ ⚠️ Scheduling Conflict      │
│                             │
│ John Smith is assigned to:  │
│                             │
│ ┌─────────────────────────┐ │
│ │ 📹 Media Team           │ │
│ │ Sunday Service          │ │
│ │ Sun, Jan 21 • 9:00 AM   │ │
│ │ Status: Accepted ✅     │ │
│ └─────────────────────────┘ │
│                             │
│ AND                         │
│                             │
│ ┌─────────────────────────┐ │
│ │ 🎵 Worship Team         │ │
│ │ Sunday Service          │ │
│ │ Sun, Jan 21 • 9:00 AM   │ │
│ │ Status: Pending ⏳      │ │
│ └─────────────────────────┘ │
│                             │
│ Suggested Actions           │
│                             │
│ ┌─────────────────────────┐ │
│ │ 💬 Contact John         │ │
│ │ Ask which he prefers    │ │
│ └─────────────────────────┘ │
│                             │
│ ┌─────────────────────────┐ │
│ │ 🔄 Reassign Worship     │ │
│ │ Find someone else       │ │
│ └─────────────────────────┘ │
│                             │
│ ┌─────────────────────────┐ │
│ │ ✅ Allow Both           │ │
│ │ If roles are compatible │ │
│ └─────────────────────────┘ │
│                             │
│ [Dismiss]                   │
│                             │
└─────────────────────────────┘
```

**Design Decisions:**
- **Clear visualization:** Show both conflicting assignments
- **Context:** Display status of each assignment
- **Guided resolution:** Suggest best actions
- **Flexibility:** Multiple resolution paths
- **Communication:** Easy contact option

---

### Screen 5: Team Member Directory
**Purpose:** View and manage team members

**UI Layout (Mobile):**
```
┌─────────────────────────────┐
│ ← Media Team Members         │
├─────────────────────────────┤
│ 🔍 Search members...        │
│                             │
│ 12 Active Members           │
│                             │
│ ┌─────────────────────────┐ │
│ │ 👤 John Smith      Lead │ │
│ │ Last served: 2 days ago │ │
│ │ Response rate: 95%      │ │
│ │ ✅ Available            │ │
│ └─────────────────────────┘ │
│                             │
│ ┌─────────────────────────┐ │
│ │ 👤 Sarah Johnson        │ │
│ │ Last served: 1 week ago │ │
│ │ Response rate: 100%     │ │
│ │ ⚠️ Unavailable Jan 28   │ │
│ └─────────────────────────┘ │
│                             │
│ ┌─────────────────────────┐ │
│ │ 👤 Mike Chen            │ │
│ │ Last served: 3 weeks ago│ │
│ │ Response rate: 80%      │ │
│ │ ✅ Available            │ │
│ └─────────────────────────┘ │
│                             │
│ 3 Inactive Members          │
│ ┌─────────────────────────┐ │
│ │ 👤 Tom Wilson           │ │
│ │ Last served: 3 months   │ │
│ │ [Reach Out]             │ │
│ └─────────────────────────┘ │
│                             │
│ [+ Add Member]              │
│                             │
└─────────────────────────────┘
```

**Design Decisions:**
- **Engagement metrics:** See who's active/inactive
- **Availability status:** Current availability at a glance
- **Actionable insights:** Prompt to reach out to inactive members
- **Quick actions:** Tap member to see details/assign

**Tap member card opens:**
```
┌─────────────────────────────┐
│ John Smith                  │
├─────────────────────────────┤
│ 📧 john@email.com           │
│ 📞 (555) 123-4567           │
│                             │
│ Service History             │
│ ┌─────────────────────────┐ │
│ │ Total: 24 assignments   │ │
│ │ This year: 8            │ │
│ │ Response rate: 95%      │ │
│ │ Avg response: 1.2 hrs   │ │
│ └─────────────────────────┘ │
│                             │
│ Upcoming Assignments        │
│ • Sun, Jan 21 ✅            │
│ • Sun, Feb 4 ⏳             │
│                             │
│ Unavailable Dates           │
│ • Feb 11-18 (Vacation)      │
│                             │
│ [Message] [Assign] [Remove] │
│                             │
└─────────────────────────────┘
```

---

## Mobile Optimizations

### Gestures
- **Swipe left on assignment:** Quick assign
- **Swipe right on conflict:** Dismiss
- **Long press member:** Quick actions menu
- **Pull to refresh:** Update all data

### Quick Actions
- **3D Touch/Long press team card:**
  - Assign volunteers
  - View roster
  - Message team
  - Team settings

### Widgets (iOS/Android)
```
┌─────────────────────────────┐
│ Media Team                  │
│ Next: Sun, Jan 21           │
│ ✅ 4/4 filled               │
│                             │
│ Worship Team                │
│ Next: Sun, Jan 21           │
│ ⚠️ 2/3 filled - Tap to fix  │
└─────────────────────────────┘
```

---

## Notifications for Team Leads

### Daily Digest (8 AM)
```
📱 Good morning, Mike!

Media Team:
✅ All assignments filled for next 2 weeks

Worship Team:
⚠️ 2 open slots for Feb 4
🔴 1 conflict on Jan 28

[View Dashboard]
```

### Real-time Alerts
- Member declines assignment → Suggest replacements
- Conflict detected → Show resolution options
- 48 hours before unfilled slot → Urgent notification
- Member hasn't responded in 3 days → Reminder prompt

---

## Analytics Dashboard

### Screen 6: Team Analytics (Optional)
**Purpose:** Long-term insights and trends

**UI Layout (Mobile):**
```
┌─────────────────────────────┐
│ ← Media Team Analytics       │
├─────────────────────────────┤
│                             │
│ Last 3 Months               │
│                             │
│ 📊 Coverage Rate            │
│ ┌─────────────────────────┐ │
│ │     ▁▃▅▇█▇▅▃▁          │ │
│ │     92% average         │ │
│ └─────────────────────────┘ │
│                             │
│ 👥 Most Active              │
│ ┌─────────────────────────┐ │
│ │ 1. Sarah Johnson (12)   │ │
│ │ 2. John Smith (11)      │ │
│ │ 3. Mike Chen (10)       │ │
│ └─────────────────────────┘ │
│                             │
│ ⚠️ At Risk                  │
│ ┌─────────────────────────┐ │
│ │ Tom Wilson              │ │
│ │ No service in 3 months  │ │
│ │ [Reach Out]             │ │
│ └─────────────────────────┘ │
│                             │
│ 📈 Trends                   │
│ • Response time improving   │
│ • Decline rate stable       │
│ • 2 new active members      │
│                             │
└─────────────────────────────┘
```

---

## Best Practices Prompts

### Proactive Coaching
```
┌─────────────────────────────┐
│ 💡 Tip                      │
│                             │
│ You have 3 members who      │
│ haven't served in 6+ weeks. │
│                             │
│ Consider:                   │
│ • Sending a check-in message│
│ • Offering easier roles     │
│ • Asking for feedback       │
│                             │
│ [Message Them] [Dismiss]    │
└─────────────────────────────┘
```

### Load Balancing Alert
```
┌─────────────────────────────┐
│ ⚖️ Balance Check            │
│                             │
│ Sarah has served 4 times    │
│ this month, while 5 members │
│ haven't served at all.      │
│                             │
│ [Auto-Balance] [View Report]│
└─────────────────────────────┘
```

---

## Accessibility

### Screen Reader Optimizations
- Announce urgent items first
- Group related information
- Clear action labels

### Keyboard Navigation
- Tab through assignments
- Enter to expand details
- Space to assign/resolve

---

## Performance Targets

- **Dashboard load:** < 1.5 seconds
- **Assign action:** < 300ms perceived
- **Conflict detection:** Real-time
- **Sync frequency:** Every 5 minutes in background

---

## Future Enhancements

### AI-Powered Features
- **Predictive staffing:** "You'll need 2 more volunteers for Easter"
- **Smart scheduling:** "Avoid assigning John and Sarah together"
- **Burnout detection:** "Mike has served 6 weeks straight"

### Automation
- **Auto-assign:** Based on rules and preferences
- **Auto-reminders:** Escalating notifications for unfilled slots
- **Auto-balance:** Distribute assignments fairly

### Communication
- **Team chat:** Built-in messaging
- **Announcements:** Broadcast to whole team
- **Appreciation:** Send thanks after service
