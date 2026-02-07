---
id: cal-d71h
status: closed
deps: []
links: []
created: 2026-02-07T23:29:10Z
type: task
priority: 1
assignee: dlepage
---
# Session view layout cleanup for idle clarity

Align Session screen with G66: keep Start/Stop pinned at top, avoid scroll, show full feedback panel even when idle with inactive styling, remove capture/status popups and top recording/input/capture/inactive messages, and keep captions visible.

## Acceptance Criteria

- Start/Stop control remains at top of Session view in both idle and recording states.\n- Feedback panel is always visible; when idle it appears inactive (greyed) without hiding any elements.\n- No session-top status/error banners or capture/input/inactive messages appear in the Session view.\n- Live captions card remains visible in Session view regardless of recording state.\n- No ScrollView introduced; layout fits default Session window size.


## Notes

**2026-02-07T23:30:44Z**

Removed conditional gating for FeedbackPanel to keep it always visible; updated SessionViewState tests. Ran ./scripts/swift-test.sh.
