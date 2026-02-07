---
id: cal-psa1
status: closed
deps: []
links: []
created: 2026-02-07T20:15:00Z
type: task
priority: 2
assignee: dlepage
tags: [session, post-session, ux]
---
# G32: Post-session review summary + quick actions

Add a lightweight post-session review panel that appears immediately after Stop and does not block the optional title prompt.

## Acceptance Criteria

- After Stop, the session view shows a compact post-session summary panel with key stats (duration, speaking time, turns, pace avg, crutch count, pauses/min).
- The summary appears immediately and does not block the optional title prompt (title prompt still shows and can be dismissed without interacting with the summary).
- Summary panel includes quick actions: `Open Recording`, `Edit Title`, `Go to Recordings` (or equivalent), wired to existing navigation/flows.
- Summary panel is hidden while recording and resets on new session start.
- Unit tests cover the new summary state transitions and quick-action intents.
- No new dependencies.

## Notes

Create a minimal UI addition; prefer reusing existing session summary models if available.
