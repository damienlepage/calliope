---
id: cal-ao1w
status: open
deps: []
links: []
created: 2026-02-06T06:30:42Z
type: task
priority: 2
assignee: dlepage
tags: [audio, capture]
---
# Confirm recording state after first buffer

Avoid setting isRecording true until the capture backend delivers the first audio buffer so the UI only shows recording after actual mic input flow begins.

## Acceptance Criteria

- AudioCapture does not mark isRecording true until the first buffer has been received (or a configurable confirmation callback indicates success).\n- If no buffers arrive within the start timeout, status transitions to captureStartTimedOut without flipping to recording.\n- Existing AudioCapture tests are updated or added to cover the new start confirmation flow.

