---
id: cal-vqnc
status: open
deps: []
links: []
created: 2026-02-07T08:10:48Z
type: task
priority: 2
assignee: dlepage
---
# Add end-to-end recordings + settings flow validation

Create end-to-end coverage for recordings list actions and settings edits persistence to ensure core navigation flows remain stable.

## Acceptance Criteria

- New tests validate recordings list view model exposes playback/reveal/delete availability for a saved session.\n- Test confirms settings updates persist and are reflected when returning to session/recordings state.\n- No UI automation required; use existing stores/view models.\n- Tests run under swift test.

