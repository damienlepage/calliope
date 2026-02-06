---
id: cal-w5f9
status: open
deps: []
links: []
created: 2026-02-06T22:18:48Z
type: task
priority: 3
assignee: dlepage
---
# Cleanup orphaned or invalid recording metadata

Remove metadata artifacts that no longer correspond to a recording or contain invalid data to keep display consistent.

## Acceptance Criteria

- Recording refresh/cleanup detects metadata files without a corresponding recording and removes them.\n- Invalid metadata JSON or empty/invalid titles are removed (with fallback display using filename/date).\n- Tests cover orphan metadata cleanup and invalid metadata removal.

