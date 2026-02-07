---
id: cal-rg5k
status: closed
deps: []
links: []
created: 2026-02-07T00:00:00Z
type: chore
priority: 3
assignee: dlepage
---
# G37: Add release QA report template and references

Create a release candidate QA report template that captures user-facing readiness notes, and link it from existing release documentation.

## Acceptance Criteria

- New `RELEASE_QA_TEMPLATE.md` includes sections for build/run, permissions, session lifecycle, live feedback, recordings/playback, diagnostics export, packaging, notarization, performance checklist reference, and privacy confirmation.
- Template includes a user-facing release notes section (what changed, known issues, support contact).
- `RELEASE_CHECKLIST.md` references the QA template as the place to record results.
- `README.md` references the QA template alongside the release checklist.
- Unit test verifies the template exists and includes privacy confirmation and key sections.
