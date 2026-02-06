---
id: cal-g24a
status: closed
deps: []
links: []
created: 2026-02-06T20:00:00Z
type: task
priority: 2
assignee: dlepage
---
# G24: Normalize session titles for metadata robustness

Harden session title normalization so metadata display is consistent even when users enter messy whitespace or control characters.

## Acceptance Criteria

- `RecordingMetadata.normalizedTitle` collapses whitespace, strips control characters, and enforces a reasonable max length.
- Recording display titles use normalized metadata titles when present.
- Tests cover the new normalization behavior and display usage.

## Notes

**2026-02-06T20:20:00Z**

Normalized titles now collapse whitespace, strip control characters, cap length, and are used in display paths with tests.
