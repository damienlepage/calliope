---
id: cal-wo9i
status: closed
deps: []
links: []
created: 2026-02-06T21:52:31Z
type: task
priority: 3
assignee: dlepage
---
# G24: Add unit coverage for session title normalization

Ensure RecordingMetadata.normalizedTitle behavior is covered for whitespace trimming and empty input.

## Acceptance Criteria

- Tests validate that leading/trailing whitespace is trimmed.
- Tests validate that empty/whitespace-only titles return nil.

