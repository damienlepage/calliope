---
id: cal-q080
status: closed
deps: []
links: []
created: 2026-02-06T15:11:52Z
type: task
priority: 2
assignee: dlepage
---
# Add critical processing latency status and warnings

Add a critical processing-latency threshold to complement the existing high threshold so users can see when feedback is severely lagging.

## Acceptance Criteria

- ProcessingLatencyStatus includes critical level with distinct formatting and color
- ProcessingLatencyFormatter returns warning text for critical latency
- UI components reflect critical state (session panel + compact overlay)
- Unit tests cover new formatter behavior


## Notes

**2026-02-06T15:13:15Z**

swift test failed: ModuleCache permission errors under /Users/dlepage/.cache/clang/ModuleCache and SwiftPM user cache not writable.
