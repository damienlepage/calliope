---
id: cal-yn5i
status: open
deps: [cal-45td]
links: []
created: 2026-02-07T08:38:47Z
type: task
priority: 1
assignee: dlepage
---
# Verify packaged app on supported macOS versions and record results

Run packaged app smoke tests on supported macOS versions and record results in a release QA report.

## Acceptance Criteria

- Packaged app verified on macOS 13, 14, and 15 per RELEASE_CHECKLIST.md.\n- A release QA report in release/ includes per-version results for launch, permissions, session flow, and recordings storage.\n- Any deviations noted with mitigation or follow-up tickets.


## Notes

**2026-02-07T08:43:20Z**

QA report created at release/QA-2026-02-07.md with all items marked Not run because this environment cannot launch packaged app or access macOS 13/14/15 test machines. Manual verification required on real hardware.

**2026-02-07T08:45:23Z**

Still blocked in this environment: cannot launch packaged app or access macOS 13/14/15 hardware to verify. Requires manual QA run on supported macOS versions and updating release/QA-2026-02-07.md with results.

**2026-02-07T08:47:27Z**

2026-02-07: Still blocked in this environment; cannot run packaged app or access macOS 13/14/15 hardware for smoke tests. Manual QA required to update release/QA-2026-02-07.md.

**2026-02-07T18:08:31Z**

Blocked: cannot run packaged app or access macOS 13/14/15 hardware in this environment. Manual QA required to update release/QA-2026-02-07.md with results.

**2026-02-07T18:16:26Z**

Blocked in this environment: cannot launch packaged app or access macOS 13/14/15 hardware. Manual QA still required to update release/QA-2026-02-07.md with results.

**2026-02-07T18:18:21Z**

2026-02-07: Still blocked in this environment; cannot launch packaged app or access macOS 13/14/15 hardware. Manual QA required to update release/QA-2026-02-07.md with results.
