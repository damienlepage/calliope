---
id: cal-w4rc
status: open
deps: [cal-ndcp, cal-0grx, cal-b1yg]
links: []
created: 2026-02-07T20:33:53Z
type: task
priority: 1
assignee: dlepage
---
# Verify packaged app on macOS 13 (Ventura)

Run packaged app QA checklist on macOS 13 and capture results.

## Acceptance Criteria

- Package built app is tested on macOS 13 (Ventura).
- release/QA-2026-02-07.md row for macOS 13 is updated (Environment, Machine, Launches, Permissions, Session Flow, Recordings Storage, Notes).
- Any failures are recorded with actionable notes.


## Notes

**2026-02-07T20:50:20Z**

Blocked 2026-02-07: automated environment lacks macOS 13 hardware/VM to run packaged app QA.

**2026-02-07T20:52:51Z**

Unable to run macOS 13 QA in this environment (host is macOS 26.2). Need Ventura hardware/VM to execute packaged app checklist and update release/QA-2026-02-07.md.

**2026-02-07T20:55:31Z**

Blocked until macOS 13 hardware access is confirmed (cal-b1yg). Environment is macOS 26.2 so Ventura QA cannot be executed here.
