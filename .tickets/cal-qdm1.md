---
id: cal-qdm1
status: closed
deps: []
links: []
created: 2026-02-06T09:22:14Z
type: task
priority: 2
assignee: dlepage
tags: [performance, ux]
---
# G5: Show processing latency average

Expose average processing latency (ms) in feedback UI for transparency while recording.

## Acceptance Criteria

- Feedback panel shows processing latency status plus average latency in ms while recording.\n- Compact overlay shows processing latency status plus average latency in ms.\n- Average latency resets to 0 when recording stops.\n- Unit tests cover latency formatting.


## Notes

**2026-02-06T09:25:15Z**

Added ProcessingLatencyFormatter, plumbed average latency through FeedbackState to feedback panel and compact overlay. swift test failed due to ModuleCache permission error at /Users/dlepage/.cache/clang/ModuleCache.
