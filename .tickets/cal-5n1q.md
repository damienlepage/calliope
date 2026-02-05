---
id: cal-5n1q
status: ready
deps: []
links: []
created: 2026-02-05T00:42:00Z
type: task
priority: 2
assignee: dlepage
---
# MVP: Add compact live feedback overlay

Provide a lightweight overlay for glanceable live feedback that can float above calls without distracting layout.

## Acceptance Criteria

- Add an overlay view that shows pace, crutch word count, and pause count in a compact layout.
- Overlay visibility is controlled by a user-facing toggle in settings and persists across launches.
- Overlay respects the always-on-top preference when enabled.
- Overlay updates use the same throttled live feedback pipeline as the main view.
- Unit tests cover overlay preference persistence and show/hide logic.
