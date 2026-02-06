---
id: cal-jrn3
status: closed
deps: []
links: []
created: 2026-02-06T17:21:38Z
type: task
priority: 3
assignee: dlepage
---
# G11: Show app version/build in Settings

Add a small About section in Settings showing Calliope version/build.

## Acceptance Criteria

Settings shows app version (CFBundleShortVersionString) and build (CFBundleVersion).\nUses a small helper to format version string for tests.\nUnit test covers formatting logic with injected bundle metadata.

