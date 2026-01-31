# Implementation Plan: Production Bug Fixes

**Generated**: 2026-01-31
**Bug Report**: PRODUCTION_BUGS.md
**Target**: Fix all P0-P2 bugs before production launch

---

## Requirements Restatement

The production testing revealed **11 bugs** across 4 priority levels:
- **P0 (Critical)**: 4 bugs blocking core functionality
- **P1 (High)**: 3 bugs affecting user experience
- **P2 (Medium)**: 4 bugs with cosmetic/UX issues

The goal is to fix all bugs systematically, prioritizing by severity and dependency.

---

## Phase 1: Critical P0 Bugs (Must Fix)

### Bug #1: Flutter Navigation Crash - Red Screen of Death
**Files**:
- `frontend/rooster_app/lib/router/app_router.dart`

**Root Cause Analysis**:
After reviewing `app_router.dart`, I found the routing setup uses GoRouter correctly with 26+ routes. The reported error (`route._navigator == navigator is not true` and `GlobalKey used multiple times`) typically occurs when:
1. Multiple navigators share the same GlobalKey
2. Widget keys are reused across different parts of the widget tree
3. Navigator state conflicts during rapid navigation

**Fix**:
- The current router code looks correct. Need to investigate if there are GlobalKey conflicts in individual screens
- Check for any screens using `GlobalKey` that might be causing conflicts
- Ensure no widget is mounted in multiple places simultaneously

**Estimated Complexity**: HIGH - requires investigation of GlobalKey usage across screens

---

### Bug #2: Create Roster Button Not Visible
**Files**:
- `frontend/rooster_app/lib/screens/roster/create_roster_screen.dart`

**Root Cause Analysis**:
After reviewing `create_roster_screen.dart:387-471`, the Create button IS present in the code at the bottom of a `ListView`. The issue is likely:
1. **Viewport overflow**: ListView doesn't have enough space to show the button
2. **Keyboard overlap**: Soft keyboard covers the button when text fields are focused
3. **Missing scroll behavior**: User might not know to scroll down

**Fix**:
- Add `resizeToAvoidBottomInset: true` to Scaffold (likely already default)
- Consider making the Create button sticky at the bottom using a `Column` with `Expanded(child: ListView(...))` and button below
- Or wrap button in `SafeArea` with bottom padding

**Estimated Complexity**: LOW - UI layout adjustment

---

### Bug #3: Missing Unavailability UI Screen
**Files**:
- `frontend/rooster_app/lib/screens/availability/availability_screen.dart`
- `frontend/rooster_app/lib/providers/availability_provider.dart` (exists but unused)

**Root Cause Analysis**:
The `/availability` route currently shows `AvailabilityScreen` which displays "My Assignments" content (line 66). This screen incorrectly uses `AssignmentProvider` instead of `AvailabilityProvider`.

**Fix**:
- Create a proper unavailability management UI in `availability_screen.dart`:
  - Show list of user's unavailable dates
  - Add "Mark Unavailable" button with date picker
  - Allow deleting unavailability records
- Use `AvailabilityProvider` which already has the necessary methods:
  - `fetchUnavailabilities()`
  - `markUnavailable(date, reason)`
  - `deleteUnavailability(id)`

**Estimated Complexity**: MEDIUM - new UI screen needed

---

### Bug #4: Second Assignment to Same Roster Fails
**Files**:
- `backend/alembic/versions/` (new migration)
- `backend/app/services/roster.py:446-478`

**Root Cause Analysis**:
The `event_assignments` table lacks a `UNIQUE(event_id, user_id)` constraint (confirmed in migration `d79c335d1532`). While the service layer checks for duplicates, there's a race condition:
1. Two concurrent requests both pass the SELECT check
2. Both try to INSERT, causing unpredictable behavior

