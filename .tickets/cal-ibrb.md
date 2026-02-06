---
id: cal-ibrb
status: closed
deps: []
links: []
created: 2026-02-06T06:30:38Z
type: task
priority: 2
assignee: dlepage
tags: [ui, feedback]
---
# Gate waiting-for-speech on meaningful input

Avoid showing constant activity when only low-level input arrives; reset waiting timer only when meaningful mic input is detected.

## Acceptance Criteria

- While recording, if only input levels below InputLevelMeter.meaningfulThreshold arrive for longer than stale delay, showWaitingForSpeech becomes true.\n- When a feedback update includes inputLevel at or above InputLevelMeter.meaningfulThreshold, showWaitingForSpeech clears.\n- Existing reset-on-stop behavior remains.

