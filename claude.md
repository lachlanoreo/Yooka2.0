# Purpose
This is the agent brief for the greenfield Rails monolith. It captures stack constraints, working style, and product requirements for the GTD-style “Plan” feature (Basecamp 4 + Google Calendar), including calendar navigation and date-locking behavior.

---

# Stack constraints
- Ruby 3.3.x recommended
- Rails 8.x recommended
- Hotwire (Turbo + Stimulus); no SPA framework
- ViewComponent preferred for non-trivial UI
- PostgreSQL
- Tailwind for CSS
- Tooling: mise (pin Ruby/Node)

Notes:
- Follow Rails conventions for structure.
- Background jobs allowed if the agent deems necessary.

---

# Testing expectations
Aim for reliable feedback. Add tests with meaningful changes.

Default test types:
- Model tests for sync mapping and ordering logic.
- Request tests for Plan actions (move task, complete task, schedule updates).
- System tests only for one or two critical flows; keep minimal for drag/move.

Local commands:
- `bin/rails test` (everything)
- `bin/rails test test/models/...`
- `bin/rails test test/requests/...`

---

# Feature Requirements: GTD “Plan” (Basecamp 4 + Google Calendar)

## Product intent
Provide a Plan tab to prioritize Basecamp tasks and personal tasks together, and time-block Today tasks against a day view calendar—without writing back to Google Calendar.

## Core mental model
- The app layers locally over Basecamp tasks assigned to me.
- Basecamp is source of truth for content and due dates.
- The app is source of truth for grouping, ordering, and time-blocking.

---



### Plan page layout
- Left pane: task groups + ordering + moving tasks between groups.
- Right pane: day view calendar (07:00–20:00) + “Top goal” field above it.

---

## Task groups (left pane)

### Fixed groups (order)
1. Inbox (visually distinct)
2. Today
3. Computer
4. Calls
5. Outside
6. Home
7. Waiting For
8. Some day

### Default grouping rules
- All new tasks (Basecamp + personal) go to Inbox.

### Manual ordering rules
- Tasks can be reordered within a group.
- Tasks can be moved between groups.
- Ordering persists per group.
- Ordering does not change anything in Basecamp.

### Task types shown together
1) Basecamp tasks (assigned to me)  
2) Personal tasks (created in the app)

### Task row requirements
- Checkbox to mark done
- Title
- Source indicator (Basecamp vs Personal)
- Due date indicator (if present)
- Basecamp tasks: icon/link to open the Basecamp to-do

---

## Basecamp task requirements

### Scope
- Only pull Basecamp to-dos assigned to me; ignore others.

### Sync behaviour
- Newly discovered Basecamp tasks are created/updated locally and placed into Inbox.
- Edits in Basecamp (title, due date, completion status) flow into the app.
- Completion: marking done in the app marks done in Basecamp.
- Archival: archived in Basecamp becomes archived locally; 404/deleted becomes archived locally.

### Due dates
- Basecamp due dates are read-only and mirror Basecamp; show none if missing.

### Deep link
- Provide “open in Basecamp” action to that to-do.

---

## Personal task requirements

### Creation
- User can add personal tasks from the Plan page; new personal tasks go to Inbox.

### Editing
- Personal task title is editable.
- Personal tasks can have an editable due date.

### Completion
- Marking done completes locally.

### Archival
- Personal tasks can be archived (soft delete).

---

## Calendar and time-blocking requirements (right pane)

### Calendar source
- Pull Google Calendar primary calendar only (read-only; no writes).

### Day view layout
- Shows a single day; default is today.
- Time range: 07:00–20:00.
- Time labels on the left; blank space visible where no events exist.
- All-day events are ignored (do not block time).

### Day navigation + locking
- The calendar supports navigating forward/backward by day.
- Past and future days are read-only for scheduling changes (locked); only today is editable for time blocks and top goal.
- Changes in the Today group affect only today’s calendar view (no retroactive or future blocks).

### “Top goal” field
- Text field above day view, saved per day.
- Editable with autosave.
- Editing permitted only for today (locked on past/future days).

### Time-blocking Today tasks
- Only tasks in Today can appear as time blocks on the day view.
- Adding to Today creates a local time-block for today (not a Google event).
- Default duration: 30 minutes.
- Auto-place in earliest available free space starting 07:00 upward.
- Resizing/moving allowed; snap to 5-minute increments.
- No overlap with Google Calendar events.
- Task blocks may overlap each other; display side-by-side with reduced width.
- Clamp at 20:00 if moved/resized beyond.
- Moving a task out of Today deletes its block for today.
- Editing (create/move/resize/delete) allowed only on today; past/future blocks are locked.

---

## UI styling
- Aim for shadcn-like: clean, neutral, modern, whitespace, subtle borders.
- Implement with Tailwind in Rails (no React required).

---

## Notes for the agent
- Store local fields for grouping, ordering, scheduling alongside Basecamp identifiers.
- Implement Basecamp sync and Google Calendar read for day view.
- Handle failures when completing Basecamp tasks (retry or surface error).
- Build a simple vertical slice first:
  1) Plan page + personal tasks in Inbox
  2) Group moving + ordering persistence
  3) Google day view rendering
  4) Today task time blocks (local scheduling) with non-overlap vs calendar
  5) Basecamp import (assigned-to-me) + open-in-Basecamp + completion writeback + archive behaviour

---

## Acceptance criteria
- Plan page exists with left task pane and right day view; Inbox is visually distinct.
- All new tasks (Basecamp + personal) land in Inbox.
- Tasks can be moved between groups and ordered within groups, persistently.
- Basecamp tasks:
  - only tasks assigned to me are shown
  - completion in app reflects in Basecamp
  - edits in Basecamp reflect in app
  - archived/deleted/404 in Basecamp becomes archived in app
  - due dates mirror Basecamp and are not editable
  - open-in-Basecamp link works
- Personal tasks:
  - can be created in Inbox
  - editable title and due date
- Calendar:
  - primary calendar events show in day view 07:00–20:00 with empty space visible
  - all-day events do nothing
  - day navigation works forward/back
  - past/future days are read-only for scheduling/top goal; only today editable
  - Today group changes only affect today’s calendar
- Today scheduling:
  - moving task into Today creates a 30-min block auto-placed earliest free slot (today only)
  - tasks cannot overlap calendar events
  - tasks can overlap each other and compress width
  - drag/resize snaps to 5 mins
  - moving task out of Today deletes its block for today
  - clamp at 20:00
- Top goal:
  - editable and saved per day; only today editable, locked for past/future
- Tests exist for core logic and request flows; `bin/rails test` passes.

