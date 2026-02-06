---
id: cal-fz9u
status: closed
deps: []
links: []
created: 2026-02-06T06:24:16Z
type: task
priority: 2
assignee: dlepage
---
# Add waiting-for-speech coverage

Expand LiveFeedbackViewModel tests to cover waiting-for-speech timer behavior so real-time feedback UI signals when no feedback arrives.

## Acceptance Criteria

- New test asserts showWaitingForSpeech becomes true after staleFeedbackDelay while recording and no feedback events\n- New test asserts showWaitingForSpeech resets to false when feedback arrives\n- Tests pass

