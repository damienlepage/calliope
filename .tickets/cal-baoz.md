---
id: cal-baoz
status: closed
deps: []
links: []
created: 2026-02-06T23:31:36Z
type: task
priority: 2
assignee: dlepage
tags: [ui, settings, compatibility]
---
# G26: Add in-app compatibility log template copy

Provide a Settings action to copy a conferencing compatibility verification log template for Zoom/Meet/Teams.

## Acceptance Criteria

- Settings > Conferencing Compatibility includes a 'Copy Verification Log' action.
- Clicking the action copies a markdown template with current date, placeholders for macOS/Calliope/device/input, and sections for Zoom/Google Meet/Teams.
- No network calls or file writes are required.
- Unit coverage validates template content includes all three platforms and the rendered date.

