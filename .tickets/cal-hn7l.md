---
id: cal-hn7l
status: closed
deps: []
links: []
created: 2026-02-07T22:15:49Z
type: task
priority: 1
assignee: dlepage
tags: [ui, session]
---
# Session screen: remove status/error banners and top capture indicators

Remove non-essential status/error surfaces and capture indicators from the session screen.

## Acceptance Criteria

- No status or error section appears on the session screen when no voice is detected.
- Remove recording indicator and input/capture text at the top of the session screen.
- Remove the error message indicating Calliope is inactive.

## Notes

**2026-02-07T23:10:00Z**

Removed session status banner, capture recovery banner, and top capture/interruption text from `SessionView` so the session surface no longer shows status/error indicators or inactive messages.
