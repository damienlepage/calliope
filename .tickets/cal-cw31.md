---
id: cal-cw31
status: closed
deps: []
links: []
created: 2026-02-07T12:00:00Z
type: task
priority: 2
assignee: dlepage
tags: [ui, preferences]
---
# G31: Surface current crutch-word preset with guidance

Expose which crutch-word preset (or custom list) is currently applied for global preferences, coaching profiles, and per-app profiles.

## Acceptance Criteria

- UI shows a "Current preset" label that resolves to a preset name when the list matches a preset; otherwise shows "Custom list".
- Guidance copy clarifies that multi-word phrases are supported and examples are provided.
- Matching logic is covered by unit tests.

## Notes

**2026-02-07**

Added preset-matching helper and labels in Settings, Coaching Profiles, and Per-App Profiles. Included guidance for multi-word phrases and unit tests for matching/label behavior.
