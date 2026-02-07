---
id: cal-lrkk
status: closed
deps: []
links: []
created: 2026-02-07T02:38:40Z
type: feature
priority: 2
assignee: dlepage
---
# G35: Add speaking-time % sorting to recordings list

Expose sorting options for speaking-time percentage in the recordings list and ensure ordering handles missing speaking stats.

## Acceptance Criteria

Recording sort menu includes speaking-time percentage options (highest/lowest). Recording list sorts by speaking-time percent derived from summary speaking time over session duration, with missing values sorted last. Unit tests cover speaking-time percentage sorting for both highest and lowest options.

