# Organisation UX Improvements

Pre-launch polish for the organisation management feature. These address gaps found during UX review of the current implementation.

---

## 1. Non-admin members: show read-only org info

**Problem:** Regular volunteers have zero visibility into which organisation they belong to. The Organisation row in Settings and the org header on My Teams are both hidden for non-admins.

**Solution:**
- **Settings screen:** Show a read-only "Organisation" row for all users (not just admins). Display the org name as subtitle. Tapping it does nothing (no chevron) since they can't manage it.
- **My Teams screen:** Show the org header card for all users, but without the "Manage" link for non-admins. Just the org name and team count.

**Files:**
- `frontend/.../screens/settings/settings_screen.dart` — remove `isAdmin` gate, make the row non-tappable for non-admins
- `frontend/.../screens/teams/my_teams_screen.dart` — show org header for all users, conditionally hide "Manage" link

---

## 2. Add member from Org Settings

**Problem:** Admins can change roles and remove members, but there's no way to add someone to the organisation directly. Currently people only join through team invites.

**Solution:**
- Add an "Invite Member" button at the bottom of the members list on the Org Settings screen
- Tapping opens a dialog with an email field
- Backend sends an invite email (reuse existing invite infrastructure)
- If the user already exists in the system, add them directly to the org
- If not, send an invite link that, when accepted, adds them to the org

**Files:**
- `frontend/.../screens/organisations/org_settings_screen.dart` — add invite button + dialog
- `backend/app/api/organisations.py` — add invite endpoint (or reuse existing invite flow)
- `backend/app/services/organisation.py` — add invite logic

**Note:** For MVP, this could be simplified to just adding existing users by email (no invite email). The full invite-by-email flow can come later.

---

## 3. "Set up your organisation" prompt on Home screen

**Problem:** The setup prompt only appears on the My Teams screen. If an admin primarily stays on Home, they may never see it.

**Solution:**
- Add the same "Set up your organisation" prompt card to the Home screen, shown above the "Upcoming" section
- Only for admins with a personal (unnamed) org
- Dismissing it on either screen should dismiss it everywhere (or just have it disappear once the org is named)

**Files:**
- `frontend/.../screens/home/home_screen.dart` — add org setup prompt (reuse the same widget or extract a shared one)
- Consider extracting `OrgSetupPrompt` widget into `frontend/.../widgets/org_setup_prompt.dart`

---

## 4. Show member count on org header card

**Problem:** The My Teams org header shows "4 teams" but not the member count. This is useful context for admins.

**Solution:**
- Fetch the org member count and display it alongside team count
- Format: "City Church · 4 teams · 3 members" or on separate lines

**Files:**
- `frontend/.../screens/teams/my_teams_screen.dart` — add member count to the org header card
- `frontend/.../providers/organisation_provider.dart` — may need to expose member count (could come from the `/auth/me` response or a lightweight API call)

**Note:** To avoid an extra API call, consider adding `member_count` to the `OrganisationWithRole` schema returned by `/auth/me`.

---

## 5. Self-action explanation on Org Settings

**Problem:** On the members list, the current user (Charles) shows "(you)" but has no actions menu. An admin might wonder why they can't change their own role.

**Solution:**
- Add a subtle hint below or beside the "(you)" label, e.g. greyed-out text "Can't modify your own role"
- Or: show the "..." menu but with disabled items and a tooltip

**Simpler approach for launch:** Just keep the "(you)" label as-is. It's conventional and self-explanatory enough. Low priority.

---

## 6. Name edit polish

**Problem:** The Cancel/Save buttons on the name edit are functional but could be easier to interact with.

**Solution:**
- Make Cancel a more visible `OutlinedButton` instead of a `TextButton`
- Ensure pressing Enter in the text field submits (already works via `onSubmitted`)

**Files:**
- `frontend/.../screens/organisations/org_settings_screen.dart` — change Cancel to OutlinedButton

**Low priority — acceptable for launch as-is.**

---

## Priority for launch

| # | Item | Priority | Effort |
|---|------|----------|--------|
| 1 | Non-admin org visibility | **High** | Small |
| 2 | Add/invite member from org settings | Medium | Medium |
| 3 | Setup prompt on Home screen | Medium | Small |
| 4 | Member count on header | Low | Small |
| 5 | Self-action explanation | Low | Tiny |
| 6 | Name edit button polish | Low | Tiny |

**Recommended for pre-launch:** Items 1, 3, 4, 6 (all small effort). Item 2 can follow shortly after launch. Item 5 is fine as-is.
