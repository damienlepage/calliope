---
id: cal-q9r2
status: closed
deps: []
links: []
created: 2026-02-05T20:10:00Z
type: task
priority: 2
assignee: dlepage
---
# MVP: Show grant-access button only when permission is undetermined

Limit the "Grant Microphone Access" action to the state where the system can still prompt the user.

## Acceptance Criteria

- The "Grant Microphone Access" button is visible only when microphone permission is not determined.
- When permission is denied or restricted, the grant button is hidden and only the System Settings action applies.
- Unit tests cover the visibility logic for all permission states.
- No network usage is introduced.

## Outcome
- Added `shouldShowGrantAccess` to `MicrophonePermissionState` and wired it into the UI.\n- Added unit tests for visibility across all permission states.
