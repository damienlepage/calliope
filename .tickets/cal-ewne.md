---
id: cal-ewne
status: closed
deps: []
links: []
created: 2026-02-06T15:52:18Z
type: task
priority: 2
assignee: dlepage
---
# G6: Add app icon asset + bundle metadata

Add a bundled app icon placeholder and required Info.plist metadata so the app bundle looks release-ready in Finder.

## Acceptance Criteria

- scripts/app/AppIcon.icns exists and is included in the app bundle resources.\n- scripts/app/Info.plist includes CFBundleIconFile and LSApplicationCategoryType (and keeps existing keys).\n- scripts/build-app.sh copies AppIcon.icns into Contents/Resources and errors if missing.\n- Tests updated/added to cover the new metadata.

