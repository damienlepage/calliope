---
id: cal-s28g
status: closed
deps: []
links: []
created: 2026-02-06T16:31:30Z
type: task
priority: 3
assignee: dlepage
tags: [ui, recordings]
---
# Recordings detail shows hours for long sessions

Ensure individual recording detail text displays hours for long recordings (>= 1 hour) while keeping short sessions in mm:ss.

## Acceptance Criteria

- RecordingItem duration formatting uses H:MM:SS when duration is >= 3600 seconds.
- Durations under 1 hour continue to render as MM:SS.
- Unit tests cover both cases.

