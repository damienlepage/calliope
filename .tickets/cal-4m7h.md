---
id: cal-4m7h
status: closed
deps: []
links: []
created: 2026-02-06T07:42:47Z
type: task
priority: 1
assignee: dlepage
tags: [ui, feedback, analysis]
---
# Live feedback shows pause rate per minute

Add a pause-per-minute readout to the live feedback panel and compact overlay, computed from pause count and session duration.

## Acceptance Criteria

- FeedbackPanel shows a pause rate value (pauses/min) alongside count/avg when session duration is available.\n- CompactFeedbackOverlay shows the same pause rate label without clutter.\n- A formatter/helper computes pause rate with sensible behavior for short/zero durations.\n- Unit tests cover pause rate formatting and edge cases.

