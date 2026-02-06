---
id: cal-g6c1
status: ready
deps: []
links: []
created: 2026-02-06T18:46:00Z
type: task
priority: 2
assignee: dlepage
---
# G6: Add release bundle metadata for app packaging

Improve the app bundle so it includes standard metadata helpful for release packaging.

## Acceptance Criteria

- `scripts/build-app.sh` copies a `PkgInfo` file into the app bundle.
- The `PkgInfo` file contains the standard `APPL????` signature.
- Add a small unit test that verifies the build script references `PkgInfo` and the template exists.
