---
id: cal-kv0b
status: open
deps: [cal-mecl]
links: []
created: 2026-02-07T01:54:45Z
type: feature
priority: 2
assignee: dlepage
tags: [ui]
---
# Session UI: post-session review card with quick actions

Add a post-session review card to the Session screen with immediate stats and quick actions without blocking the title prompt.

## Acceptance Criteria

- When a session ends, a post-session review card appears on the Session screen alongside the title prompt.
- The card shows key summary lines (pace/crutch/pause/speaking) or a fallback message when unavailable.
- Quick actions include View Recordings, Play/Pause, Reveal in Finder, and Details (or equivalent existing actions).
- Actions are disabled appropriately while recording.
- Visual treatment is calm and does not compete with the title prompt.
- Uses the post-session review model from cal-mecl.

