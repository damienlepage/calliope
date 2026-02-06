---
id: cal-mj2q
status: closed
deps: []
links: []
created: 2026-02-06T17:21:41Z
type: task
priority: 3
assignee: dlepage
---
# G12: Add keyboard shortcuts for session controls

Add keyboard shortcuts for Start/Stop and navigation between Session/Recordings/Settings.

## Acceptance Criteria

Cmd+R starts/stops recording when Session view is active.\nCmd+1/2/3 switch between Session/Recordings/Settings.\nShortcuts are documented in code comments or inline labels as needed.

## Notes

**2026-02-06**

Added menu commands for Cmd+1/2/3 navigation with shortcut labels, plus a focused Cmd+R toggle that only activates in Session. Covered AppSection shortcut labels with tests.
