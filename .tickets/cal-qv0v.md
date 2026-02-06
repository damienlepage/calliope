---
id: cal-qv0v
status: closed
deps: []
links: []
created: 2026-02-06T22:39:21Z
type: task
priority: 2
assignee: dlepage
---
# G24: Use session date for recording display + sorting

Use a consistent session date derived from metadata/inferred filename for recordings list detail text and date sorting. Remove reliance on file modification timestamps when metadata is available.

## Acceptance Criteria

- Recordings list detail text uses session date derived from metadata.createdAt or inferred filename (falls back to modifiedAt only when needed).\n- Date sorting uses the same session date logic.\n- Tests cover date derivation and sorting behavior.

