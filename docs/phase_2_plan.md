# Phase 2 Plan - Post-MVP Expansion

**Purpose:** Build on the completed MVP by closing UX gaps, operationalizing notifications, and adding team-lead tooling that supports real-world use.

---

## Goals

1. **Operational readiness**: Deliver reliable communications (push + email) and configurable notification preferences.
2. **Team-lead efficiency**: Improve assignment visibility, unavailability awareness, and event-level management.
3. **Polish + resilience**: Consistent error handling, loading states, and better empty-state guidance.

---

## Scope

### In Scope
- Send Invite screen wiring and resend support.
- Member assignment visibility for team leads.
- Unavailability/conflict awareness in quick assign flows.
- Push notification infrastructure (FCM) and settings toggles.
- Event detail screen for roster occurrences.
- Error/empty/loading UX pass across primary lists.

### Out of Scope (Phase 3+)
- Organization-level admin / multi-organization management.
- Advanced scheduling (auto-rotation, swap requests).
- Calendar views and analytics dashboards.
- Offline-first caching.

---

## Workstreams & Deliverables

### 1) Communication & Notifications
**Objective:** Make Rooster notification-first in production.

**Backend tasks**
- Create push notification service and token storage.
- Send pushes for new assignments, reminders, and declines.
- Add rate limiting and delivery logging.

**Frontend tasks**
- Register device tokens on login.
- Handle foreground/background notification clicks.
- Add notification toggle in settings (stored server-side).

**Acceptance criteria**
- A registered user receives a push when assigned.
- A team lead receives a push on decline.
- Notification toggle disables pushes without affecting in-app notifications.

---

### 2) Team-Lead Assignment Awareness
**Objective:** Improve team lead visibility and reduce scheduling errors.

**Backend tasks**
- Add endpoint: `GET /teams/:teamId/members/:userId/assignments`.
- Return upcoming assignments + status + event metadata.

**Frontend tasks**
- Load assignments in `MemberDetailScreen` (team lead view).
- Display assignment count in invite CTA for placeholders.

**Acceptance criteria**
- Team leads see upcoming assignments for any team member.
- Placeholder invite CTA displays assignment count when available.

---

### 3) Unavailability-Aware Quick Assign
**Objective:** Prevent assigning volunteers who are unavailable or already booked.

**Backend tasks**
- Ensure `/availability/conflicts` includes event-level conflicts and reasons.

**Frontend tasks**
- Load conflicts in `AssignVolunteersSheet`.
- Split lists into Available / Unavailable with reasons.
- Disable selection for unavailable entries.

**Acceptance criteria**
- Unavailable members are clearly labeled with reason.
- Assign button is disabled for unavailable members.

---

### 4) Event Detail & Roster Management
**Objective:** Provide per-event insights and quick actions.

**Frontend tasks**
- Add event detail screen with event metadata.
- Show assignments + slot status.
- Include add/remove volunteer actions from event detail.

**Backend tasks**
- Reuse existing roster event and assignment endpoints as needed.

**Acceptance criteria**
- Event cards in roster detail navigate to an event detail view.
- Team leads can add/remove volunteers at event level.

---

### 5) UX & Resilience Pass
**Objective:** Make the app predictable and forgiving in real usage.

**Tasks**
- Add consistent error banners for failed API calls.
- Add empty states with clear next steps.
- Add loading skeletons for lists (home, teams, rosters).
- Ensure form buttons are disabled during submission.

**Acceptance criteria**
- Users receive clear feedback on every failed network action.
- Empty states always provide a next action.

---

## Milestones (Suggested)

1. **M2.1 - Invite + Member Detail Wiring**
   - Send Invite screen hooked to API.
   - Member assignments endpoint + UI.

2. **M2.2 - Unavailability + Event Detail**
   - Conflicts integrated into quick assign.
   - Event detail navigation and assignment actions.

3. **M2.3 - Notifications Productionization**
   - FCM integration end-to-end.
   - Settings toggle + delivery logging.

4. **M2.4 - UX Polish Pass**
   - Empty states, error handling, loading skeletons.

---

## Risks & Dependencies

- **FCM setup** requires Firebase project credentials and mobile configuration.
- **Member assignment endpoint** must respect team permissions.
- **Unavailability conflicts** may require backend tuning for performance.

---

## Definition of Done (Phase 2)

- Send Invite flow is fully wired and resilient to errors.
- Team leads can view member assignments and avoid conflicts when assigning.
- Push notifications are delivered reliably with user-controlled toggles.
- Key list screens show robust empty/error/loading states.
