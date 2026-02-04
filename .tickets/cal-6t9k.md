---
id: cal-6t9k
status: closed
deps: [cal-aygb, cal-5qxd, cal-68hv, cal-smcu]
links: []
created: 2026-02-04T12:00:00Z
type: task
priority: 1
assignee: dlepage
---
# MVP: Wire live feedback into UI overlay

Bind `AudioAnalyzer` live outputs (pace, crutch count, pause count) into the SwiftUI overlay so users see real-time feedback while recording.

## Acceptance Criteria

- Overlay view displays pace, crutch count, and pause count values from the live analyzer state.
- Values update at least once per second while recording.
- Values reset predictably when recording stops.
- Add unit coverage for the view model or binding layer to verify updates and reset behavior.

## Outcome
- Added a LiveFeedbackViewModel that binds analyzer output and resets on recording stop.
- Overlay now reads from the view model state.
- Added unit tests covering live updates and reset behavior.
