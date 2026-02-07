---
id: cal-auqb
status: closed
deps: []
links: []
created: 2026-02-07T23:06:44Z
type: task
priority: 1
assignee: dlepage
tags: [ui, session]
---
# G66: Session surface cleanup for visibility

Ensure Session screen meets PRD minimalism for G66.

## Acceptance Criteria

- Start/Stop control is placed at top of Session view and remains visible without scrolling at default window size.
- Session content is fixed-layout (no scrolling) and all live elements remain visible; when idle, metrics are visually inactive/greyed but still visible.
- Remove any status/error popups and top-of-session banners/messages related to recording/input/capture/inactive state from the Session view.
- Live captions area remains visible at all times (idle or recording) in the Session view.
- Add/adjust unit or UI coverage if needed for new logic.

