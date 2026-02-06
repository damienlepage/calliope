---
id: cal-d2fi
status: closed
deps: [cal-a9hr]
links: []
created: 2026-02-06T09:37:17Z
type: task
priority: 2
assignee: dlepage
tags: [performance, storage, recordings]
---
# G5: Persist performance metrics in recording summaries

Extend AnalysisSummary to include processing latency and utilization metrics for later review in the recordings view.

## Acceptance Criteria

- Extend AnalysisSummary with average and peak processing latency (ms) plus average and peak processing utilization (ratio or percent).
- AudioAnalyzer writes these metrics when ending a recording; defaults to 0 when unavailable.
- Recordings view surfaces the metrics in the recording detail row or summary text (recordings screen only).
- Add unit tests for summary encoding/decoding and formatting.

