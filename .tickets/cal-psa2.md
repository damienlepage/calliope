---
id: cal-psa2
status: closed
deps: []
links: []
created: 2026-02-07T20:16:00Z
type: task
priority: 1
assignee: dlepage
tags: [session, capture, reliability]
---
# G33: Session recovery guidance for capture failures

Provide clear in-session messaging and recovery actions when capture fails or mic input drops mid-session.

## Acceptance Criteria

- When capture fails to start or drops during a session, show a prominent in-session banner/state describing the issue in plain language.
- Provide a primary recovery action that retries capture and a secondary action that opens Settings to mic/capture diagnostics.
- If input level is silent for a configurable threshold while recording, surface a "No mic input detected" message with guidance.
- Recovery UI is visible only while impacted; it clears automatically once capture resumes.
- Unit tests cover the capture failure state, retry intent, and auto-clear behavior.
- No new dependencies.

## Notes

Prefer reusing existing capture diagnostics state if already tracked by the session coordinator.
