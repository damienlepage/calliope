---
id: cal-jr6h
status: closed
deps: []
links: []
created: 2026-02-06T08:40:57Z
type: task
priority: 2
assignee: dlepage
---
# Centralize microphone permission copy

Move microphone permission status copy into MicrophonePermissionState to keep Settings messaging consistent and testable.

## Acceptance Criteria

- MicrophonePermissionState exposes a human-friendly description string for each state.\n- SettingsView uses the shared description instead of local switch.\n- Unit tests cover the description strings for each permission state.

