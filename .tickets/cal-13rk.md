---
id: cal-13rk
status: closed
deps: []
links: []
created: 2026-02-06T15:07:19Z
type: task
priority: 3
assignee: dlepage
---
# G5: Add performance guardrail tracker tests

Add unit coverage for processing latency/utilization trackers to ensure window averaging and status thresholds behave as expected.

## Acceptance Criteria

- Tests cover ProcessingLatencyTracker average/window behavior and status threshold.\n- Tests cover ProcessingUtilizationTracker average/window behavior and high/critical thresholds.\n- Tests pass.


## Notes

**2026-02-06T15:08:10Z**

Added window rollover tests for latency and utilization trackers.
