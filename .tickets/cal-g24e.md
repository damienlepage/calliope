---
id: cal-g24e
status: closed
deps: []
links: []
created: 2026-02-06T23:47:19Z
type: task
priority: 2
assignee: dlepage
---
# G24: Make session date display resilient to bad metadata

Prevent out-of-range metadata timestamps from confusing the recordings list and detail views.

## Acceptance Criteria

- `RecordingItem.sessionDate` and title fallbacks ignore unreasonable `createdAt` metadata and prefer inferred dates or file modification times.
- Recordings list and detail metadata text remain stable when metadata contains future or pre-2000 timestamps.
- Add unit coverage in `RecordingItemTests` or `RecordingListViewModelTests` for the date normalization and fallback behavior.

## Notes

Use `RecordingMetadata.normalizedCreatedAt` to centralize the decision logic.
