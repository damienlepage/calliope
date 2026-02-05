---
id: cal-7p1k
status: closed
deps: []
links: []
created: 2026-02-05T00:00:00Z
type: task
priority: 2
assignee: dlepage
---
# MVP: Allow stop to clear capture errors

When a start attempt fails (e.g., permission missing), the UI can be stuck in an error state even after the user presses Stop. Provide a small reset path so Stop clears error state when not recording.

## Acceptance Criteria

- Pressing Stop when not recording clears any `AudioCapture` error status back to idle.
- No impact on normal stop behavior when recording.
- Unit test covers the stop-on-error path.

## Outcome

- Stop now clears error status even when not recording.
- Added a unit test covering the stop-on-error reset.
