---
id: cal-a49x
status: closed
deps: []
links: []
created: 2026-02-08T01:15:03Z
type: task
priority: 1
assignee: dlepage
---
# G71: Recordings-centric stop flow + WPM column + inline title edit

Implement recordings-centric stop flow per G71 requirements.

## Acceptance Criteria

- Session view no longer shows post-stop title prompt; feedback panel remains greyed with last values after stop.\n- When a recording completes, app switches to Recordings tab, selects the new recording, and focuses an inline title field with an empty draft and a Part placeholder.\n- Recordings table adds an Avg WPM column; accessibility list includes WPM value.\n- Inline title edits save optional titles to metadata and update display names without forcing defaults.


## Notes

**2026-02-08T01:21:44Z**

Implemented recordings-centric stop flow, inline title edit, and WPM column; ran ./scripts/swift-test.sh.
