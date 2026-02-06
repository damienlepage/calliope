---
id: cal-uosw
status: open
deps: []
links: []
created: 2026-02-06T15:53:03Z
type: task
priority: 3
assignee: dlepage
---
# G7: Add window-level controller coverage

Improve test coverage by making window level changes testable without touching NSApp directly.

## Acceptance Criteria

- WindowLevelController refactored to allow injecting a window list or applier.\n- Unit tests verify always-on-top sets floating level and false sets normal level using fakes.\n- Existing behavior unchanged for production calls.

