---
id: cal-d3oi
status: closed
deps: []
links: []
created: 2026-02-06T09:29:54Z
type: task
priority: 2
assignee: dlepage
---
# G4: Show capture status in compact overlay

Add capture transparency to compact overlay so users can confirm mic + backend while in-call.

## Acceptance Criteria

- When compact overlay is visible during recording, it shows capture status text derived from input device + backend status.\n- If input device name is blank, fallback to backend status only.\n- Add unit coverage for the formatter used by the overlay.


## Notes

**2026-02-06T09:31:00Z**

swift test failed: ModuleCache permission error under /Users/dlepage/.cache/clang/ModuleCache (unable to open Swift module); see lessons-learned.yaml note.
