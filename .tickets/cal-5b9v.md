---
id: cal-5b9v
status: closed
deps: []
links: []
created: 2026-02-07T00:12:34Z
type: task
priority: 2
assignee: dlepage
tags: [metadata, ux]
---
# G24: Align display name date with metadata createdAt

Use metadata.createdAt (when available) as the source for default session titles even if the filename includes a timestamp, so display name matches sessionDate sorting.

## Acceptance Criteria

- RecordingMetadataDisplayFormatter.displayName uses metadata.createdAt before inferred filename timestamps when building default session titles.\n- Unit test covers display name preferring metadata createdAt even when recording filename includes a timestamp.\n- No regressions to existing display name behavior for segment titles or explicit metadata titles.

