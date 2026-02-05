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
1. [DONE][P1] Add capture start timeout and user guidance
Acceptance Criteria: When the user taps Start, if the capture pipeline does not reach a running/recording state within 1 second, capture stops and the status UI shows a clear message to retry; timeout does not fire when capture starts successfully; unit tests cover timeout and success paths.
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
12. [DONE][P1] Add microphone permission preflight and UI messaging
Acceptance Criteria: Starting capture checks microphone permission status before starting the audio engine; if denied or restricted, the status UI shows a clear, actionable message and capture does not start; unit tests cover granted, denied, and restricted permission states with mocked authorization responses.
13. [DONE][P1] Add capture pipeline smoke test with local input audio
Acceptance Criteria: A test-only input path can inject a bundled mono WAV into `AudioCapture` without using the system audio graph; starting and stopping capture produces a local recording file with non-zero size; tests verify file creation and that the input path remains microphone-only in production builds.
14. [DONE][P2] Add recording management actions in recordings list
Acceptance Criteria: The recordings list supports reveal-in-Finder and delete actions for `.m4a`/`.wav` items; deletion removes the file locally and updates the list; unit tests cover delete behavior and list refresh.
15. [DONE][P2] Refresh recordings list after recording stops
Acceptance Criteria: When a recording session stops, the recordings list reloads so new files appear without relaunching; unit tests cover the reload trigger on recording stop.
16. [DONE][P2] Show recording duration and size in recordings list
Acceptance Criteria: The recordings list shows each file's duration and size alongside the modified date; metadata is loaded from local file data only; unit tests cover mapping of duration and size into recording items.
17. [DONE][P1] Add live input level indicator and silence warning
Acceptance Criteria: While capture is running, compute a lightweight input level from the user's microphone buffers and display a small level meter in the live feedback UI; if no meaningful input is detected for 5 seconds, surface a clear "No mic input detected" warning without stopping capture; updates are throttled to avoid UI jank; unit tests cover level mapping and silence timer behavior.
18. [DONE][P2] Persist per-recording analysis summary artifacts
Acceptance Criteria: When a recording stops, write a local JSON summary (pace stats, pause stats, crutch word counts) alongside the audio file; summaries are stored only on-device with no network usage; recording deletion also removes its summary; unit tests cover summary creation and deletion wiring.
19. [DONE][P1] Show active microphone device name and handle changes
Acceptance Criteria: The UI displays the current microphone input device name while recording; if the device changes during an active session, the capture stops with a clear message instructing the user to press Start again; the device name updates after the change; unit tests cover device name exposure and change handling.
20. [DONE][P2] Ignore zero-byte recordings in list
Acceptance Criteria: Recording listing ignores `.m4a`/`.wav` files with zero byte size; unit tests cover filtering out zero-byte files while keeping valid recordings.
21. [DONE][P1] Add end-to-end live analysis smoke test with bundled audio
Acceptance Criteria: Test-only analysis input path can inject a bundled mono WAV into the live analysis pipeline without using the system audio graph; the live feedback view model receives paced/crutch/pause updates that differ from defaults; tests assert updates are throttled and remain local-only with no network usage.
22. [DONE][P2] Add recordings folder shortcut
Acceptance Criteria: Recordings section includes an "Open Folder" action that reveals the local recordings directory; unit tests verify the recordings list view model requests the workspace to open the recordings directory; no network usage is introduced.
23. [DONE][P1] Add voice isolation capture backend
Acceptance Criteria: Add a voice isolation capture backend using the platform voice processing/voice isolation path; expose a user-facing preference to enable/disable and persist it locally; enable by default when supported with a clear fallback status when not supported; keep capture microphone-only and local; unit tests cover backend selection, preference persistence, and fallback behavior.
24. [DONE][P2] Add reset action for sensitivity preferences
Acceptance Criteria: A "Reset to Defaults" action restores pace, pause, and crutch word settings to default values; defaults persist across launches; unit tests cover reset behavior and persistence.
25. [DONE][P2] Show analysis summary stats in recordings list
Acceptance Criteria: Recording list items surface locally stored analysis summary stats (average pace, pause count, crutch word total) when a summary JSON exists; loading remains local-only with no network usage; unit tests cover summary loading and display text formatting.
26. [DONE][P2] Confirm before deleting recordings
Acceptance Criteria: Deleting a recording requires an explicit confirmation; canceling the prompt leaves recordings untouched; unit tests cover pending delete, confirm, and cancel behaviors.
27. [DONE][P1] Add in-app mic capture diagnostics
Acceptance Criteria: A "Test Mic" control runs a short (<=3s) local-only capture using the existing microphone pipeline without saving audio; the UI reports success/failure with a clear status message; the test auto-stops and returns the app to idle; unit tests cover success, failure, and auto-stop states with mocked capture behavior.
28. [DONE][P1] Show live session duration while recording
Acceptance Criteria: While recording, the main view and compact overlay show an elapsed time label in mm:ss; the timer updates once per second without adding noticeable CPU usage; stopping recording resets the timer and hides the label; unit tests cover formatting and timer start/stop with a controllable clock.
29. [DONE][P2] Surface pace guidance text alongside WPM
Acceptance Criteria: The feedback panel and compact overlay display a short text label ("Slow", "On Target", "Fast") derived from `PaceFeedback.level` next to the pace value; labels update with live feedback; unit tests cover mapping from pace values to label text.
30. [DONE][P2] Clarify Start disabled reasons for mic permission states
Acceptance Criteria: When Start is disabled due to microphone permission, the blocking reason text reflects whether permission is not determined, denied, or restricted with clear guidance; unit tests cover each permission state mapping.
31. [DONE][P2] Surface recording delete failures in the UI
Acceptance Criteria: If deleting a recording fails, the recordings section shows a clear local-only error message; successful deletes clear the error; unit tests cover the failure path.
32. [DONE][P2] Clear mic test status when recording starts
Acceptance Criteria: Starting a recording clears any prior mic test success/failure status so stale messages are not shown; unit tests cover the reset behavior.
33. [DONE][P1] Enforce on-device speech recognition only
Acceptance Criteria: `SpeechTranscriber` refuses to start when on-device recognition is unsupported; authorization is not requested when on-device recognition is unsupported; unit tests cover the on-device support gate.
