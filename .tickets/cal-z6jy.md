---
id: cal-z6jy
status: closed
deps: [cal-3r4u]
links: []
created: 2026-02-06T23:50:13Z
type: task
priority: 2
assignee: dlepage
tags: [metadata, ui, recordings]
---
# Unify session metadata formatting in UI

Ensure session metadata (title, date/time, part labels) displays consistently across recordings list and detail views.

## Acceptance Criteria

- Recordings list and detail sheet use the same display-name formatter for session title + part labels.
- Date/time formatting uses a shared formatter and is consistent across views.
- Metadata display gracefully handles missing or legacy fields.
- Unit/UI tests verify consistent formatting for standard and long-session recordings.