However, the reported bug says "first assignment works, subsequent fail" - this suggests the issue might be:
1. Frontend not properly refreshing state after first assignment
2. API returning error when trying to assign DIFFERENT user to same event
3. Cache/state mismatch between frontend and backend

**Fix**:
1. Add database unique constraint via new migration
2. Verify frontend properly handles assignment creation
3. Check if "unfilled slots" count is refreshed after assignment

**Estimated Complexity**: MEDIUM - migration + investigation

---

## Phase 2: High Priority P1 Bugs

### Bug #5: Negative Day Count Display
**Files**:
- `frontend/rooster_app/lib/widgets/upcoming_assignment_card.dart:86-94`
- `frontend/rooster_app/lib/providers/assignment_provider.dart` (add date filter)

**Root Cause**:
Line 89-90 in `upcoming_assignment_card.dart`:
```dart
if (daysUntil < 7) {
  return 'In $daysUntil days';  // Returns "In -5 days" for past dates!
}
```

**Fix**:
1. In `assignment_provider.dart`, filter out past assignments from `upcomingAssignments`:
```dart
List<EventAssignment> get upcomingAssignments =>
    _assignments.where((a) =>
      a.isConfirmed &&
      (a.eventDate?.isAfter(DateTime.now()) ?? false)
    ).toList();
```

2. In `upcoming_assignment_card.dart`, handle edge case:
```dart
if (daysUntil < 0) {
  return '${-daysUntil} days ago'; // or filter these out entirely
}
```

**Estimated Complexity**: LOW - simple date filtering

---

### Bug #6: URL/Content Route Mismatch
**Files**:
- `frontend/rooster_app/lib/router/app_router.dart`
- `frontend/rooster_app/lib/screens/settings/settings_screen.dart`

