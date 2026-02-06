---
id: cal-9g2g
status: closed
deps: []
links: []
created: 2026-02-06T05:20:44Z
type: task
priority: 1
assignee: dlepage
tags: [audio, analysis, privacy]
---
# Ignore transcriptions when not recording

Prevent late or stray speech transcription results from updating live feedback when the session is not recording.

## Acceptance Criteria

- AudioAnalyzer ignores transcription updates when isRecording is false.\n- Live feedback metrics (pace/crutch counts) remain unchanged if transcription arrives after stop.\n- Unit tests cover the new behavior.

