---
id: cal-othm
status: closed
deps: []
links: []
created: 2026-02-06T21:20:10Z
type: feature
priority: 1
assignee: dlepage
tags: [recordings, metadata, ui]
---
# G22: Add optional session titles

Prompt for an optional session title after stopping and persist it with recording metadata.

## Acceptance Criteria

- After stopping a recording session, a non-blocking title prompt is shown with Save/Skip.\n- Titles are persisted locally per recording (including session segments) and appear in the recordings list/detail.\n- Search matches the saved title.\n- Metadata files are cleaned up on delete.\n- Added/updated tests for metadata read/write and title display.


## Notes

**2026-02-06T21:26:01Z**

Implemented session title prompt with local metadata sidecars, updated recordings list display/search, and added metadata-related tests.
