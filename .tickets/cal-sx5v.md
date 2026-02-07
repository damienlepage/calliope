---
id: cal-sx5v
status: closed
deps: []
links: []
created: 2026-02-07T07:22:33Z
type: task
priority: 1
assignee: dlepage
---
# G53: Launch readiness SLA guardrail in diagnostics

Add explicit launch readiness SLA evaluation so diagnostics reports indicate whether session readiness met the 2-second target.

## Acceptance Criteria

Diagnostics report includes readiness target seconds and status (on_target/slow or similar) derived from sessionReadyLatencySeconds with a 2s threshold. Unit tests cover status calculation for below/above threshold and nil latency.


## Notes

**2026-02-07T07:24:51Z**

Added readiness SLA target and status to diagnostics report with tests; swift test passes via ./scripts/swift-test.sh.
