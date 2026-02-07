---
id: cal-qa13
status: blocked
deps: []
links: []
created: 2026-02-07T20:30:00Z
type: task
priority: 1
assignee: dlepage
tags: [release, qa, packaging]
---
# G57: Packaged app verification on macOS 13 (Ventura)

Run the packaged app smoke test on macOS 13 hardware and record results in the release QA report.

## Acceptance Criteria

- `dist/Calliope.app` launches on macOS 13 without unexpected Gatekeeper errors.
- Permissions, session flow, and recordings storage checks are completed per RELEASE_CHECKLIST.md.
- Results are recorded in `release/QA-2026-02-07.md` for the macOS 13 line with machine details and notes.

## Blockers

Requires access to macOS 13 hardware capable of running the packaged app.
