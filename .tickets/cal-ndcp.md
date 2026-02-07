---
id: cal-ndcp
status: closed
deps: []
links: []
created: 2026-02-07T20:33:32Z
type: task
priority: 1
assignee: dlepage
---
# Prepare packaged app build for QA

Run packaging scripts to produce the release candidate app bundle and zip for QA.

## Acceptance Criteria

- `./scripts/build-app.sh` succeeds and outputs `dist/Calliope.app`.
- `./scripts/package-release.sh` succeeds and outputs a versioned zip in `dist/`.
- Update `release/QA-2026-02-07.md` lines for build/package steps with results and notes.
