---
id: cal-5ozt
status: closed
deps: []
links: []
created: 2026-02-06T09:06:09Z
type: task
priority: 2
assignee: dlepage
tags: [ux, session, audio]
---
# Session: Surface capture device and backend status

Expose active input device name and capture backend status in the session view so users can confirm conferencing readiness while recording.

## Acceptance Criteria

- Session screen shows input device name and capture backend status while recording.\n- Formatting avoids empty device names and degrades gracefully if unavailable.\n- Unit tests cover the formatter that produces the session capture status text.


## Notes

**2026-02-06T09:06:53Z**

Added CaptureStatusFormatter, surfaced capture device/backend status in SessionView, and added unit tests.
