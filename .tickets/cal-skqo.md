---
id: cal-skqo
status: closed
deps: []
links: []
created: 2026-02-06T15:24:15Z
type: task
priority: 2
assignee: dlepage
---
# G6: Add app bundle build script

Create a minimal packaging script and Info.plist template to produce a .app bundle from the SwiftPM build.

## Acceptance Criteria

- scripts/build-app.sh builds release binary and creates Calliope.app under dist/\n- App bundle includes Contents/MacOS/Calliope and Info.plist with NSMicrophoneUsageDescription\n- Script exits non-zero on failure and prints bundle path on success

