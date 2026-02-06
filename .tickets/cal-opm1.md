---
id: cal-opm1
status: closed
deps: []
links: []
created: 2026-02-06T15:30:51Z
type: task
priority: 1
assignee: dlepage
---
# Add swift test wrapper with local module cache

Introduce a test wrapper to avoid ModuleCache permission errors by using repo-local cache paths.

## Acceptance Criteria

- scripts/swift-test.sh exists and is executable.\n- The script uses repo-local module cache and SwiftPM cache directories.\n- The script forwards any arguments to swift test.\n- ralph.sh runs tests via scripts/swift-test.sh.

