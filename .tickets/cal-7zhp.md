---
id: cal-7zhp
status: closed
deps: []
links: []
created: 2026-02-06T17:35:45Z
type: task
priority: 2
assignee: dlepage
---
# G13: Handle sleep/wake + interruptions

Ensure recording sessions stop or pause gracefully when the system sleeps, wakes, or the app loses audio input.

## Acceptance Criteria

- Recording stops cleanly on system sleep and resumes with a clear state on wake.\n- Audio interruptions (input loss, route change) surface a non-blocking status and do not corrupt active recordings.\n- Unit coverage added for new interruption state handling.

