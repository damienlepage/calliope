---
id: cal-844z
status: closed
deps: []
links: []
created: 2026-02-06T07:51:16Z
type: task
priority: 2
assignee: dlepage
tags: [tests, feedback]
---
# G1: Add regression coverage for feedback metric formatting

Add unit coverage for feedback metric formatting edge cases to prevent UI regressions (pace, pauses, elapsed time).

## Acceptance Criteria

- New tests cover pause rate formatting when duration is nil/zero and when pauses are zero.
- Tests cover session duration formatting for short and long sessions.
- Tests cover pace label/value formatting across slow/target/fast/idle ranges.

