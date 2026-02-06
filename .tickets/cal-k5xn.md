---
id: cal-k5xn
status: open
deps: []
links: []
created: 2026-02-06T09:10:03Z
type: task
priority: 2
assignee: dlepage
tags: [performance, analysis, ui]
---
# G5: Add performance guardrail signal

Surface a lightweight processing-latency signal to help detect when analysis falls behind during live sessions.

## Acceptance Criteria

- Track per-buffer processing duration in analysis pipeline and compute a rolling average.\n- Expose a new status field (e.g., OK/High) in LiveFeedbackState or session status.\n- Update UI to show the status only while recording.\n- Add unit tests for the rolling average/threshold logic.

