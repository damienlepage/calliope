---
id: cal-31z1
status: closed
deps: []
links: []
created: 2026-02-07T07:17:03Z
type: task
priority: 1
assignee: dlepage
---
# G53: Capture launch-to-session readiness timing

Add instrumentation to measure time from app launch to session readiness (Start button enabled) and expose it in diagnostics export for verification.

## Acceptance Criteria

Diagnostics report includes launch timestamp and readiness latency (seconds) when available; readiness recorded only once per launch; unit tests cover tracker and diagnostics encoding.

