# Rooster - Pre-Production Bug Report

**Generated**: 2026-01-31
**Testing Method**: Automated browser testing with 7 parallel test flows
**Test User**: charles@church.com (Team Lead)

---

## CRITICAL BUGS (Must Fix Before Launch)

### 1. Flutter Navigation Crash - Red Screen of Death
- **Location**: Multiple routes, especially Settings and navigation between pages
- **Error**: `Assertion failed: route._navigator == navigator is not true` (navigator.dart:3326:12)
- **Also**: `A GlobalKey was used multiple times inside one widget's child list`
- **Impact**: App crashes to red error screen, requires page refresh to recover
- **File**: `routes.dart:397:7`
- **Priority**: P0

### 2. Create Roster Button Not Visible
- **Location**: Team Detail > + Create Roster > New Roster form
- **Issue**: The "Create" button exists in code (`create_roster_screen.dart:389`) but is not visible/accessible in the rendered UI
- **Impact**: **Users cannot create new rosters** - blocking issue
- **Root Cause**: Likely viewport/overflow issue with ListView not showing full content
- **Priority**: P0

### 3. Missing Unavailability UI Screen
- **Location**: Settings > My Availability
- **Issue**: Shows "My Assignments" screen instead of unavailability management
- **Impact**: **Users have no way to mark themselves unavailable** despite backend API existing
- **Backend**: API exists at `/availability` endpoint with POST, GET, DELETE
- **Frontend**: `AvailabilityProvider` exists but `AvailabilityScreen` shows wrong content
- **File**: `/frontend/rooster_app/lib/screens/availability/availability_screen.dart`
- **Priority**: P0

### 4. Second Assignment to Same Roster Fails
- **Location**: Home > Needs Attention > + Assign
- **Issue**: First assignment works, subsequent assignments fail with "Failed to assign volunteer"
- **Impact**: Cannot complete roster assignments when multiple volunteers needed
- **Priority**: P0

---

## HIGH PRIORITY BUGS

### 5. Negative Day Count Display
- **Location**: Home page, Upcoming Assignments section
- **Issue**: Past assignments show "In -5 days" instead of being hidden or properly labeled
- **Expected**: Filter out past assignments OR display as "5 days ago"
- **Priority**: P1

### 6. URL/Content Route Mismatch
- **Location**: Multiple screens
- **Issue**: URL shows one route but content displays different page
- **Examples**:
  - URL shows `/#/settings` but displays "Notifications" content
  - URL shows `/#/availability` but displays "My Assignments" content
- **Priority**: P1

### 7. Unfilled Slots Badge Not Updating
- **Location**: Home page "Needs Attention" section
- **Issue**: The "56 unfilled" badge doesn't update after successful assignments
- **Expected**: Should decrement after each assignment
- **Priority**: P1

---

## MEDIUM PRIORITY BUGS

### 8. Pluralization Error
- **Location**: My Teams page
- **Issue**: Shows "1 members" instead of "1 member"
- **Fix**: Add conditional logic for singular/plural
- **Priority**: P2

### 9. Menu Label Mismatch
- **Location**: Settings screen
- **Issue**: "My Availability" links to "My Assignments" screen
- **Impact**: Misleading navigation
- **Priority**: P2

### 10. Sunday Service Shows Monday Date
- **Location**: My Assignments screen
- **Issue**: "Sunday Service" roster shows "Monday, January 26, 2026"
- **Impact**: Semantic confusion - roster name doesn't match scheduled day
- **Priority**: P2

### 11. Day Selector Ambiguity
- **Location**: Create Roster form
- **Issue**: "T" appears twice for both Tuesday and Thursday
- **Fix**: Use "Tu" and "Th" to differentiate
- **Priority**: P2

---

## UX IMPROVEMENTS NEEDED

### Authentication/Registration
- [ ] Add password confirmation field on registration
- [ ] Display password requirements before submission
- [ ] Add "Already have an account?" link on register page
- [ ] Consider email verification for production

### Settings
- [ ] Add profile editing capability
- [ ] Add password change option
- [ ] Add granular email notification preferences
- [ ] Add back button/close mechanism on Settings page
- [ ] Fix inconsistent navigation (drawer vs full page)

### General UI
- [ ] Clean up test data before launch (rosters named "asdfadf")
- [ ] Improve Flutter web accessibility (inputs not exposed to accessibility tree)
- [ ] Add loading states for async operations
- [ ] Consider pagination for large lists (56 unfilled slots)

---

## TEST RESULTS SUMMARY

| Flow | Status | Notes |
|------|--------|-------|
| Registration | PASS | Works but missing password confirmation |
| Login | PASS | Works correctly |
| Create Team | PASS | Works correctly |
| Add Member | PASS | Placeholder members work |
| Create Roster | BLOCKED | Create button not visible |
| Assign Volunteers | PARTIAL | First assignment works, subsequent fail |
| Accept Assignment | PASS | Works with good UX |
| Decline Assignment | PASS | Works with reason selection |
| Mark Unavailability | BLOCKED | UI screen missing |
| Settings | PARTIAL | Navigation crashes sometimes |
| Logout | PASS | Works, clears session correctly |
| Route Protection | PASS | Guards work after logout |

---

## RECOMMENDED FIX ORDER

1. **Flutter Navigation Crash** - Affects multiple flows, causes app to become unusable
2. **Create Roster Button** - Core functionality blocked
3. **Unavailability UI** - Feature completely missing
4. **Assignment API Bug** - Multiple volunteers can't be assigned
5. **Negative Day Count** - Confusing for all users
6. **Route Mismatches** - Navigation issues
7. **Badge Updates** - Admin UX
8. **Minor UX fixes** - Pluralization, labels, etc.

---

## FILES LIKELY NEEDING CHANGES

- `/frontend/rooster_app/lib/router/routes.dart` - Navigation crashes
- `/frontend/rooster_app/lib/screens/roster/create_roster_screen.dart` - Button visibility
- `/frontend/rooster_app/lib/screens/availability/availability_screen.dart` - Wrong content
- `/backend/app/api/` - Assignment API endpoint
- `/frontend/rooster_app/lib/screens/home/` - Day count calculation
- `/frontend/rooster_app/lib/widgets/` - Badge update logic
