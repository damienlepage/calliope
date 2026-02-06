---
id: cal-900m
status: open
deps: []
links: []
created: 2026-02-06T15:30:55Z
type: task
priority: 2
assignee: dlepage
---
# Add code coverage report helper

Provide a simple script to run swift test with code coverage and summarize results for manual review.

## Acceptance Criteria

- scripts/coverage.sh exists and is executable.\n- Script runs swift test with code coverage enabled and emits a summary to stdout.\n- Script writes a coverage report file under dist/ (e.g., dist/coverage.txt).

