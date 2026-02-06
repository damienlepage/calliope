---
id: cal-v8zj
status: closed
deps: []
links: []
created: 2026-02-06T17:57:40Z
type: task
priority: 2
assignee: dlepage
---
# G15: Validate recording artifacts on stop

Run integrity validation on recording stop and surface recoverable issues for missing audio/summary artifacts.

## Acceptance Criteria

- Integrity validation runs when recording stops (including error stops) for all session recording URLs.\n- Missing audio or summary files generate integrity reports.\n- Recordings list surfaces integrity warnings when reports are present.\n- Unit tests cover stop-time validation and warning surfacing.

