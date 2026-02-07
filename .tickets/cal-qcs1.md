---
id: cal-qcs1
status: closed
deps: []
links: []
created: 2026-02-07T07:08:56Z
type: task
priority: 1
assignee: dlepage
---
# G52: Local cache isolation for swift test

Ensure swift test uses repo-local caches to avoid permission errors from user home paths.

## Acceptance Criteria

- ./scripts/swift-test.sh and ./scripts/coverage.sh set all relevant cache/temp env vars so clang and SwiftPM do not write to ~/Library or ~/.cache.\n- README test section remains accurate.\n- Running ./scripts/swift-test.sh no longer emits ModuleCache or SwiftPM cache permission errors.

