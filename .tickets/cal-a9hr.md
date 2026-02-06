---
id: cal-a9hr
status: closed
deps: []
links: []
created: 2026-02-06T09:37:11Z
type: task
priority: 2
assignee: dlepage
tags: [performance, analysis, ui]
---
# G5: Track processing headroom vs buffer duration

Add a processing headroom metric (processing time divided by buffer duration) to detect when analysis is approaching real-time limits.

## Acceptance Criteria

- Compute buffer duration from audio buffer frame length and sample rate for each processed buffer.
- Track a rolling average processing utilization (processingDuration / bufferDuration) with a small window (constant in Constants).
- Derive a status enum (OK/High/Critical) based on utilization thresholds (constants).
- Expose utilization average and status in FeedbackState and show it in FeedbackPanel and CompactFeedbackOverlay only while recording.
- Add unit tests for the tracker and threshold transitions.

