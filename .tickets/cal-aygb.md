---
id: cal-aygb
status: closed
deps: []
links: []
created: 2026-02-04T04:39:21Z
type: task
priority: 1
assignee: dlepage
---
# MVP: Mic capture pipeline skeleton

Implement a minimal microphone capture pipeline (AVAudioEngine or AVAudioRecorder) that can start/stop without errors. Success: Start/Stop toggles without crash and logs show audio frames arriving.

## Outcome
- Added a buffer publisher from the mic tap and connected it to the analysis pipeline.
- Added lightweight logging every 50 buffers to confirm frames arrive during a run.
- UI now uses live recording state to start/stop the capture pipeline.

## Notes
- `swift build` failed locally due to toolchain mismatch and module cache permissions; runtime verification still needed.
