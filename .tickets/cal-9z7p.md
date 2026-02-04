---
id: cal-9z7p
status: closed
deps: []
links: []
created: 2026-02-04T02:20:00Z
type: task
priority: 2
assignee: dlepage
---
# Add RecordingManager test coverage with injectable base directory

Add lightweight tests that validate RecordingManager creates local recording URLs, filters recordings by extension, and deletes files reliably. Make RecordingManager testable by allowing a base directory injection while keeping the shared instance behavior unchanged.

## Acceptance Criteria

- RecordingManager supports an initializer that accepts a base directory for tests while keeping default behavior for `shared`.
- Unit tests verify:
  - `getNewRecordingURL` returns an `.m4a` URL under `CalliopeRecordings`.
- `getAllRecordings` returns only `.m4a` and `.wav` files.
- `deleteRecording` removes files.
- Tests pass with `swift test`.

## Outcome
- Added an injectable base directory + file manager for RecordingManager without changing shared behavior.
- Added unit coverage for recording URL creation, filtering, and deletion.
