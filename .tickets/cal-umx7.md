---
id: cal-umx7
status: closed
deps: []
links: []
created: 2026-02-07T01:06:48Z
type: feature
priority: 2
assignee: dlepage
tags: [ui, recordings, profiles]
---
# Surface coaching profile in recordings list + detail

Show the coaching profile used for each recording in the recordings list and the recording detail view.

## Acceptance Criteria

- Recordings list displays the coaching profile label used for each recording.\n- Recording detail view displays the coaching profile label used for the session.\n- Uses persisted profile metadata (no new dependency).\n- Adds or updates unit tests for the new display logic.


## Notes

**2026-02-07T01:08:30Z**

Added coaching profile label to recordings list + detail view; tests added for coachingProfileText; ran scripts/swift-test.sh.
