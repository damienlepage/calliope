---
id: cal-5qxd
status: closed
deps: [cal-aygb]
links: []
created: 2026-02-04T04:39:24Z
type: task
priority: 2
assignee: dlepage
---
# MVP: Live pace estimation from mic

Compute a simple real-time speaking pace metric from the mic stream. Success: pace value updates at least once per second while recording.

## Outcome
- Wired speech transcription into the audio analyzer so pace updates from live partial results.
- Pace analyzer now tracks elapsed time deterministically and resets with recording state.
- Added unit coverage for pace math and reset behavior.
