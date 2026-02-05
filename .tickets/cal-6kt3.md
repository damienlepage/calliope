---
id: cal-6kt3
status: closed
deps: []
links: []
created: 2026-02-05T07:06:01Z
type: task
priority: 1
assignee: dlepage
---
# MVP: Add voice isolation capture backend

Introduce a voice-isolated microphone capture path so Calliope better filters out other participants during live calls while keeping audio strictly local.

## Acceptance Criteria

- Add a voice isolation capture backend that uses the platform voice processing/voice isolation path when available.
- Provide a user-facing preference to enable/disable voice isolation, persisted locally.
- Voice isolation is enabled by default when supported; when not supported, fall back to standard mic capture with a clear status message.
- Audio capture remains microphone-only and does not allow system audio input.
- Unit tests cover backend selection, preference persistence, and fallback behavior.

## Notes

- Keep CPU usage low; avoid additional dependencies.
- Ensure no network usage is introduced.

## Outcome
- Implemented voice isolation backend selection with a persisted preference and fallback to standard mic capture.
- UI exposes the voice isolation toggle with clear status messaging when unsupported.
- Tests cover backend selection, preference persistence, and fallback behavior.
