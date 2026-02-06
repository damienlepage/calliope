---
id: cal-nwag
status: closed
deps: []
links: []
created: 2026-02-06T18:24:25Z
type: task
priority: 2
assignee: dlepage
---
# G16: Add auto-clean retention for recordings

Add optional auto-clean controls in Settings and enforce retention for old recordings.

## Acceptance Criteria

- Settings shows an Auto-clean toggle with retention options (e.g., 30/60/90 days) and helper copy about local deletion.
- Auto-clean is disabled by default and persists across launches.
- When enabled, recordings older than the chosen retention are deleted (audio + summaries + integrity reports) without running while recording.
- Cleanup runs at least on recordings list refresh and after a recording stops.
- Unit coverage added for retention deletion logic.

