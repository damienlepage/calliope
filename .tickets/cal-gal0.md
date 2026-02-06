---
id: cal-gal0
status: closed
deps: []
links: []
created: 2026-02-06T16:18:19Z
type: task
priority: 2
assignee: dlepage
tags: [release, packaging]
---
# G6: Add optional code signing step to release packaging

Add an optional code signing step to the release packaging workflow so artifacts are ready for distribution without requiring signing credentials in local builds.

## Acceptance Criteria

- scripts/package-release.sh signs dist/Calliope.app when SIGNING_IDENTITY is set and skips signing otherwise\n- Signing uses hardened runtime options and reports success/failure clearly\n- Tests cover the presence of the signing hook in the release script\n- README documents how to set SIGNING_IDENTITY to enable signing


## Notes

**2026-02-06T16:19:06Z**

Added optional code signing hook in package-release.sh, updated README, and expanded packaging script tests.
