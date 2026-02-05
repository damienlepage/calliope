---
id: cal-v2r1
status: closed
deps: []
links: []
created: 2026-02-05T19:10:00Z
type: task
priority: 2
assignee: dlepage
---
# MVP: Persist privacy disclosure acceptance

Persist the privacy disclosure acknowledgment so users do not need to re-confirm on every launch.

## Acceptance Criteria

- Acceptance state persists across app relaunches.
- UI initializes disclosure toggle from persisted state.
- Unit tests verify persistence behavior.
- No changes to audio routing or network behavior.

## Outcome
- Persisted disclosure acceptance in UserDefaults and initialize the toggle from stored state.
- Added unit coverage for disclosure persistence.
