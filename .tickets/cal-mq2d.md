---
id: cal-mq2d
status: ready
deps: []
links: []
created: 2026-02-05T19:00:00Z
type: task
priority: 2
assignee: dlepage
tags: [ui, ux]
---
# MVP: Add always-on-top overlay toggle

Provide a simple toggle so the coaching window can stay above other apps during live calls.

## Acceptance Criteria

- A user-facing toggle enables/disables always-on-top behavior.
- When enabled, the main window level uses a floating/overlay level; when disabled it returns to normal.
- The toggle persists across app launches.
- Unit tests cover the persistence of the toggle state and default value.
