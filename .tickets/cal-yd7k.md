---
id: cal-yd7k
status: closed
deps: []
links: []
created: 2026-02-06T09:05:00Z
type: task
priority: 2
assignee: dlepage
tags: [recordings, playback]
---
# Recordings: stop playback when active item disappears after reload

When the recordings list reloads, ensure any active playback is stopped if the active item is no longer present.

## Acceptance Criteria

- `RecordingListViewModel.loadRecordings()` stops playback if `activePlaybackURL` is not present in the refreshed list.
- `refreshRecordings()` and recording-stop reloads inherit the same behavior without extra callers.
- Unit tests cover stopping playback when the active recording is removed.

## Outcome

- Reloading recordings now stops playback when the active item disappears.
- Added unit coverage for the missing-active-item reload scenario.
