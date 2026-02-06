---
id: cal-7hhj
status: closed
deps: []
links: []
created: 2026-02-06T07:51:13Z
type: task
priority: 1
assignee: dlepage
tags: [ui, feedback]
---
# G1: Audit live feedback UI against PRD

Review Session + Compact overlay feedback UI for PRD compliance and tighten copy/layout if needed.

## Acceptance Criteria

- Session screen is minimal when idle (prompt + Start only; no feedback panel).
- During recording, feedback panel shows pace (with target range hint + WPM), crutch count, pauses (count + avg + rate/min), input level meter, and elapsed time.
- Compact overlay mirrors the same metrics in a compact format.
- Any copy/layout adjustments are covered by updated/added unit tests (e.g., SessionViewState or formatter tests).


## Notes

**2026-02-06T07:51:56Z**

Reviewed SessionView/FeedbackPanel/CompactFeedbackOverlay; idle state shows prompt + Start only, and recording state includes pace (WPM + target range), crutch count, pauses (count + avg + rate/min), input level meter, and elapsed time. Compact overlay mirrors metrics. No copy/layout changes needed.
