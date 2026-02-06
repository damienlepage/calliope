---
id: cal-7aay
status: closed
deps: []
links: []
created: 2026-02-06T18:35:13Z
type: task
priority: 3
assignee: dlepage
tags: [ui, recordings, metrics]
---
# G18: Add 7-day trend summary to recordings list

Surface a compact last-7-days summary in the Recordings header to support self-review trends.

## Acceptance Criteria

- When recordings in the last 7 days have analysis summaries, show a 'Last 7 days' summary line in the recordings header.\n- Summary includes average WPM, total crutch count, and pauses/min when duration is available.\n- If there are no recent summaries or duration data, omit the line.\n- Add unit coverage in RecordingListViewModelTests.

