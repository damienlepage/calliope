---
id: cal-hz3m
status: closed
deps: []
links: []
created: 2026-02-06T17:10:00Z
type: task
priority: 2
assignee: dlepage
tags: [metadata, ux]
---
# G24: Harden session title entry and metadata clarity

Improve session metadata entry so titles are validated clearly (no silent truncation) and the save action reflects whether the title is valid.

## Acceptance Criteria

- Session title prompt shows a clear max-length hint and surfaces when a title will be shortened.
- Save action is disabled when the title is empty/invalid; Skip remains available.
- Normalized title logic exposes truncation info for UI use without changing storage semantics.
- Add unit tests covering title normalization info (valid, empty, truncated).
- No new dependencies.

## Notes

**2026-02-06T17:14:00Z**

Added title validation info + UI hinting, disabled Save when invalid, and added metadata info tests.
