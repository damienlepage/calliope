---
id: cal-kta7
status: closed
deps: []
links: []
created: 2026-02-06T17:57:32Z
type: task
priority: 1
assignee: dlepage
---
# G13: Handle app focus interruptions during recording

Add app active/inactive interruption handling to audio capture so recording remains stable when the app loses focus.

## Acceptance Criteria

- Observe NSApplication willResignActive/didBecomeActive notifications in AudioCapture.\n- When recording and the app resigns active, set a non-blocking interruption message and keep recording.\n- When the app becomes active again, clear that interruption without affecting other interruption states.\n- Unit tests cover the focus interruption behavior.


## Notes

**2026-02-06T17:58:21Z**

Added app active/inactive interruption handling in AudioCapture with tests ensuring recording continues and interruptions clear on focus return.
