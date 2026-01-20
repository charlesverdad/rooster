# UX Guidelines: Displaying Dates and Times

**Last Updated:** January 2026  
**Applies to:** All assignment and roster displays

---

## Principle: Context-Appropriate Date Display

Different users need different information at different times. The way we display dates should adapt to:
1. **User role** (Member vs Team Lead vs Admin)
2. **Context** (List view vs Detail view)
3. **Time proximity** (How soon is the event?)

---

## Date Display Rules

### For Members (Assignment Views)

Members care about **WHEN** they're serving, not the recurrence pattern.

#### List Views (Home, Assignments Tab)

**Use relative dates for upcoming assignments:**

| Time Until Event | Display Format | Example |
|-----------------|----------------|---------|
| Today | "Today • [time]" | "Today • 9:00 AM" |
| Tomorrow | "Tomorrow • [time]" | "Tomorrow • 9:00 AM" |
| 2-6 days | "In X days • [time]" | "In 5 days • 9:00 AM" |
| 1 week | "Next [day] • [time]" | "Next Sunday • 9:00 AM" |
| 2-3 weeks | "In X weeks • [time]" | "In 2 weeks • 9:00 AM" |
| 1+ month | "[Month] [day] • [time]" | "Feb 15 • 9:00 AM" |

**Example Card:**
```
┌─────────────────────────┐
│ 🔴 PENDING RESPONSE     │
│ Sunday Service - Media  │
│ Tomorrow • 9:00 AM      │  ← Relative date
│ [Decline]    [Accept]   │
└─────────────────────────┘
```

**Rationale:**
- **Cognitive ease:** "Tomorrow" is faster to process than "Jan 21"
- **Urgency:** Relative dates convey urgency better
- **Glanceability:** Quick scan shows what's coming up

---

#### Detail View (Assignment Detail Screen)

**Show both relative AND absolute dates:**

```
┌─────────────────────────────┐
│ Sunday Service - Media      │
│                             │
│ 📅 Tomorrow (Jan 21, 2026)  │  ← Relative + Absolute
│ ⏰ 9:00 AM - 11:00 AM       │
│ 📍 Main Sanctuary           │
│                             │
│ 🔁 Recurring: Every Sunday  │  ← Pattern shown here
└─────────────────────────────┘
```

**Rationale:**
- **Relative date:** Quick understanding ("Tomorrow")
- **Absolute date:** Specific reference (Jan 21)
- **Recurrence pattern:** Context for planning ahead
- **Only show recurrence in detail view** - not needed in lists

---

### For Team Leads (Roster Management)

Team leads need to see **coverage status** and **assignment patterns**.

#### Team Dashboard

**Show next occurrence with status:**
```
┌─────────────────────────┐
│ Sunday Service          │
│ Next: Tomorrow (Jan 21) │  ← Relative + absolute
│ ✅ 2/2 filled           │  ← Coverage status
└─────────────────────────┘
```

---

#### Roster Detail View

**Show upcoming occurrences chronologically:**
```
┌─────────────────────────┐
│ Tomorrow (Jan 21)       │  ← Relative
│ ✅ 2/2 filled           │
│ • John Smith ✅         │
│ • Sarah Johnson ✅      │
└─────────────────────────┘

┌─────────────────────────┐
│ In 8 days (Jan 28)      │  ← Relative
│ ⚠️ 1/2 filled           │
│ • Mike Chen ✅          │
│ • [+ Assign]            │
└─────────────────────────┘

┌─────────────────────────┐
│ In 2 weeks (Feb 4)      │  ← Relative
│ 🔴 0/2 filled           │
│ • [+ Assign]            │
│ • [+ Assign]            │
└─────────────────────────┘
```

**Rationale:**
- Relative dates for quick scanning
- Absolute dates in parentheses for reference
- Focus on **what needs action** (unfilled slots)

---

#### Roster Settings/Edit

