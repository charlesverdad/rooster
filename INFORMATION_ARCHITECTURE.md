# Rooster App - Information Architecture & Navigation Design

**Version:** 1.0  
**Last Updated:** January 2026  
**Platform:** Mobile-first (iOS/Android), Web-compatible  
**Design Philosophy:** Progressive disclosure, role-based navigation, mobile-first

---

## Table of Contents
1. [Navigation Structure](#navigation-structure)
2. [Page Inventory](#page-inventory)
3. [User Journeys by Role](#user-journeys-by-role)
4. [Navigation Patterns](#navigation-patterns)
5. [Design System](#design-system)

---

## Navigation Structure

### Primary Navigation (Bottom Tab Bar)

The app uses a **bottom navigation bar** for primary navigation - the most thumb-friendly pattern for mobile.

```
┌─────────────────────────────────────┐
│                                     │
│         [Page Content]              │
│                                     │
├─────────────────────────────────────┤
│ [Home] [Assignments] [Teams] [More] │
└─────────────────────────────────────┘
```

**Tabs (Role-Adaptive):**

**For Team Members:**
- 🏠 **Home** - Dashboard with upcoming assignments
- 📋 **Assignments** - All assignments (pending, accepted, declined)
- 👥 **Teams** - Teams they belong to
- ⋯ **More** - Profile, settings, notifications

**For Team Leads:**
- 🏠 **Home** - Team lead dashboard with alerts
- 📋 **Assignments** - Personal + team assignments
- 👥 **Teams** - Teams they lead (enhanced view)
- ⋯ **More** - Profile, settings, notifications, analytics

**For Admins:**
- 🏠 **Home** - Organization overview
- 📋 **Rosters** - All rosters across teams
- 👥 **Teams** - All teams (management view)
- ⋯ **More** - Settings, analytics, members

**Design Rationale:**
- **Bottom placement:** Thumb-friendly on mobile (80% of users are right-handed)
- **4 tabs maximum:** Prevents cognitive overload
- **Icons + labels:** Clear meaning, accessible
- **Role-adaptive:** Same structure, different content based on permissions

---

## Page Inventory

### 1. Authentication & Onboarding

#### 1.1 Login Screen
**Route:** `/login`  
**Access:** Public  
**Purpose:** User authentication

**Layout:**
```
┌─────────────────────────────┐
│                             │
│         🏛️                  │
│       Rooster               │
│  Church Volunteer Rostering │
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
│  [Forgot Password?]         │
│                             │
└─────────────────────────────┘
```

**Links to:**
- Register Screen (1.2)
- Forgot Password (1.3)
- Home Dashboard (2.1) - on success

**Reference:** See [PRD.md](../PRD.md#f1-authentication--onboarding)

---

#### 1.2 Register Screen
**Route:** `/register`  
**Access:** Public  
**Purpose:** New user registration

**Layout:**
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
│  Confirm Password           │
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

**Links to:**
- Login Screen (1.1)
- Onboarding Flow (1.4) - on success

---

#### 1.3 Forgot Password
**Route:** `/forgot-password`  
**Access:** Public  
**Purpose:** Password reset

**Flow:**
1. Enter email → Send reset link
2. Check email → Click link
3. Enter new password → Confirm
4. Redirect to login

---

#### 1.4 Onboarding (First-time users)
**Route:** `/onboarding`  
**Access:** Authenticated, first login  
**Purpose:** Guide new users

**Screens:**
1. **Welcome** - "Welcome to Rooster!"
2. **Join Organization** - Enter invite code or browse
3. **Join Teams** - Select teams to join
4. **Notification Preferences** - Set up alerts
5. **Complete** - "You're all set!"

**Links to:** Home Dashboard (2.1)

---

### 2. Home & Dashboard

#### 2.1 Home Dashboard (Member View)
**Route:** `/home`  
**Tab:** Home (🏠)  
**Access:** Team Member  
**Purpose:** Quick overview of upcoming assignments

**Layout:**
```
┌─────────────────────────────┐
│ Rooster              🔔 3   │
├─────────────────────────────┤
│                             │
│ Welcome back, John! 👋      │
│                             │
│ Your Assignments            │
│                             │
│ ┌─────────────────────────┐ │
│ │ 🔴 PENDING RESPONSE     │ │
│ │ Sunday Service - Media  │ │
│ │ Sun, Jan 21 • 9:00 AM   │ │
│ │ [Decline]    [Accept]   │ │
│ └─────────────────────────┘ │
│                             │
│ ┌─────────────────────────┐ │
│ │ ✅ ACCEPTED             │ │
│ │ Sunday Service - Media  │ │
│ │ Sun, Jan 28 • 9:00 AM   │ │
│ └─────────────────────────┘ │
│                             │
│ [View All Assignments]      │
│                             │
├─────────────────────────────┤
│ [Home] [Assignments] [⋯]    │
└─────────────────────────────┘
```

**Components:**
- Greeting with user name
- Pending assignments (with actions)
- Upcoming accepted assignments
- Quick action: View all

**Links to:**
- Assignment Detail (3.2) - tap card
- All Assignments (3.1) - "View All"
- Notifications (6.1) - bell icon

**Reference:** See [01_viewing_and_responding_to_assignments.md](./user_flows/01_viewing_and_responding_to_assignments.md#screen-1-home-dashboard)

---

#### 2.2 Home Dashboard (Team Lead View)
**Route:** `/home`  
**Tab:** Home (🏠)  
**Access:** Team Lead  
**Purpose:** Team management overview

**Layout:**
```
┌─────────────────────────────┐
│ Rooster              🔔 5   │
├─────────────────────────────┤
│ Welcome back, Mike! 👋      │
│ Team Lead                   │
│                             │
│ ⚠️ Needs Attention (3)      │
│ ┌─────────────────────────┐ │
│ │ 🔴 Media Team           │ │
│ │ 2 unfilled slots        │ │
│ │ [Assign Now]            │ │
│ └─────────────────────────┘ │
│                             │
│ Your Teams                  │
│ ┌─────────────────────────┐ │
│ │ 📹 Media Team           │ │
│ │ Next: Sun, Jan 21       │ │
│ │ ✅ 4/4 filled           │ │
│ └─────────────────────────┘ │
│                             │
│ [+ Create Roster]           │
│                             │
├─────────────────────────────┤
│ [Home] [Assignments] [⋯]    │
└─────────────────────────────┘
```

**Components:**
- Alerts section (unfilled slots, conflicts)
- Team health cards
- Quick actions

**Links to:**
- Team Detail (4.2) - tap team card
- Create Roster (5.1) - "+ Create Roster"
- Quick Assign (5.3) - "Assign Now"

**Reference:** See [02_team_lead_dashboard.md](./user_flows/02_team_lead_dashboard.md#screen-1-team-lead-home-dashboard)

---

#### 2.3 Home Dashboard (Admin View)
**Route:** `/home`  
**Tab:** Home (🏠)  
**Access:** Admin  
**Purpose:** Organization-wide overview

**Layout:**
```
┌─────────────────────────────┐
│ Grace Community Church      │
├─────────────────────────────┤
│                             │
│ Organization Overview       │
│                             │
│ ┌─────────────────────────┐ │
│ │ 📊 This Week            │ │
│ │ 12 rosters active       │ │
│ │ 45 assignments          │ │
│ │ 92% filled              │ │
│ └─────────────────────────┘ │
│                             │
│ ⚠️ Needs Attention          │
│ • 3 unfilled slots          │
│ • 2 conflicts               │
│ • 1 inactive team           │
│                             │
│ Teams (8)                   │
│ ┌─────────────────────────┐ │
│ │ 📹 Media Team       ✅  │ │
│ │ 🎵 Worship Team     ⚠️  │ │
│ │ 🧹 Cleaning Team    ✅  │ │
│ └─────────────────────────┘ │
│                             │
│ [View All Teams]            │
│ [+ Create Team]             │
│                             │
└─────────────────────────────┘
```

**Links to:**
- All Teams (4.3) - "View All Teams"
- Create Team (4.4) - "+ Create Team"
- Analytics (7.1) - stats section

---

### 3. Assignments

#### 3.1 All Assignments (List View)
**Route:** `/assignments`  
**Tab:** Assignments (📋)  
**Access:** All users  
**Purpose:** View all assignments with filtering

**Layout:**
```
┌─────────────────────────────┐
│ Assignments              🔍 │
├─────────────────────────────┤
│ [Pending] [Accepted] [All]  │
│                             │
│ ┌─────────────────────────┐ │
│ │ 🔴 PENDING              │ │
│ │ Sunday Service - Media  │ │
│ │ Sun, Jan 21 • 9:00 AM   │ │
│ │ [Decline]    [Accept]   │ │
│ └─────────────────────────┘ │
│                             │
│ ┌─────────────────────────┐ │
│ │ ✅ ACCEPTED             │ │
│ │ Sunday Service - Media  │ │
│ │ Sun, Jan 28 • 9:00 AM   │ │
│ └─────────────────────────┘ │
│                             │
│ ┌─────────────────────────┐ │
│ │ ✅ ACCEPTED             │ │
│ │ Prayer Night - Worship  │ │
│ │ Tue, Jan 23 • 7:00 PM   │ │
│ └─────────────────────────┘ │
│                             │
├─────────────────────────────┤
│ [Home] [Assignments] [⋯]    │
└─────────────────────────────┘
```

**Features:**
- Filter tabs (Pending, Accepted, Declined, All)
- Search icon (filters by roster name, team)
- Grouped by status
- Pull to refresh

**Links to:**
- Assignment Detail (3.2) - tap card
- Search/Filter (3.3) - search icon

---

#### 3.2 Assignment Detail
**Route:** `/assignments/:id`  
**Access:** All users  
**Purpose:** Full assignment information

**Layout:** See [01_viewing_and_responding_to_assignments.md](./user_flows/01_viewing_and_responding_to_assignments.md#screen-2-assignment-detail-expanded)

**Components:**
- Date, time, location
- Role description
- Co-volunteers
- Team lead contact
- Accept/Decline buttons
- Request swap option (if accepted)

**Links to:**
- Request Swap (3.4) - "Request Swap"
- Contact Team Lead - phone/email
- Back to Assignments (3.1)

---

#### 3.3 Search & Filter
**Route:** `/assignments/search`  
**Access:** All users  
**Purpose:** Find specific assignments

**Filters:**
- Date range
- Team
- Status
- Roster name

---

#### 3.4 Request Swap
**Route:** `/assignments/:id/swap`  
**Access:** Member (for accepted assignments)  
**Purpose:** Request to swap with another team member

**Flow:**
1. Select team member to swap with
2. Add optional message
3. Send request
4. Other member receives notification
5. They accept/decline

---

### 4. Teams

#### 4.1 My Teams (Member View)
**Route:** `/teams`  
**Tab:** Teams (👥)  
**Access:** Team Member  
**Purpose:** View teams user belongs to

**Layout:**
```
┌─────────────────────────────┐
│ My Teams                 🔍 │
├─────────────────────────────┤
│                             │
│ ┌─────────────────────────┐ │
│ │ 📹 Media Team           │ │
│ │ 12 members              │ │
│ │ Next: Sun, Jan 21       │ │
│ │ Your role: Member       │ │
│ └─────────────────────────┘ │
│                             │
│ ┌─────────────────────────┐ │
│ │ 🎵 Worship Team         │ │
│ │ 8 members               │ │
│ │ Next: Sun, Jan 21       │ │
│ │ Your role: Member       │ │
│ └─────────────────────────┘ │
│                             │
│ [Browse All Teams]          │
│                             │
├─────────────────────────────┤
│ [Home] [Assignments] [⋯]    │
└─────────────────────────────┘
```

**Links to:**
- Team Detail (4.2) - tap team card
- Browse Teams (4.5) - "Browse All Teams"

---

#### 4.2 Team Detail
**Route:** `/teams/:id`  
**Access:** Team members  
**Purpose:** Team information and roster schedule

**Layout (Member View):**
```
┌─────────────────────────────┐
│ ← Media Team            ⚙️   │
├─────────────────────────────┤
│                             │
│ 📹 Media Team               │
│ 12 members • 4 rosters      │
│                             │
│ [Members] [Rosters] [About] │
│                             │
│ Upcoming Rosters            │
│ ┌─────────────────────────┐ │
│ │ Sunday Service          │ │
│ │ Every Sunday • 9:00 AM  │ │
│ │ Next: Jan 21            │ │
│ └─────────────────────────┘ │
│                             │
│ ┌─────────────────────────┐ │
│ │ Prayer Night            │ │
│ │ 2nd Tuesday • 7:00 PM   │ │
│ │ Next: Jan 23            │ │
│ └─────────────────────────┘ │
│                             │
│ Team Members (12)           │
│ ┌─────────────────────────┐ │
│ │ 👤 Mike Chen (Lead)     │ │
│ │ 👤 John Smith           │ │
│ │ 👤 Sarah Johnson        │ │
│ │ [View All]              │ │
│ └─────────────────────────┘ │
│                             │
└─────────────────────────────┘
```

**Tabs:**
- **Members** - Team member list
- **Rosters** - All rosters for this team
- **About** - Team description, team lead

**Links to:**
- Roster Detail (5.4) - tap roster card
- Member Profile (4.6) - tap member
- Team Settings (4.7) - gear icon (if lead)

**Reference:** See [02_team_lead_dashboard.md](./user_flows/02_team_lead_dashboard.md#screen-2-team-detail-view)

---

#### 4.3 All Teams (Admin View)
**Route:** `/teams`  
**Tab:** Teams (👥)  
**Access:** Admin  
**Purpose:** Manage all teams in organization

**Layout:**
```
┌─────────────────────────────┐
│ All Teams                🔍 │
├─────────────────────────────┤
│ [+ Create Team]             │
│                             │
│ Active Teams (8)            │
│ ┌─────────────────────────┐ │
│ │ 📹 Media Team       ✅  │ │
│ │ 12 members • 4 rosters  │ │
│ │ Lead: Mike Chen         │ │
│ └─────────────────────────┘ │
│                             │
│ ┌─────────────────────────┐ │
│ │ 🎵 Worship Team     ⚠️  │ │
│ │ 8 members • 2 rosters   │ │
│ │ Lead: Sarah Johnson     │ │
│ │ 2 unfilled slots        │ │
│ └─────────────────────────┘ │
│                             │
│ Inactive Teams (1)          │
│ ┌─────────────────────────┐ │
│ │ 🧹 Cleaning Team        │ │
│ │ No activity 3 months    │ │
│ └─────────────────────────┘ │
│                             │
└─────────────────────────────┘
```

**Links to:**
- Create Team (4.4) - "+ Create Team"
- Team Detail (4.2) - tap team card

---

#### 4.4 Create Team
**Route:** `/teams/create`  
**Access:** Admin  
**Purpose:** Create new team

**Fields:**
- Team name
- Description
- Team lead (select member)
- Initial members (optional)

---

#### 4.5 Browse Teams
**Route:** `/teams/browse`  
**Access:** All members  
**Purpose:** Discover and join teams

**Layout:**
```
┌─────────────────────────────┐
│ ← Browse Teams          🔍  │
├─────────────────────────────┤
│                             │
│ Available Teams             │
│                             │
│ ┌─────────────────────────┐ │
│ │ 🧹 Cleaning Team        │ │
│ │ Help keep our church    │ │
│ │ clean and welcoming     │ │
│ │ 5 members               │ │
│ │ [Request to Join]       │ │
│ └─────────────────────────┘ │
│                             │
│ ┌─────────────────────────┐ │
│ │ 🚗 Transport Team       │ │
│ │ Provide rides for       │ │
│ │ members who need help   │ │
│ │ 3 members               │ │
│ │ [Request to Join]       │ │
│ └─────────────────────────┘ │
│                             │
└─────────────────────────────┘
```

---

#### 4.6 Member Profile
**Route:** `/members/:id`  
**Access:** Team members (same team)  
**Purpose:** View member information

**Layout:**
```
┌─────────────────────────────┐
│ ← John Smith                │
├─────────────────────────────┤
│                             │
│       👤                    │
│    John Smith               │
│    Member                   │
│                             │
│ 📧 john@email.com           │
│ 📞 (555) 123-4567           │
│                             │
│ Teams                       │
│ • Media Team                │
│ • Worship Team              │
│                             │
│ Service History             │
│ • 24 total assignments      │
│ • 8 this year               │
│ • 95% response rate         │
│                             │
│ [Message]                   │
│                             │
└─────────────────────────────┘
```

---

#### 4.7 Team Settings
**Route:** `/teams/:id/settings`  
**Access:** Team Lead, Admin  
**Purpose:** Manage team configuration

**Sections:**
- Team information (edit name, description)
- Team lead (change)
- Members (add, remove)
- Notifications (configure)
- Danger zone (archive team)

---

### 5. Rosters & Scheduling

#### 5.1 Create Roster
**Route:** `/rosters/create`  
**Access:** Team Lead, Admin  
**Purpose:** Create new recurring roster

**Reference:** See [00_creating_a_schedule.md](./user_flows/00_creating_a_schedule.md) for complete flow

**Screens:**
1. Roster Basics (name, team, description)
2. Recurrence Pattern (weekly, monthly, custom)
3. Slot Configuration (volunteers needed, assignment method)
4. Review & Confirm
5. Success & Next Steps

**Links to:**
- Assign Volunteers (5.3) - from success screen
- Roster Detail (5.4) - "View Roster"

---

#### 5.2 Roster List
**Route:** `/rosters`  
**Access:** Team Lead (own teams), Admin (all)  
**Purpose:** View all rosters

**Layout:**
```
┌─────────────────────────────┐
│ Rosters                  🔍 │
├─────────────────────────────┤
│ [+ Create Roster]           │
│                             │
│ Media Team                  │
│ ┌─────────────────────────┐ │
│ │ Sunday Service          │ │
│ │ Every Sunday • 9:00 AM  │ │
│ │ 2 volunteers needed     │ │
│ │ Next: Jan 21 ✅         │ │
│ └─────────────────────────┘ │
│                             │
│ ┌─────────────────────────┐ │
│ │ Prayer Night            │ │
│ │ 2nd Tuesday • 7:00 PM   │ │
│ │ 1 volunteer needed      │ │
│ │ Next: Jan 23 ⚠️         │ │
│ └─────────────────────────┘ │
│                             │
│ Worship Team                │
│ ┌─────────────────────────┐ │
│ │ Sunday Service          │ │
│ │ Every Sunday • 9:00 AM  │ │
│ │ 3 volunteers needed     │ │
│ │ Next: Jan 21 ⚠️         │ │
│ └─────────────────────────┘ │
│                             │
└─────────────────────────────┘
```

**Links to:**
- Create Roster (5.1) - "+ Create Roster"
- Roster Detail (5.4) - tap roster card

---

#### 5.3 Assign Volunteers (Quick Assign)
**Route:** `/rosters/:id/assign`  
**Access:** Team Lead, Admin  
**Purpose:** Assign volunteers to specific dates

**Reference:** See [00_creating_a_schedule.md](./user_flows/00_creating_a_schedule.md#screen-6-assign-volunteers)

**Features:**
- List of upcoming dates
- "+ Add volunteer" for each slot
- Smart suggestions (AI-powered)
- Availability indicators
- Conflict warnings

---

#### 5.4 Roster Detail
**Route:** `/rosters/:id`  
**Access:** Team Lead (own), Admin (all), Members (view only)  
**Purpose:** View roster schedule and assignments

**Layout:**
```
┌─────────────────────────────┐
│ ← Sunday Service - Media ⚙️ │
├─────────────────────────────┤
│                             │
│ 📅 Every Sunday             │
│ ⏰ 9:00 AM - 11:00 AM       │
│ 👥 2 volunteers needed      │
│                             │
│ [Calendar] [List] [Stats]   │
│                             │
│ Upcoming Assignments        │
│ ┌─────────────────────────┐ │
│ │ Sun, Jan 21, 2026       │ │
│ │ ✅ 2/2 filled           │ │
│ │ • John Smith ✅         │ │
│ │ • Sarah Johnson ✅      │ │
│ └─────────────────────────┘ │
│                             │
│ ┌─────────────────────────┐ │
│ │ Sun, Jan 28, 2026       │ │
│ │ ⚠️ 1/2 filled           │ │
│ │ • Mike Chen ✅          │ │
│ │ • [+ Assign]            │ │
│ └─────────────────────────┘ │
│                             │
│ [Assign Volunteers]         │
│                             │
└─────────────────────────────┘
```

**Tabs:**
- **Calendar** - Monthly calendar view
- **List** - Chronological list (default)
- **Stats** - Coverage rate, response rate

**Links to:**
- Assign Volunteers (5.3) - "+ Assign" or button
- Roster Settings (5.5) - gear icon
- Assignment Detail (3.2) - tap assignment

---

#### 5.5 Roster Settings
**Route:** `/rosters/:id/settings`  
**Access:** Team Lead, Admin  
**Purpose:** Edit roster configuration

**Sections:**
- Basic info (name, description)
- Schedule (recurrence pattern)
- Volunteers needed
- Assignment method
- Notifications
- Danger zone (delete roster)

---

### 6. Notifications & Settings

#### 6.1 Notifications
**Route:** `/notifications`  
**Access:** All users  
**Purpose:** View all in-app notifications

**Layout:**
```
┌─────────────────────────────┐
│ ← Notifications              │
│ [Mark All Read]             │
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
│ │ ⚠️ Conflict Detected    │ │
│ │ You're assigned to 2    │ │
│ │ rosters on Jan 21       │ │
│ │ 5 hours ago             │ │
│ └─────────────────────────┘ │
│                             │
│ ┌─────────────────────────┐ │
│ │ ✅ Swap Approved        │ │
│ │ Sarah accepted your     │ │
│ │ swap request            │ │
│ │ Yesterday               │ │
│ └─────────────────────────┘ │
│                             │
└─────────────────────────────┘
```

**Features:**
- Unread indicator (bold, elevated)
- Swipe to delete
- Tap to mark as read
- Group by date

**Links to:**
- Related assignment/roster - tap notification

---

#### 6.2 Profile & Settings
**Route:** `/settings`  
**Tab:** More (⋯)  
**Access:** All users  
**Purpose:** User profile and app settings

**Layout:**
```
┌─────────────────────────────┐
│ Settings                    │
├─────────────────────────────┤
│                             │
│       👤                    │
│    John Smith               │
│    john@email.com           │
│                             │
│ [Edit Profile]              │
│                             │
│ Account                     │
│ • Notification Preferences  │
│ • Privacy                   │
│ • Change Password           │
│                             │
│ Teams                       │
│ • My Teams                  │
│ • Browse Teams              │
│                             │
│ About                       │
│ • Help & Support            │
│ • Terms of Service          │
│ • Privacy Policy            │
│ • App Version 1.0.0         │
│                             │
│ [Logout]                    │
│                             │
└─────────────────────────────┘
```

**Links to:**
- Edit Profile (6.3)
- Notification Preferences (6.4)
- My Teams (4.1)
- Browse Teams (4.5)

---

#### 6.3 Edit Profile
**Route:** `/settings/profile`  
**Access:** All users  
**Purpose:** Update user information

**Fields:**
- Profile photo
- Full name
- Email
- Phone number
- Bio (optional)

---

#### 6.4 Notification Preferences
**Route:** `/settings/notifications`  
**Access:** All users  
**Purpose:** Configure notification settings

**Options:**
- **Push Notifications**
  - New assignments
  - Reminders (7 days, 1 day, day-of)
  - Swap requests
  - Conflicts
- **Email Notifications**
  - Weekly digest
  - Assignment confirmations
- **Quiet Hours**
  - Start time
  - End time

---

### 7. Analytics & Reports (Team Lead/Admin)

#### 7.1 Team Analytics
**Route:** `/teams/:id/analytics`  
**Access:** Team Lead, Admin  
**Purpose:** Team performance insights

**Metrics:**
- Coverage rate (% of slots filled)
- Response rate (% of members responding)
- Average response time
- Most/least active members
- Trends over time

**Reference:** See [02_team_lead_dashboard.md](./user_flows/02_team_lead_dashboard.md#screen-6-team-analytics-optional)

---

#### 7.2 Organization Analytics
**Route:** `/analytics`  
**Access:** Admin  
**Purpose:** Organization-wide insights

**Metrics:**
- Total assignments
- Coverage across all teams
- Member engagement
- Team health scores
- Trends and forecasts

---

## User Journeys by Role

### Team Member Journey

**Primary Path:**
```
Login (1.1)
  ↓
Home Dashboard (2.1)
  ↓
[See pending assignment]
  ↓
Tap "Accept"
  ↓
Success! (stays on Home)
```

**Secondary Paths:**
- View all assignments: Home → Assignments tab (3.1)
- View team: Home → Teams tab (4.1) → Team Detail (4.2)
- Check notifications: Home → Bell icon → Notifications (6.1)
- Update profile: Home → More tab → Settings (6.2)

---

### Team Lead Journey

**Primary Path:**
```
Login (1.1)
  ↓
Home Dashboard (2.2)
  ↓
[See unfilled slot alert]
  ↓
Tap "Assign Now"
  ↓
Quick Assign (5.3)
  ↓
Select volunteer
  ↓
Success! (returns to Home)
```

**Secondary Paths:**
- Create roster: Home → "+ Create Roster" → Create flow (5.1)
- Manage team: Home → Tap team card → Team Detail (4.2)
- View analytics: Team Detail → Stats tab → Analytics (7.1)
- Resolve conflict: Home → Conflict alert → Resolution flow

---

### Admin Journey

**Primary Path:**
```
Login (1.1)
  ↓
Home Dashboard (2.3)
  ↓
Organization overview
  ↓
[See team needing attention]
  ↓
Tap team
  ↓
Team Detail (4.2)
  ↓
Take action
```

**Secondary Paths:**
- Create team: Home → "+ Create Team" → Create Team (4.4)
- View all teams: Home → "View All Teams" → All Teams (4.3)
- Organization analytics: Home → Stats → Analytics (7.2)
- Manage members: Teams → Team Detail → Members tab

---

## Navigation Patterns

### 1. Bottom Navigation (Primary)
**When to use:** Main app sections  
**Pattern:** Persistent bottom bar with 4 tabs  
**Behavior:** Tapping active tab scrolls to top

### 2. Stack Navigation (Secondary)
**When to use:** Drilling into details  
**Pattern:** Push new screen onto stack  
**Behavior:** Back button returns to previous screen

### 3. Modal/Bottom Sheet (Tertiary)
**When to use:** Quick actions, forms  
**Pattern:** Slides up from bottom  
**Behavior:** Swipe down or tap outside to dismiss

### 4. Tabs (Content Organization)
**When to use:** Multiple views of same entity  
**Pattern:** Horizontal tabs below header  
**Example:** Team Detail (Members, Rosters, About)

---

## Design System

### Color Palette

**Primary Colors:**
- **Primary:** Deep Purple (#673AB7) - Main actions, active states
- **Secondary:** Teal (#009688) - Accents, secondary actions

**Status Colors:**
- **Success:** Green (#4CAF50) - Accepted, filled, completed
- **Warning:** Orange (#FF9800) - Pending, attention needed
- **Error:** Red (#F44336) - Declined, unfilled, conflicts
- **Info:** Blue (#2196F3) - Information, neutral

**Neutral Colors:**
- **Background:** White (#FFFFFF)
- **Surface:** Light Gray (#F5F5F5)
- **Text Primary:** Dark Gray (#212121)
- **Text Secondary:** Medium Gray (#757575)

---

### Typography

**Font Family:** Inter (sans-serif)

**Scale:**
- **H1:** 28px, Bold - Page titles
- **H2:** 24px, Bold - Section headers
- **H3:** 20px, Semibold - Card titles
- **Body:** 16px, Regular - Main content
- **Caption:** 14px, Regular - Secondary info
- **Small:** 12px, Regular - Timestamps, labels

---

### Spacing

**Base unit:** 8px

**Scale:**
- **xs:** 4px - Tight spacing
- **sm:** 8px - Default spacing
- **md:** 16px - Section spacing
- **lg:** 24px - Large gaps
- **xl:** 32px - Page margins

---

### Components

**Buttons:**
- **Primary:** Filled, primary color, white text
- **Secondary:** Outlined, primary color
- **Text:** No background, primary color text

**Cards:**
- White background
- 8px border radius
- 2px elevation (shadow)
- 16px padding

**Input Fields:**
- Outlined style
- 8px border radius
- 16px padding
- Label above field

---

## Responsive Breakpoints

**Mobile:** < 768px (default)  
**Tablet:** 768px - 1024px  
**Desktop:** > 1024px

**Adaptations:**
- **Mobile:** Bottom nav, single column
- **Tablet:** Side nav option, two columns
- **Desktop:** Side nav, multi-column layouts

---

## Accessibility

### WCAG 2.1 AA Compliance

**Visual:**
- Contrast ratio 4.5:1 minimum for text
- Touch targets 44x44pt minimum
- Focus indicators on all interactive elements

**Screen Reader:**
- Semantic HTML
- ARIA labels where needed
- Logical heading hierarchy

**Keyboard:**
- All functions accessible via keyboard
- Logical tab order
- Skip navigation links

---

## Performance Targets

- **Time to Interactive:** < 2 seconds
- **First Contentful Paint:** < 1 second
- **Smooth scrolling:** 60 FPS
- **Offline support:** Core features work offline

---

## Future Considerations

### Phase 2 Features
- Calendar integration (Google, Apple)
- Multi-organization switching
- Advanced analytics
- Team chat
- Swap marketplace

### Scalability
- Support for 1000+ members per organization
- 100+ teams
- 10,000+ assignments per year

---

## Conclusion

This information architecture prioritizes:
1. **Mobile-first design** - Thumb-friendly navigation
2. **Role-based experience** - Adaptive UI based on permissions
3. **Progressive disclosure** - Show what's needed, when needed
4. **Clear hierarchy** - Logical grouping and navigation
5. **Accessibility** - Inclusive design for all users

All pages are designed to work seamlessly together, creating a cohesive experience that makes volunteer rostering simple and efficient.
