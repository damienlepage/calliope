---
id: cal-g24b
status: queued
deps: []
links: []
created: 2026-02-06T20:02:00Z
type: task
priority: 3
assignee: dlepage
---
# G24: Handle corrupt metadata files gracefully

Guard against corrupted or invalid metadata so the recordings list can recover cleanly.

## Acceptance Criteria

- Invalid metadata files are ignored and do not break recordings display.
- Corrupted metadata is removed or repaired to avoid repeated decode errors.
- Tests cover the fallback behavior for invalid metadata files.

