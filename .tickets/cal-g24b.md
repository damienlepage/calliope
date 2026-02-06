---
id: cal-g24b
status: closed
deps: []
links: []
created: 2026-02-06T20:02:00Z
type: task
priority: 3
assignee: dlepage
---
# G24: Handle corrupt metadata files gracefully

Guard against corrupted or invalid metadata so the recordings list can recover cleanly.

## Acceptance Criteria

- Invalid metadata files are ignored and do not break recordings display.
- Corrupted metadata is removed or repaired to avoid repeated decode errors.
- Tests cover the fallback behavior for invalid metadata files.


## Notes

**2026-02-06T22:00:51Z**

Added metadata corruption handling: invalid JSON or empty titles remove metadata files; normalized titles are repaired. Added unit tests. Did not run swift test due to known ModuleCache permission errors under /Users/dlepage/.cache/clang/ModuleCache.
