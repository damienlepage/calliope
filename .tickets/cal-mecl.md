---
id: cal-mecl
status: closed
deps: []
links: []
created: 2026-02-07T01:54:40Z
type: feature
priority: 1
assignee: dlepage
tags: [ui, recordings]
---
# Post-session review model and quick-action data

Create a small post-session review model that selects the primary recording from a CompletedRecordingSession and exposes summary + quick-action targets for the session screen.

## Acceptance Criteria

- A new post-session review struct/view-model selects a primary recording (longest duration; falls back sensibly when duration missing).
- The model exposes summary strings (pace/crutch/pause/speaking) and a recording URL for quick actions.
- ContentView populates and clears the post-session review state when a session completes or the prompt is dismissed.
- Missing summary data is handled with a clear fallback message (no crash).
- Unit tests cover selection logic and fallback behavior.

