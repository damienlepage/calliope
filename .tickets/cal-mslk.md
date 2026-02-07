---
id: cal-mslk
status: closed
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

**2026-02-07T21:04:06Z**

2026-02-07: Still blocked in this environment; cannot run macOS 14 packaged app QA without a macOS 14 machine or VM. QA row in release/QA-2026-02-07.md remains Not run.

**2026-02-07T21:06:10Z**

2026-02-07: Still blocked in this environment (macOS 26.2 host; no macOS 14 machine/VM available). Unable to run packaged app QA; release/QA-2026-02-07.md remains Not run for macOS 14.

**2026-02-07T21:08:10Z**

2026-02-07: Still blocked; current host is macOS 26.2 and no macOS 14 VM/test machine available to run packaged app QA.

**2026-02-07T21:10:19Z**

2026-02-07: Still blocked in this environment (macOS 26.2 host; no macOS 14 VM/test machine available) so packaged app QA cannot be run here.

**2026-02-07T21:12:23Z**

2026-02-07: Still blocked; this environment does not have a macOS 14 (Sonoma) machine/VM, so packaged app QA cannot be executed here.