**Show recurrence pattern prominently:**
```
┌─────────────────────────────┐
│ Sunday Service - Media      │
│                             │
│ 📅 Every Sunday             │  ← Pattern is primary
│ ⏰ 9:00 AM - 11:00 AM       │
│ 👥 2 volunteers needed      │
│                             │
│ Next occurrence: Tomorrow   │  ← Next date secondary
└─────────────────────────────┘
```

**Rationale:**
- Pattern is what they're editing
- Next occurrence provides context

---

## Implementation Guidelines

### Relative Date Logic

```javascript
function getRelativeDate(date) {
  const today = new Date();
  const diffDays = Math.ceil((date - today) / (1000 * 60 * 60 * 24));
  
  if (diffDays === 0) return "Today";
  if (diffDays === 1) return "Tomorrow";
  if (diffDays >= 2 && diffDays <= 6) return `In ${diffDays} days`;
  if (diffDays === 7) return `Next ${getDayName(date)}`;
  if (diffDays >= 8 && diffDays <= 20) return `In ${Math.ceil(diffDays / 7)} weeks`;
  
  // 3+ weeks: show month and day
  return formatDate(date, "MMM d");
}
```

### Display Format Helper

```javascript
function formatAssignmentDate(date, context) {
  const relative = getRelativeDate(date);
  const absolute = formatDate(date, "MMM d, yyyy");
  
  switch (context) {
    case 'list':
      // List view: relative only
      return relative;
      
    case 'detail':
      // Detail view: relative + absolute
      return `${relative} (${absolute})`;
      
    case 'notification':
      // Notifications: relative
      return relative;
      
    default:
      return relative;
  }
}
```

---

## Accessibility Considerations

### Screen Reader Announcements

**For relative dates:**
```html
<time datetime="2026-01-21T09:00:00">
  <span aria-label="Tomorrow, January 21st, 2026 at 9:00 AM">
    Tomorrow • 9:00 AM
  </span>
</time>
```

**Rationale:**
- Visual: "Tomorrow • 9:00 AM" (concise)
- Screen reader: Full date and time (complete info)

---

## Edge Cases

### Past Assignments

**Show as absolute dates:**
```
┌─────────────────────────┐
│ ✅ COMPLETED            │
│ Sunday Service - Media  │
│ Jan 14, 2026            │  ← Absolute date
└─────────────────────────┘
```

**Rationale:** Relative dates ("7 days ago") less useful for history

---

### Far Future (3+ months)

**Show absolute dates:**
```
┌─────────────────────────┐
│ 🔴 PENDING              │
│ Easter Service          │
│ April 20, 2026          │  ← Absolute date
└─────────────────────────┘
```

**Rationale:** "In 12 weeks" is harder to process than "April 20"

---

### All-Day Events

**Omit time:**
```
┌─────────────────────────┐
│ Church Retreat          │
│ Tomorrow                │  ← No time shown
│ All day event           │
└─────────────────────────┘
```

---

## Localization

### Date Formats by Region

| Region | Format | Example |
|--------|--------|---------|
| US | MMM d, yyyy | Jan 21, 2026 |
| UK | d MMM yyyy | 21 Jan 2026 |
| ISO | yyyy-MM-dd | 2026-01-21 |

### Relative Date Translations

Ensure relative terms are translated:
- English: "Tomorrow", "In 5 days"
- Spanish: "Mañana", "En 5 días"
- French: "Demain", "Dans 5 jours"

---

## Summary

**Key Principles:**

1. **Members see WHEN** (relative dates in lists)
2. **Team leads see COVERAGE** (status + relative dates)
3. **Detail views show BOTH** (relative + absolute)
4. **Recurrence patterns** only in detail/settings views
5. **Context matters** - adapt display to user's needs

**Before:**
```
Sunday Service - Media
Every Sunday • 9:00 AM
```

**After (Member View):**
```
Sunday Service - Media
Tomorrow • 9:00 AM
```

**After (Detail View):**
```
Sunday Service - Media
Tomorrow (Jan 21, 2026) • 9:00 AM
Recurring: Every Sunday
```

This approach reduces cognitive load and makes the app more intuitive for all users.
