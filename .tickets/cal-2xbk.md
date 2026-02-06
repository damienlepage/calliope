---
id: cal-2xbk
status: closed
deps: []
links: []
created: 2026-02-06T05:30:19Z
type: task
priority: 2
assignee: dlepage
---
# Ignore Audio Buffers When Not Recording

## Description
Prevent live analysis updates from audio buffers when a session is not actively recording. This avoids stale feedback (input level, pauses) after the user stops recording or before they start.

## Acceptance Criteria
- Audio analyzer ignores audio buffers while `isRecording == false`.
- Input level and pause metrics remain unchanged when buffers arrive outside recording.
- Test coverage added for the non-recording buffer behavior.

## Notes

**2026-02-06T05:32:38Z**

Added guard to ignore audio buffers when not recording; added AudioAnalyzer test. swift test failed due to ModuleCache permission/SDK mismatch.
