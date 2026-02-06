---
id: cal-cxan
status: closed
deps: []
links: []
created: 2026-02-06T07:30:50Z
type: task
priority: 3
assignee: dlepage
---
# Recordings view manual refresh

Add a refresh action so users can reload recordings after external file changes.

## Acceptance Criteria

- Recordings view includes a Refresh action near the list header.\n- Refresh is disabled while recording.\n- RecordingListViewModel exposes a refresh hook (or reuses loadRecordings) and has unit coverage for the new behavior.

