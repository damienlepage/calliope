---
id: cal-g7c1
status: closed
deps: []
links: []
created: 2026-02-06T18:45:00Z
type: task
priority: 1
assignee: dlepage
---
# G7: Enforce coverage threshold in coverage script

Add a coverage gate to the existing coverage script so we can reliably track the 80% target and surface regressions.

## Acceptance Criteria

- `scripts/coverage.sh` calculates an overall line-coverage percentage from `llvm-cov report` output.
- The script exits non-zero when overall line coverage is below 80%.
- The coverage report includes the calculated percentage and the threshold value.
- Add unit coverage that validates the coverage script includes the threshold logic.

## Outcome
- Added a coverage threshold gate and summary line to `scripts/coverage.sh`.
- Added a unit test to assert the coverage script includes threshold logic.
