---
id: cal-dzoy
status: closed
deps: []
links: []
created: 2026-02-07T00:59:45Z
type: feature
priority: 1
assignee: dlepage
tags: [privacy, session, ux]
---
# Enforce voice-isolation risk acknowledgment before recording

Block Start when voice isolation is unavailable and the audio route is flagged as risky (speaker bleed). Require explicit user acknowledgment to proceed, and remember it only for the current session.

## Acceptance Criteria

- When voice isolation is unavailable and route risk is true, Start is disabled until user acknowledges risk.\n- Acknowledgment is per session (reset after Stop or app relaunch).\n- UI copy makes clear other participants' voices might be captured.\n- Unit tests cover the gating logic.

