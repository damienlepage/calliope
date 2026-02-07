---
id: cal-z9x1
status: closed
deps: []
links: []
created: 2026-02-07T22:57:24Z
type: task
priority: 1
assignee: dlepage
---
# G66: Session surface cleanup (visibility + no popups)

Align the Session UI with PRD clarity requirements: start/stop control at the top, no scrolling, all sections visible even when inactive (greyed), remove status/error popups and top-of-screen capture/input/inactive messages, and keep captions visible at all times.

## Acceptance Criteria

Start/Stop control sits at the top of the Session screen.
Session screen does not scroll at default window size; all sections remain visible while inactive content is greyed.
Top-level capture/input/recording status messages and pop-up banners are removed from Session view (if needed, they stay in Settings/diagnostics).
Live captions section remains visible in the Session layout even when transcription is empty (uses placeholder/empty state instead of collapsing).

## Notes

**2026-02-07T23:07:40Z**

Removed session status card and route/blocking banners from Session view, keeping the feedback panel visible with caption placeholder. Start/stop remains pinned at the top and inactive feedback stays dimmed.
