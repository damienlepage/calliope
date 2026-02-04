---
id: cal-90g6
status: closed
deps: []
links: []
created: 2026-02-04T07:00:06Z
type: task
priority: 1
assignee: dlepage
tags: [ui, analysis]
---
# Use shared pace thresholds for feedback panel

Replace hardcoded pace thresholds in FeedbackPanel with a shared helper that uses Constants.targetPaceMin/Max.

## Acceptance Criteria

- New pace classification helper uses Constants thresholds by default\n- FeedbackPanel uses helper for pace color\n- Tests cover pace classification boundaries

