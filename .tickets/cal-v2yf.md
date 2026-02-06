---
id: cal-v2yf
status: closed
deps: []
links: []
created: 2026-02-06T06:17:54Z
type: task
priority: 1
assignee: dlepage
---
# MVP: Validate audio buffers are published and written during capture

Add coverage to ensure AudioCapture publishes audio buffers and writes to the audio file while recording.

## Acceptance Criteria

- Test simulates buffer delivery and asserts audioBufferPublisher emits.\n- Test asserts AudioFileWritable write is called when recording.\n- Test passes.

