---
id: cal-5l9z
status: closed
deps: []
links: []
created: 2026-02-06T21:10:32Z
type: task
priority: 2
assignee: dlepage
---
# G21: Add search + sorting to recordings list

Add user-facing search and sort controls to the recordings list. Search should filter recordings by display name (case-insensitive). Sort should allow date newest/oldest and duration longest/shortest. Update view model logic and UI, and add unit coverage for search + sort.

## Acceptance Criteria

- Recordings view shows search field and sort control in the header.
- Search filters recordings by display name, case-insensitive, and empty search shows all.
- Sorting supports date newest/oldest and duration longest/shortest with stable tie-breaker.
- Unit tests cover search filtering and sort order.
- Existing recordings summary/trend/most recent reflect the filtered/sorted view without regressions.

