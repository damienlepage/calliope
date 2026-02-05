---
id: cal-t8f2
status: closed
deps: []
links: []
created: 2026-02-05T12:30:00Z
type: task
priority: 1
assignee: dlepage
---
# MVP: Ensure stop recording handles no-speech cleanly

Prevent stop actions from surfacing speech recognition errors when no speech is detected. This should keep the UI status clean and avoid confusing error banners in quiet sessions.

## Acceptance Criteria

- Stopping a recording session after silence does not surface speech recognition errors to the user.
- Any underlying recognition cancellation or timeout errors are mapped to a non-error "stopped" state.
- Unit tests cover the stop flow with no speech detected and verify UI status remains non-error.
- No changes to audio routing, network behavior, or privacy guardrails.

## Outcome
- Suppressed benign no-speech and cancelation speech recognition errors by mapping them to a stopped state.
- Added speech transcriber state tracking and tests to ensure silent stop paths do not surface errors.
