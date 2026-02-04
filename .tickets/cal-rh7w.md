---
id: cal-rh7w
status: closed
deps: []
links: []
created: 2026-02-04T12:45:00Z
type: task
priority: 3
assignee: dlepage
---
# Add AudioBufferCopy unsupported format coverage

Add unit coverage that verifies `AudioBufferCopy.copy` returns nil for unsupported audio formats.

## Acceptance Criteria

- Unit test uses a non-supported `AVAudioFormat` (e.g. float64) and asserts copy returns nil.
- Tests pass with `swift test`.

## Outcome
- Added unit coverage asserting `AudioBufferCopy.copy` returns nil for float64 buffers.
