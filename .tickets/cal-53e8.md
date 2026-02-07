---
id: cal-53e8
status: closed
deps: []
links: []
created: 2026-02-07T21:25:42Z
type: bug
priority: 1
assignee: dlepage
tags: [ui, layout, session]
---
# G63: Fix live guidance layout overlap

Live guidance currently duplicates sections and overlaps panels, hiding Stop button. Clean up layout to match PRD single-panel guidance.

## Acceptance Criteria

- Live guidance screen shows a single main panel without overlapping sections.
- Pauses section appears only once.
- Stop button remains visible at default window size without scrolling.

