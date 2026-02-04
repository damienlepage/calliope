---
id: cal-821s
status: closed
deps: []
links: []
created: 2026-02-04T06:43:15Z
type: task
priority: 2
assignee: dlepage
---
# Prevent duplicate feedback updates on rebind

LiveFeedbackViewModel should clear previous subscriptions when bind is called again to avoid duplicate state updates.

## Acceptance Criteria

Calling bind twice should only deliver one update per feedback emission.

