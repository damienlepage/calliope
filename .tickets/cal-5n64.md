---
id: cal-5n64
status: closed
deps: []
links: []
created: 2026-02-07T22:16:03Z
type: task
priority: 1
assignee: dlepage
tags: [audio, metrics]
---
# Speaking time stops only after long pause threshold

Keep speaking time increasing through short pauses; stop only when a pause exceeds the high threshold that counts as a turn-ending pause.

## Acceptance Criteria

- Speaking time continues to increment across short pauses.
- Speaking time stops increasing only when pause duration exceeds the high pause threshold.
- Add/adjust tests to lock behavior.

