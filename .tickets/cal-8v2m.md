---
id: cal-8v2m
status: ready
deps: []
links: []
created: 2026-02-05T00:40:00Z
type: task
priority: 1
assignee: dlepage
---
# MVP: Handle input device changes during recording

When the default audio input device changes mid-session (e.g., headset plugged/unplugged), the audio engine can reconfigure unexpectedly. We should handle this gracefully to avoid crashes or stuck recording states.

## Acceptance Criteria

- `AudioCapture` observes audio engine configuration changes while recording.
- If a configuration change occurs during recording, Calliope stops recording and surfaces a clear error state instructing the user to press Start again.
- Stopping due to a device change leaves the app in a stable idle state (no dangling taps).
- Unit tests cover the configuration-change path and ensure recording resets cleanly.
