---
id: cal-xv2u
status: open
deps: []
links: []
created: 2026-02-07T01:33:24Z
type: feature
priority: 2
assignee: dlepage
tags: [audio, session, reliability]
---
# Add recovery actions for capture errors

Improve in-session recovery clarity when capture fails or input drops.

## Acceptance Criteria

- When AudioCapture status is error, Session view shows a short recovery hint and one relevant action (e.g., retry start or open Settings) based on the error.\n- Recovery messaging stays off the session screen when capture is healthy.\n- Unit tests cover error-to-action mapping.

