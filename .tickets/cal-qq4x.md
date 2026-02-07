---
id: cal-qq4x
status: closed
deps: []
links: []
created: 2026-02-07T05:04:54Z
type: task
priority: 2
assignee: dlepage
---
# G44: Fit recordings table to default window

Reduce recordings table horizontal sprawl so columns remain readable at the default window width.

## Acceptance Criteria

- Recordings table fits within the default recordings window width without horizontal scrolling.
- Recording column shows only name/title; no extra metadata in the first column.
- Integrity issues remain visible in the list (via a compact status column or similar).
- Details remain accessible via the Details action.


## Notes

**2026-02-07T05:05:58Z**

Widened recordings view window width while keeping session/settings compact, constrained table column widths, and narrowed status to integrity-only indicator. Ran scripts/swift-test.sh.
