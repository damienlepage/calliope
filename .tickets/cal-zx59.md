---
id: cal-zx59
status: closed
deps: []
links: []
created: 2026-02-07T19:15:00Z
type: task
priority: 1
assignee: dlepage
---
# Ensure live feedback panel includes captions and coaching profile

Live feedback should surface all glanceable metrics in the main feedback panel, including live captions and the active coaching profile.

## Acceptance Criteria

- Feedback panel includes a live captions section with a visible CC toggle and default-on captions.
- Feedback panel includes the active coaching profile (label or picker) while recording.
- Session view remains scroll-free at default window size.
- Tests updated or added for the new feedback panel inputs.

## Notes

**2026-02-07T19:22:00Z**

Moved live captions + coaching profile picker/label into the feedback panel, kept CC toggle default-on, and added FeedbackPanelTests coverage. Session view stays scroll-free with existing layout constraints. Closed ticket.
