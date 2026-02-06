---
id: cal-tm2x
status: closed
deps: []
links: []
created: 2026-02-06T19:05:00Z
type: task
priority: 2
assignee: dlepage
tags: [trends, recordings]
---
# G18: Add 7-day trend deltas in recordings header

Provide a lightweight trend view by comparing the last 7 days of recordings to the prior 7 days for pace, crutch words, and pauses.

## Acceptance Criteria

- Add a new recordings header line that summarizes trend deltas for the last 7 days vs the prior 7 days.
- Trend line includes pace delta (WPM), crutch word delta (count), and pauses per minute delta.
- Trend line is omitted when either window lacks usable summaries.
- Unit tests cover trend formatting and omission behavior.
- No new dependencies.

## Outcome
- Added 7-day vs prior trend delta summary to the recordings header for pace, crutch count, and pauses/min.
- Added unit coverage for trend formatting and omission when the prior window is missing.
