---
id: cal-rj9d
status: closed
deps: []
links: []
created: 2026-02-06T18:35:16Z
type: task
priority: 4
assignee: dlepage
tags: [settings, preferences, profiles]
---
# G19: Define per-app feedback profiles

Introduce a model and storage plan for per-app feedback profiles (Zoom/Meet/Teams) with Settings UI planning.

## Acceptance Criteria

- Document a lightweight profile model (app identifier, pace/pause/crutch settings).\n- Add placeholder Settings UI section (disabled or TODO) explaining upcoming per-app profiles.\n- Include unit coverage for profile storage model when implemented.


## Notes

**2026-02-06T18:41:30Z**

Added per-app profile model/store with persistence + Settings placeholder section and tests. Ran ./scripts/swift-test.sh (warnings about deprecated APIs in AudioBufferCopy/RecordingsListViewModel).
