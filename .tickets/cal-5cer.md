---
id: cal-5cer
status: closed
deps: []
links: []
created: 2026-02-06T18:12:00Z
type: feature
priority: 2
assignee: dlepage
tags: [ui, storage]
---
# Bulk recording management and storage summary

Add bulk delete controls and storage usage summary in the recordings experience.

## Acceptance Criteria

Recordings view shows total storage used and recording count.\nDelete All action prompts for confirmation before removing files.\nBulk deletion updates list, storage summary, and clears errors.\nUnit tests cover bulk delete logic in RecordingManager/RecordingListViewModel.


## Notes

**2026-02-06T18:15:26Z**

Added Delete All action, bulk delete handling, and tests. Ran ./scripts/swift-test.sh.
