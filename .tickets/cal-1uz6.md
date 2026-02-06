---
id: cal-1uz6
status: closed
deps: []
links: []
created: 2026-02-06T17:35:52Z
type: task
priority: 2
assignee: dlepage
---
# G15: Validate recording artifacts on stop

Add integrity checks when a recording stops to confirm expected audio and analysis artifacts exist and surface recoverable issues.

## Acceptance Criteria

- Recording stop path validates audio file + summary artifacts and emits a non-blocking warning on missing data.\n- Warning appears in recordings detail view (not Session) with guidance to retry.\n- Unit coverage added for integrity validation outcomes.

