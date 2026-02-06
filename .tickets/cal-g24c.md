---
id: cal-g24c
status: closed
deps: []
links: []
created: 2026-02-06T23:47:19Z
type: task
priority: 2
assignee: dlepage
---
# G24: Normalize session title saves and created-at metadata

Harden the post-recording title flow so saved metadata is always normalized and uses a reasonable session date, even when user input is invalid or the session timestamp is missing.

## Acceptance Criteria

- Saving a session title always writes normalized (trimmed, de-duped whitespace, truncated) titles across all session segments.
- When the session `createdAt` is missing or unreasonable, metadata falls back to inferred session time from the recording filename or the current time before saving.
- If the user enters an invalid title, the app preserves default metadata without overwriting it.
- Add/update unit coverage for the save flow or supporting helper(s) to prove the normalization and fallback behavior.

## Notes

**2026-02-06T23:59:00Z**

Added RecordingManager save flow to normalize titles, infer createdAt fallback (filename or now), and skip invalid titles; ContentView now uses it with unit coverage.

Focus on the `ContentView` title prompt flow and use `RecordingMetadata.normalizedCreatedAt` for date normalization.
