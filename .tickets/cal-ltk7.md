---
id: cal-ltk7
status: closed
deps: []
links: []
created: 2026-02-06T17:05:16Z
type: feature
priority: 1
assignee: dlepage
tags: [permissions, ux, analysis]
---
# Add speech recognition permission UX

Provide a speech recognition permission manager, settings UI, Info.plist usage string, and eligibility gating for speech transcription.

## Acceptance Criteria

- Settings shows speech recognition status with Grant/Open actions and disclosure copy.\n- Transcription start is gated on permission status (no repeated prompts while denied).\n- Info.plist template includes NSSpeechRecognitionUsageDescription.\n- Tests cover permission state mapping, settings action visibility, and gating in audio analyzer.\n- No network/transcript transmission added.

