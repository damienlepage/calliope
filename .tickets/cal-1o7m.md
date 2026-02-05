---
id: cal-1o7m
status: closed
deps: []
links: []
created: 2026-02-05T19:10:00Z
type: task
priority: 1
assignee: dlepage
---
# MVP: Enforce on-device speech recognition only

Ensure speech transcription never falls back to cloud recognition by requiring on-device support before starting.

## Acceptance Criteria

- `SpeechTranscriber` refuses to start when on-device recognition is unsupported.
- Authorization is not requested when on-device recognition is unsupported.
- Unit tests cover the on-device support gate.

## Outcome
- `SpeechTranscriber` now checks on-device support before requesting authorization.
- Added unit coverage to ensure authorization is skipped and state transitions to error when unsupported.
