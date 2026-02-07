---
id: cal-u07e
status: closed
deps: []
links: []
created: 2026-02-07T07:49:45Z
type: task
priority: 2
assignee: dlepage
---
# G55: Include capture device context in diagnostics export

Diagnostics export should include capture backend status, input/output device names, and input format snapshot so support can verify privacy guardrails.

## Acceptance Criteria

DiagnosticsReport includes capture diagnostics fields for backend status, input/output device names, and input sample rate/channel count.\nDiagnostics export uses current AudioCapture values.\nUnit tests cover encoding/decoding and export wiring.

