---
id: cal-ps7j
status: ready
deps: []
links: []
created: 2026-02-06T19:06:00Z
type: task
priority: 3
assignee: dlepage
tags: [per-app, settings]
---
# G19: Per-app feedback profile detail editor (Settings)

Provide an MVP editor for per-app feedback profiles so users can tailor pace, pauses, and crutch words per conferencing app.

## Acceptance Criteria

- Settings "Manage Profiles" presents a list of existing profiles and a detail editor for the selected profile.
- Users can add a profile by entering a bundle identifier (e.g., "us.zoom.xos") and adjust pace min/max, pause threshold, and crutch words.
- Profiles are saved via `PerAppFeedbackProfileStore` and normalized on save.
- UI includes inline guidance about using bundle identifiers and examples for Zoom/Meet/Teams.
- Unit tests cover profile creation and normalization through the store.
- No new dependencies.
