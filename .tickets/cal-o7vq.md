---
id: cal-o7vq
status: closed
deps: []
links: []
created: 2026-02-06T19:08:56Z
type: feature
priority: 1
assignee: dlepage
---
# G20: Apply per-app profiles based on frontmost app

Detect the frontmost app during recording, match it to stored per-app feedback profiles, and apply settings dynamically while surfacing the active profile in Session UI and overlay.

## Acceptance Criteria

- When recording, the app identifies the frontmost application bundle ID and resolves a matching per-app profile (or none).
- Active profile settings are applied to live analysis thresholds without requiring restart.
- Session view displays the active profile name or 'Default' while recording.
- Compact overlay mirrors the active profile state when visible.
- Unit coverage added for profile resolution + application logic.


## Notes

**2026-02-06T19:09:58Z**

Verified existing implementation: ActiveAnalysisPreferencesStore applies frontmost app profiles during recording; Session + overlay show active profile label with default fallback. Updated goals.yaml to AT_TARGET.