**Root Cause Analysis**:
The settings screen (line 118-120) navigates to `/availability` when "My Availability" is tapped. The issue is that:
1. URL shows correct route (`/#/availability`)
2. But `AvailabilityScreen` displays "My Assignments" content (Bug #3)

This is the SAME bug as #3 - once we fix the availability screen, this mismatch resolves.

**Fix**: Addressed by Bug #3 fix

**Estimated Complexity**: N/A - covered by Bug #3

---

### Bug #7: Unfilled Slots Badge Not Updating
**Files**:
- `frontend/rooster_app/lib/screens/home/home_screen.dart`
- `frontend/rooster_app/lib/providers/roster_provider.dart`

**Root Cause Analysis**:
After a successful assignment, the badge showing unfilled slots doesn't update because:
1. The count comes from provider state
2. Assignment creation doesn't trigger a refresh of the unfilled count
3. Need to call `fetchUnfilledSlots()` after assignment

**Fix**:
- After successful assignment in the provider, trigger a refresh of the unfilled slots count
- Or use optimistic UI update: decrement badge count immediately on success

**Estimated Complexity**: LOW - state management adjustment

---

## Phase 3: Medium Priority P2 Bugs

### Bug #8: Pluralization Error ("1 members")
**Files**:
- `frontend/rooster_app/lib/screens/teams/my_teams_screen.dart:296`

**Fix**:
Change line 296 from:
```dart
'${team.memberCount} members'
```
To:
```dart
'${team.memberCount} ${team.memberCount == 1 ? 'member' : 'members'}'
```

**Estimated Complexity**: TRIVIAL

---

### Bug #9: Menu Label Mismatch
**Files**:
- `frontend/rooster_app/lib/screens/settings/settings_screen.dart:116`

**Root Cause**:
Line 116 shows "My Availability" but links to a screen showing "My Assignments".

**Fix**:
Once Bug #3 is fixed, this becomes correct. The link (line 119) correctly goes to `/availability` which should show availability management, not assignments.

**Estimated Complexity**: N/A - covered by Bug #3

---

### Bug #10: Sunday Service Shows Monday Date
**Files**: Investigation needed

**Root Cause Analysis**:
Roster named "Sunday Service" shows "Monday, January 26, 2026" - but January 26, 2026 is actually a Monday. This is likely:
1. Test data issue (roster named incorrectly)
2. Or recurrence logic bug creating events on wrong day

**Fix**:
- Clean up test data before production
- Verify `recurrence_day` is correctly applied when generating events

**Estimated Complexity**: LOW - likely test data issue

---

### Bug #11: Day Selector Ambiguity (T for Tuesday and Thursday)
**Files**:
- `frontend/rooster_app/lib/screens/roster/create_roster_screen.dart:107-113`

**Root Cause**:
Lines 107-113 use single letters:
```dart
_buildDayButton('S', 0),  // Sunday
_buildDayButton('M', 1),  // Monday
_buildDayButton('T', 2),  // Tuesday
_buildDayButton('W', 3),  // Wednesday
_buildDayButton('T', 4),  // Thursday - SAME AS TUESDAY!
_buildDayButton('F', 5),
_buildDayButton('S', 6),
```

**Fix**:
Use "Tu" and "Th" to differentiate:
```dart
_buildDayButton('Su', 0),
_buildDayButton('M', 1),
_buildDayButton('Tu', 2),
_buildDayButton('W', 3),
_buildDayButton('Th', 4),
_buildDayButton('F', 5),
_buildDayButton('Sa', 6),
```

**Estimated Complexity**: TRIVIAL

---

## Implementation Order & Dependencies

```
Phase 1 (Critical - Parallel):
├── Bug #3: Availability Screen (independent)
├── Bug #4: Assignment DB + Frontend (investigation)
├── Bug #2: Create Button visibility (independent)
└── Bug #1: Navigation crash (investigation needed)

Phase 2 (High - After Phase 1):
├── Bug #5: Negative days (depends on understanding assignment flow)
├── Bug #7: Badge update (may be related to Bug #4)
└── Bug #6: Covered by Bug #3

Phase 3 (Medium - Quick fixes):
├── Bug #8: Pluralization (trivial)
├── Bug #11: Day selector (trivial)
├── Bug #9: Covered by Bug #3
└── Bug #10: Test data cleanup
```

---

## Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Navigation crash has multiple causes | MEDIUM | HIGH | Isolate and test each screen |
| Database migration breaks existing data | LOW | HIGH | Test on staging first |
| Assignment race condition edge case | LOW | MEDIUM | Add unique constraint |
| Unknown bugs in untested flows | MEDIUM | MEDIUM | E2E testing after fixes |

---

## Estimated Complexity Summary

| Bug # | Description | Complexity |
|-------|-------------|------------|
| 1 | Navigation crash | HIGH |
| 2 | Create button visibility | LOW |
| 3 | Availability screen | MEDIUM |
| 4 | Assignment failure | MEDIUM |
| 5 | Negative days | LOW |
| 6 | Route mismatch | N/A (Bug #3) |
| 7 | Badge update | LOW |
| 8 | Pluralization | TRIVIAL |
| 9 | Menu label | N/A (Bug #3) |
| 10 | Sunday/Monday | LOW |
| 11 | Day selector | TRIVIAL |

---

## Recommended Approach

Execute fixes using **parallel subagents** for independent bugs:

1. **Subagent 1**: Fix Bug #3 (Availability Screen) - covers #6 and #9
2. **Subagent 2**: Fix Bug #2 (Create Button visibility)
3. **Subagent 3**: Fix Bug #4 (Assignment failure) + Bug #7 (Badge update)
4. **Subagent 4**: Fix Bug #5 (Negative days) + Bug #8 + #11 (trivial fixes)
5. **Subagent 5**: Investigate Bug #1 (Navigation crash)

After all subagents complete:
- Run full test suite
- Manual E2E verification
- Clean up test data (Bug #10)
- Create single PR with all fixes

---

**WAITING FOR CONFIRMATION**: Proceed with this plan? (yes/no/modify)
