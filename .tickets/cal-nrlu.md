---
id: cal-nrlu
status: open
deps: []
links: []
created: 2026-02-07T00:17:24Z
type: task
priority: 3
assignee: dlepage
---
# G28: Add audio route risk warning logic

Detect risky audio routes (e.g., built-in speakers + mic) and surface a warning during active sessions.

## Acceptance Criteria

- Audio route evaluator returns warning states based on input/output device names and capture backend.\n- Session UI shows a brief warning when a risky route is detected while recording.\n- Unit tests cover the evaluator logic.

