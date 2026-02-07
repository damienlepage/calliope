---
id: cal-h772
status: closed
deps: []
links: []
created: 2026-02-07T00:17:17Z
type: task
priority: 2
assignee: dlepage
---
# G27: Add coaching profile model + persistence

Introduce a named coaching profile model and store persisted profile list + selection.

## Acceptance Criteria

- CoachingProfile model exists with name + AnalysisPreferences payload.\n- CoachingProfileStore persists profiles + selected ID in UserDefaults, seeding a default profile when empty.\n- Unit tests cover normalization (name trimming, empty rejection) and persistence/selection fallback.

