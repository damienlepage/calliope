---
id: cal-45td
status: closed
deps: []
links: []
created: 2026-02-07T08:38:44Z
type: task
priority: 1
assignee: dlepage
---
# Add release QA report scaffolding and helper script

Provide a standard location and helper to generate release QA reports from the template.

## Acceptance Criteria

- release/README.md explains where QA reports live and how to create them.\n- scripts/new-release-qa-report.sh copies RELEASE_QA_TEMPLATE.md to release/QA-YYYY-MM-DD.md without overwriting existing files and prints the path.\n- README.md release checklist section references the new script and release/ location.\n- Tests cover the new scaffolding expectations.

