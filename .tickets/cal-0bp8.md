---
id: cal-0bp8
status: open
deps: []
links: []
created: 2026-02-07T05:44:50Z
type: task
priority: 1
assignee: dlepage
---
# G48: Validate session continuity across background/minimize/reopen

Verify recording continues when app backgrounded/minimized and UI state restores accurately on reopen. Add lifecycle handling if gaps found.

## Acceptance Criteria

Session timer and speaking time remain accurate after background/minimize/reopen. Recording state (recording/idle), overlay state, and feedback panels restore without resets. Add or update unit coverage for lifecycle handling if logic changes.

