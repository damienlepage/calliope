---
id: cal-g24d
status: closed
deps: []
links: []
created: 2026-02-06T23:47:19Z
type: task
priority: 2
assignee: dlepage
---
# G24: Strengthen metadata backfill and cleanup consistency

Ensure metadata backfill and orphan cleanup behave predictably for multi-part sessions and malformed metadata.

## Acceptance Criteria

- `RecordingManager.backfillMetadataIfNeeded` applies normalized titles and reasonable `createdAt` values to all segments for a session when missing or invalid.
- `RecordingManager.cleanupOrphanedMetadata` removes metadata for missing recordings and repairs malformed metadata files when a recording exists.
- Add unit tests that cover:
  - Metadata backfill for multi-segment sessions with missing `createdAt`.
  - Cleanup behavior when metadata exists without a matching recording file.
  - Repair/removal of malformed metadata JSON.

## Notes

**2026-02-07T00:10:00Z**

Backfill now groups session segments to align normalized titles and createdAt across parts when missing or invalid. Cleanup removes orphaned metadata and triggers repair/backfill for malformed metadata when recordings exist. Added unit coverage for multi-part backfill and malformed metadata cleanup.

Prefer targeted unit tests in `RecordingManagerTests` and avoid UI changes in this task.
