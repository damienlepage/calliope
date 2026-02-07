---
id: cal-thbz
status: closed
deps: []
links: []
created: 2026-02-07T05:44:47Z
type: task
priority: 1
assignee: dlepage
---
# G47: Ensure non-color status cues and readable contrast

Review status indicators and warnings in Session/Recordings/Settings to ensure no information is conveyed by color alone and contrast remains readable in light/dark mode.

## Acceptance Criteria

All status/warning indicators include text or symbol plus color. No critical meaning relies on color alone. Any status-only dots/badges include accessible text labels.

## Notes

**2026-02-07T06:01:00Z**

Added explicit crutch-word status labels in the live feedback panel and compact overlay, plus unit coverage for the new status text helper.
