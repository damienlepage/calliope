---
id: cal-ndph
status: closed
deps: []
links: []
created: 2026-02-07T04:45:20Z
type: task
priority: 1
assignee: dlepage
---
# G46: Make session surface fixed and no-scroll

Remove ScrollView and trim session UI to session-relevant elements so default window size needs no scrolling.

## Acceptance Criteria

Only session-relevant elements are shown; non-essential status/diagnostic elements are removed or moved.

## Notes

**2026-02-07T00:00:00Z**

Removed the session ScrollView, gated capture status details to recording-only, and added coverage for the new session view-state flag. Default window layout no longer requires scrolling.
