---
id: cal-6p8d
status: closed
deps: []
links: []
created: 2026-02-06T18:10:30Z
type: task
priority: 2
assignee: dlepage
tags: [compatibility, settings, ux]
---
# G26: Track conferencing compatibility verification status

Add lightweight per-app verification tracking so users can mark Zoom/Meet/Teams as verified and see the last verification date in Settings.

## Acceptance Criteria

- Settings shows a verification toggle or button for Zoom, Google Meet, and Microsoft Teams.
- Each platform shows "Verified" with the last verification date once marked.
- Verification state is stored locally (UserDefaults) and survives relaunch.
- Unit tests cover the storage model and date formatting for verified states.

## Notes

