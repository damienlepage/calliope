---
id: cal-wqu8
status: closed
deps: [cal-fhbo]
links: []
created: 2026-02-06T21:39:53Z
type: task
priority: 2
assignee: dlepage
---
# G23: Surface speaking activity in recordings UI

Expose speaking time and speaking turn counts in recordings list metadata and the recording detail sheet so users can browse how often they spoke and for how long.

## Acceptance Criteria

- Recordings list items show speaking time and speaking turns alongside existing metadata when available.\n- Recording detail view includes a small section for speaking activity (total speaking time, speaking turns, speaking % of session).\n- Formatting handles long sessions (hours) and gracefully hides when metrics are unavailable.

## Notes

**2026-02-06T22:05:00Z**

Added speaking activity metadata to recordings list summary and a speaking activity section in the detail view, plus tests.
