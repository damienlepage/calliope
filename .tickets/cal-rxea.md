---
id: cal-rxea
status: closed
deps: []
links: []
created: 2026-02-05T05:17:32Z
type: bug
priority: 1
assignee: dlepage
---
# Ignore speech recognition errors after stop

Suppress non-actionable speech recognition errors that arrive after the user stops recording.

## Acceptance Criteria

- SpeechTranscriber ignores errors that arrive after stopTranscription is called and remains in .stopped state.\n- Unit test covers stop -> error sequence.

