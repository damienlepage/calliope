---
id: cal-9e2p
status: closed
deps: []
links: []
created: 2026-02-06T00:00:00Z
type: task
priority: 1
assignee: dlepage
---
# Add pause duration metrics to live feedback and summaries

Track average pause duration during live sessions and surface it in the live feedback UI and recording summaries.

## Acceptance Criteria
- Pause detection tracks average pause duration for the current session.
- Live feedback displays pause count and average pause duration while recording.
- Analysis summaries persist average pause duration alongside pause count and threshold.
- Recordings list shows pause count and average pause duration when a summary exists.
- Unit tests cover pause duration tracking, UI formatting, and summary persistence/loading with local-only data.
- No network usage is introduced.

## Outcome
- Added average pause duration tracking to `PauseDetector` and wired it through `AudioAnalyzer` into live feedback.
- Live feedback and compact overlay show pause count with average duration.
- Analysis summaries now persist average pause duration and recordings list surfaces it in summary text.
- Added unit coverage for pause duration tracking and summary formatting/persistence.
