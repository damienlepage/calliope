---
id: cal-gi1p
status: closed
deps: []
links: []
created: 2026-02-07T02:22:56Z
type: task
priority: 3
assignee: dlepage
tags: [ui, session]
---
# Polish session feedback panel layout

Refine FeedbackPanel visual hierarchy to feel calmer and more intuitive without changing the underlying metrics or privacy behavior.

## Acceptance Criteria

FeedbackPanel uses a clearer visual grouping for pace, crutch words, pauses, and input/processing status (e.g., subtle cards or sections) while preserving existing data points.\nTypography hierarchy feels calmer (labels de-emphasized; key values emphasized) and spacing avoids crowding.\nSession screen remains minimal and only shows feedback during recording.


## Notes

**2026-02-07T02:25:24Z**

Updated FeedbackPanel layout with calmer card grouping; added CrutchWordFeedback helper + tests. swift test failed due to ModuleCache permission errors (known issue).
