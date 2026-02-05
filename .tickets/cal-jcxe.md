---
id: cal-jcxe
status: closed
deps: []
links: []
created: 2026-02-04T04:39:34Z
type: task
priority: 2
assignee: dlepage
---
# MVP: Privacy guardrails

Document and enforce that only local mic input is used and no data leaves device. Success: short privacy note in UI/README and code comments on data boundaries.


## Notes

**2026-02-04T05:07:23Z**

Added privacy guardrails UI with required confirmations and enforced start gating; added tests.

**2026-02-04T05:07:52Z**

Added README privacy notes and local-only recording comment in AudioCapture.

**2026-02-05T00:00:00Z**

Expanded privacy settings copy to state local-only processing and mic-only capture, added explicit UI statements, and enforced microphone-only input backend with test coverage.
