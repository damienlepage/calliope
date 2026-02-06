---
id: cal-ikjc
status: closed
deps: []
links: []
created: 2026-02-06T07:43:01Z
type: task
priority: 2
assignee: dlepage
tags: [recordings, analysis, ui]
---
# Recording summary includes pause rate per minute

Add a pause-per-minute metric to the recording summary text so users can compare sessions.

## Acceptance Criteria

- RecordingItem.summaryText includes pauses/min when duration is available.\n- Summary formatting handles zero/short durations gracefully.\n- RecordingListViewModelTests updated for the new summary text.

