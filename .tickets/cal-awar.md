---
id: cal-awar
status: closed
deps: []
links: []
created: 2026-02-06T06:47:05Z
type: task
priority: 2
assignee: dlepage
---
# Gate mic-unavailable reason on permission

Avoid confusing users with 'No microphone input' before permission is granted. Update RecordingEligibility and tests.

## Acceptance Criteria

When microphone permission is not authorized, blocking reasons omit microphoneUnavailable even if no input devices.


## Notes

**2026-02-06T06:47:33Z**

swift test failed: swiftpm cache not writable (ModuleCache permission).
