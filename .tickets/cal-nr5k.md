---
id: cal-nr5k
status: ready
deps: []
links: []
created: 2026-02-05T19:05:00Z
type: task
priority: 1
assignee: dlepage
tags: [preferences, analysis, ui]
---
# MVP: Add sensitivity preferences for pace, pause, and crutch words

Expose basic tuning controls so users can adjust coaching sensitivity without code changes.

## Acceptance Criteria

- Preferences model persists pace min/max, pause threshold, and crutch word list locally.
- UI provides simple controls to edit these values.
- Audio analysis uses the stored preferences for pace classification, pause detection, and crutch word detection.
- Defaults match current Constants values on first launch.
- Unit tests validate default values, persistence, and analyzer wiring.
