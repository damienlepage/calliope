---
id: cal-ny7p
status: closed
deps: []
links: []
created: 2026-02-06T21:30:20Z
type: task
priority: 1
assignee: ralph
---
# G22: Default session naming for recordings

Implement default recording display names that include session date and start time when no custom title is provided.

## Acceptance Criteria

- Recordings without metadata titles display a default name that includes date and start time.\n- Session part recordings append the part label to the default name.\n- Metadata titles still override default naming.\n- Unit tests cover default naming behavior.


## Notes

**2026-02-06T21:32:36Z**

Implemented default session display names using recording timestamps or modified dates, with part labels appended. Updated RecordingItem tests and RecordingListViewModel tests; swift-test.sh passes with cache warnings.
