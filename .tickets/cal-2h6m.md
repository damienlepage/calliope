---
id: cal-2h6m
status: closed
deps: []
links: []
created: 2026-02-04T12:50:00Z
type: task
priority: 1
assignee: dlepage
---
# MVP: Add microphone permission gating to recording

Ensure recording only starts when microphone access is authorized, and expose a small UI affordance to request access.

## Acceptance Criteria

- Start is disabled unless microphone permission is authorized and privacy guardrails are satisfied.
- UI shows current microphone permission state and provides a way to request access.
- `AudioCapture` refuses to start when microphone permission is not authorized.
- Add unit coverage for the permission manager and recording eligibility logic.

## Outcome
- Added a microphone permission manager with UI status and request button.
- Recording now requires both privacy guardrails and authorized microphone access.
- Added unit tests for permission manager state updates and eligibility rules.
