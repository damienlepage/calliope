---
id: cal-4n8m
status: closed
deps: []
links: []
created: 2026-02-04T12:55:00Z
type: task
priority: 2
assignee: dlepage
---
# Ensure recording filenames are unique

Recording files should not collide when created in rapid succession. Add a small test to confirm uniqueness.

## Acceptance Criteria

- Recording filenames are unique across consecutive calls.
- Unit test covers uniqueness behavior.

## Outcome
- Recording filenames now include a millisecond timestamp and UUID suffix.
- Added a unit test to validate uniqueness across consecutive calls.
