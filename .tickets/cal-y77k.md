---
id: cal-y77k
status: closed
deps: []
links: []
created: 2026-02-06T06:53:57Z
type: task
priority: 2
assignee: dlepage
tags: [ui, session, privacy]
---
# Session idle screen: keep only prompt and Start

Align Session idle state with PRD minimalism by removing non-essential status/device detail text when not recording and no error.

## Acceptance Criteria

- When not recording and no error state, the Session screen shows only the idle prompt and Start button (plus title if retained).\n- Device selection message and backend status are hidden while idle.\n- Error state still shows status messaging.\n- SessionViewState tests updated/added to cover the new idle visibility rules.

