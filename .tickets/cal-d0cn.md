---
id: cal-d0cn
status: closed
deps: []
links: []
created: 2026-02-07T05:22:03Z
type: task
priority: 2
assignee: dlepage
---
# Validate session lifecycle across background/minimize/reopen

Ensure recording sessions remain stable when app is backgrounded, minimized, or reopened; validate timer accuracy and UI restoration.

## Acceptance Criteria

App state transitions (background/foreground, window close/reopen, minimize) do not stop recording or desync timers. UI restores active session state when reopened. Added unit/integration tests or documented manual verification steps if untestable.
