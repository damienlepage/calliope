---
id: cal-ngve
status: closed
deps: []
links: []
created: 2026-02-06T09:09:57Z
type: task
priority: 2
assignee: dlepage
tags: [ui, audio, settings]
---
# G4: Settings capture diagnostics

Expose capture transparency details in Settings without cluttering Session view.

## Acceptance Criteria

- Settings > Capture shows backend status text, selected input device name, and input format (sample rate + channel count) while idle and recording.\n- Values update when preferred microphone or voice isolation preference changes.\n- Add unit tests for any new formatter/helper used to render diagnostics.

