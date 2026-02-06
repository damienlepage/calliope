---
id: cal-fx9n
status: ready
deps: []
links: []
created: 2026-02-06T09:06:00Z
type: task
priority: 2
assignee: dlepage
tags: [recordings, ux]
---
# Recordings: clear stale delete prompts after list reload

When recordings are reloaded (manual refresh or recording stops), clear any pending delete prompt so the UI stays consistent with the latest list.

## Acceptance Criteria

- `RecordingListViewModel.loadRecordings()` clears `pendingDelete` and `deleteErrorMessage` before publishing refreshed items.
- Unit tests cover pending delete clearing when the list reloads.
