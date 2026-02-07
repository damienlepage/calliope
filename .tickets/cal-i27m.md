---
id: cal-i27m
status: closed
deps: []
links: []
created: 2026-02-07T06:37:42Z
type: task
priority: 1
assignee: dlepage
---
# G49: Speaking time target in coaching profiles

Add a speaking-time target preference that can be set per coaching profile and for per-app profiles, with base defaults in Settings.

## Acceptance Criteria

- AnalysisPreferences includes a speaking-time target (with defaults + normalization) and persists in AnalysisPreferencesStore, CoachingProfileStore, and PerAppFeedbackProfileStore.\n- Settings and coaching profile editors include a speaking-time target control.\n- Live feedback surfaces show the target alongside speaking time.\n- Tests updated for new preference persistence/normalization.

