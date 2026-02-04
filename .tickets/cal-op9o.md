---
id: cal-op9o
status: closed
deps: []
links: []
created: 2026-02-04T14:45:10Z
type: task
priority: 2
assignee: dlepage
---
# Surface recording-blocked reasons

Expose why recording cannot start (privacy guardrails vs microphone permission) so UI can message users.

## Acceptance Criteria

- RecordingEligibility exposes ordered blocking reasons for privacy and mic permission.\n- ContentView shows a clear disabled message driven by those reasons.\n- Tests cover blocking reason output and existing canStart behavior.

