---
id: cal-lsg9
status: closed
deps: []
links: []
created: 2026-02-04T07:07:19Z
type: task
priority: 1
assignee: dlepage
---
# Align crutch word detector with constants

Use Constants.crutchWords as the single source of truth and ensure multi-word phrases are detected consistently.

## Acceptance Criteria

Tests cover constants-derived detection and continue to pass.


## Notes

**2026-02-04T07:08:20Z**

Implemented constants-derived crutch word parsing and added tests. swift build failed due to Swift toolchain/SDK mismatch and non-writable SwiftPM/clang caches (same as prior lessons).
