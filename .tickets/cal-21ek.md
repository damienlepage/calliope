---
id: cal-21ek
status: closed
deps: []
links: []
created: 2026-02-07T00:54:06Z
type: feature
priority: 1
assignee: dlepage
---
# Seed coaching profile presets

Provide default coaching profile presets for new installs so users can select a named profile without creating one.

## Acceptance Criteria

When no coaching profiles are stored, at least 3 presets are seeded (including Default).|Session profile picker shows presets (since >1 profile).|Persisted profiles are unchanged for existing users.|Unit tests cover preset seeding and selection.


## Notes

**2026-02-07T00:55:20Z**

Ran swift test; failed due to ModuleCache permission error under /Users/dlepage/.cache/clang/ModuleCache (known issue).
