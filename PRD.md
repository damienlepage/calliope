# Calliope PRD

## Summary
Calliope is a macOS app that acts as a real-time communication coach during conference calls. It isolates the user’s voice and provides immediate, visual feedback on speaking pace, filler words, and pauses while keeping all audio and data local to the device.

## Goals
- Help users improve spoken clarity and confidence during live calls.
- Provide low-latency, real-time feedback without distracting the user.
- Preserve privacy by never recording other participants and keeping data local.

## Non-Goals
- Recording or transcribing other participants’ voices.
- Cloud storage, remote processing, or shared analytics.
- Post-production editing or detailed call analytics beyond core feedback.

## Target Users
- Professionals who frequently present or lead meetings.
- Sales and customer-facing teams.
- Students and job seekers practicing interview communication.

## Use Cases
- Live coaching during Zoom/Google Meet/Teams calls.
- Practice runs for presentations with live feedback.
- Self-review of personal speaking habits over time using local recordings.

## Requirements

### Functional Requirements
1. Voice isolation that captures only the user’s voice during live calls.
2. Real-time visual cues for:
   - Speaking pace/speed.
   - Crutch word detection (e.g., “uh”, “ah”, “so”).
   - Pause analysis (detect overly long or frequent pauses).
3. Local storage of recordings and analysis artifacts on the user’s file system.
4. Privacy safeguards ensuring other participants’ voices are not recorded.
5. Support for common conferencing tools running on macOS (Zoom, Google Meet, Teams, etc.).

### Non-Functional Requirements
1. Low-latency processing suitable for live feedback.
2. Reliable performance on typical macOS hardware (Apple Silicon and Intel).
3. Secure local storage with clear data ownership by the user.
4. Minimal CPU usage to avoid degrading call performance.
5. Works as a native macOS app using Swift/SwiftUI, AVFoundation, Speech, and Core Audio.

## UX Requirements
- Always-on-top or easily accessible overlay for visual cues.
- Visual indicators that are glanceable and non-intrusive.
- Clear start/stop control with status indicator.
- Simple preferences for sensitivity tuning (pace, crutch words, pause thresholds).

## Data & Privacy
- All audio and analysis remain on-device.
- No network transmission of audio or transcripts.
- Explicit disclosure that only the user’s voice is captured.

## Assumptions
- The app can access the microphone and audio input permissions.
- Users are comfortable with local recording for self-improvement.
- Conference call audio routing allows for isolating the user’s microphone input.

## Out of Scope (Initial Release)
- Multi-user profiles or team dashboards.
- Cloud backup or cross-device sync.
- Advanced coaching such as sentiment analysis or emotion detection.

## Success Metrics
- User-reported improvement in speaking clarity and confidence.
- Low crash rate and stable real-time performance during calls.
- High retention among users who take frequent calls.

## Open Questions
- What level of customization should be available for crutch word lists?
- Should feedback be configurable per app (Zoom vs. Meet vs. Teams)?
- How will we visualize pace and pauses to be effective yet unobtrusive?

## Ready Tickets
1. [DONE][P1] Define microphone capture pipeline baseline
Acceptance Criteria: App can start and stop a local-only microphone capture session; capture errors are surfaced in the UI status; unit tests cover start/stop and error propagation.
2. [DONE][P1] Wire live analysis outputs to UI feedback indicators
Acceptance Criteria: Pace, crutch word, and pause indicators update from live analysis stream; updates are throttled to avoid UI jank; unit tests validate mapping from analysis events to UI state.
3. [DONE][P2] Document and enforce privacy guardrails in capture settings
Acceptance Criteria: App settings UI clearly states local-only processing and user-only capture; code enforces microphone-only input path with no system audio capture; tests assert settings copy and enforcement.
4. [DONE][P2] Remove headset confirmation gate for recording eligibility
Acceptance Criteria: Recording eligibility no longer blocks on headset confirmation; UI removes headset confirmation toggle; tests cover updated eligibility and guardrail behavior.
5. [DONE][P1] Add sensitivity preferences for pace, pause, and crutch words
Acceptance Criteria: Preferences model persists pace min/max, pause threshold, and crutch word list locally; UI provides simple controls to edit these values; analysis uses stored preferences for pace, pause, and crutch word detection; defaults match current Constants values; unit tests cover defaults, persistence, and analyzer wiring.
6. [DONE][P2] Add always-on-top overlay toggle
Acceptance Criteria: User-facing toggle enables/disables always-on-top behavior; window level switches between floating and normal; toggle persists across launches; unit tests cover default and persistence.
7. [DONE][P2] Normalize crutch word input
Acceptance Criteria: Crutch word parsing trims whitespace, lowercases entries, deduplicates while preserving order; unit tests cover normalization behavior.
8. [DONE][P2] Sort recordings newest-first and ignore directories
Acceptance Criteria: Recording listing returns only `.m4a`/`.wav` files (no directories) ordered by most recent modification date; unit tests cover sorting and filtering.
9. [DONE][P1] Handle input device changes during recording
Acceptance Criteria: `AudioCapture` observes audio engine configuration changes; on change during recording it stops and surfaces a clear error instructing the user to press Start again; taps are removed and the app returns to a stable idle state; unit tests cover the configuration-change path.
10. [DONE][P2] First-launch privacy disclosure sheet
Acceptance Criteria: A non-dismissible modal sheet appears on first launch until the user accepts the disclosure; acceptance is persisted; the sheet does not reappear after acceptance; unit tests cover persistence and gating logic.
11. [DONE][P2] Add compact live feedback overlay
Acceptance Criteria: A compact overlay view shows pace/crutch/pause; visibility is controlled by a user-facing toggle and persists across launches; overlay respects the always-on-top preference; unit tests cover overlay preference persistence and show/hide behavior.
