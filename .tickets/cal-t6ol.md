---
id: cal-t6ol
status: closed
deps: []
links: []
created: 2026-02-06T07:03:45Z
type: task
priority: 2
assignee: dlepage
tags: [ui, ux, session]
---
# Session idle view: keep only prompt + Start

Align idle session screen with PRD minimal state.

## Acceptance Criteria

- When isRecording is false and status is idle, Session view does not show the app title or status indicators; only the idle prompt and Start button remain visible.\n- When recording or error, title/status may appear as before.\n- SessionViewState tests cover the new visibility rule.

