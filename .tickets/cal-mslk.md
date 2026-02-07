---
id: cal-mslk
status: open
deps: [cal-ndcp, cal-0grx]
links: []
created: 2026-02-07T20:33:56Z
type: task
priority: 1
assignee: dlepage
---
# Verify packaged app on macOS 14 (Sonoma)

Run packaged app QA checklist on macOS 14 and capture results.

## Acceptance Criteria

- Package built app is tested on macOS 14 (Sonoma).
- release/QA-2026-02-07.md row for macOS 14 is updated (Environment, Machine, Launches, Permissions, Session Flow, Recordings Storage, Notes).
- Any failures are recorded with actionable notes.


## Notes

**2026-02-07T20:58:11Z**

Blocked 2026-02-07: automation host lacks macOS 14; needs access to macOS 14 test machine or VM to run packaged app QA.

**2026-02-07T21:01:17Z**

2026-02-07: Unable to run macOS 14 QA; current automation host is macOS 26.2 and no macOS 14 VM/test machine is available.
