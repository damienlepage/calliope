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
   - Pause analysis (detect effective frequency and duration of pauses).
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
### Experience Principles
- Primary actions must be immediately visible without scrolling.
- The main session screen should contain only session-relevant elements.
- Configuration and privacy settings belong in Settings, not the main flow.
- Respect macOS human interface patterns for navigation, Settings, and permissions.
- The UI should feel calm, focused, and delightful with minimal cognitive load.

### Information Architecture
- Main window contains the session control and live feedback only.
- Settings window contains all configuration and one-time permissions state.
- Recordings are accessible via a dedicated secondary view (tab/segmented control) or separate window, not on the default session screen.
- Privacy disclosures are shown at first launch and then live in Settings afterward.

### Main Session Screen (Default)
- Prominent Start/Stop control with clear status messaging.
- Live feedback panel (pace, crutch words, pauses, input level, elapsed time) while recording.
- Minimal idle state: a short, friendly prompt and a single primary CTA (Start).
- No settings, permissions, or recordings list visible by default.

### Settings & Permissions
- Microphone permission status shown in Settings after first grant.
- Permission recovery actions (Open System Settings, Grant Access when undetermined) live in Settings, not on the session screen.
- Privacy guardrails and preferences presented as grouped sections with concise copy.
- Sensitivity controls remain simple and discoverable, with Reset to Defaults.

### Recordings
- Recordings list lives in a separate view or window.
- Only show the recordings list on demand; never block or precede the session start flow.
- Keep “Open Folder,” playback, and delete actions in the recordings view.

### Navigation & Behavior
- Use a macOS-standard toolbar with a segmented control or sidebar for:
  - Session
  - Recordings
  - Settings
- Always default to Session when starting the app.
- All elements on the Session screen must have a purpose for the current session.

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
1. [DONE][P2] Show available microphone inputs in Settings
Acceptance Criteria: Settings displays the list of available microphone input device names and highlights the current default input; the list refreshes when devices connect/disconnect; when no inputs are available, the existing "No microphone input device detected" message remains; no network usage is introduced; unit tests cover list contents, default highlighting, and refresh behavior with a mocked provider.
1. [DONE][P2] Add quick link to System Settings for mic permission blocks
Acceptance Criteria: When Start is disabled due to denied or restricted microphone permission, the status UI presents a clear "Open System Settings" action; the action opens the system privacy microphone settings pane locally; the action is hidden when permission is granted or not determined; unit tests cover action visibility and invocation with a mocked settings opener; no network usage is introduced.
1. [DONE][P2] Refresh microphone permission when app becomes active
Acceptance Criteria: Microphone permission state refreshes when the app becomes active (e.g., after returning from System Settings); Start button availability updates accordingly; unit tests cover the refresh-on-activation path.
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
34. [DONE][P2] Clean up zero-byte recordings when capture fails to start
Acceptance Criteria: When recording fails before entering the recording state, any zero-byte recording file created for that attempt is removed; recordings that successfully start are unaffected; unit tests cover cleanup on engine start failure.
35. [DONE][P1] Guard Start when no microphone input device is available
Acceptance Criteria: If the system reports no available microphone input device, Start is disabled and the status UI shows a clear, actionable message to connect or enable a mic; when a device becomes available, Start re-enables automatically; unit tests cover unavailable and available device states with mocked device lists.
36. [DONE][P1] Reset live feedback state on start/stop to avoid stale indicators
Acceptance Criteria: Starting capture resets pace/crutch/pause indicators, input level, silence warnings, and elapsed timer to neutral defaults before first live updates; stopping capture clears the live feedback state and hides any warnings; unit tests cover reset behavior on start and stop paths.
37. [DONE][P2] Add local playback controls for recordings
Acceptance Criteria: Recordings list supports play/pause and stop for `.m4a`/`.wav` items using local-only playback; only one recording can play at a time; UI indicates which item is playing; stopping playback clears the indicator; unit tests cover play, pause, stop, and single-active-playback enforcement with local-only audio APIs.
38. [DONE][P1] Add capture start validation for real microphone input
Acceptance Criteria: When capture starts, verify within 2 seconds that input level crosses a minimal threshold and the recording file size grows above zero; if either check fails, stop capture and show a clear local-only status message instructing the user to retry or select another mic; successful starts do not show the error; unit tests cover success and failure paths with mocked level and file-size providers.
39. [DONE][P2] Stop playback during live recording
Acceptance Criteria: When a recording session starts, any active playback stops and the playing indicator clears; play/pause and stop controls are disabled while recording is active; controls re-enable when recording stops and the list still refreshes; unit tests cover playback stopping and recording state propagation; no network usage is introduced.
40. [DONE][P2] Show Grant Access only when permission is undetermined
Acceptance Criteria: The \"Grant Microphone Access\" action is visible only when microphone permission is not determined; when permission is denied or restricted, the grant action is hidden and only the System Settings action applies; unit tests cover the visibility logic for all permission states; no network usage is introduced.
41. [DONE][P2] Add Sound settings shortcut when no microphone is available
Acceptance Criteria: When Start is disabled because no microphone input device is available, the status UI shows an \"Open Sound Settings\" action; the action opens the system Sound input settings pane locally; the action is hidden when a microphone device is available or permission is blocking Start for other reasons; unit tests cover action visibility and invocation with a mocked settings opener; no network usage is introduced.
42. [DONE][P1] Surface stale live feedback while recording
Acceptance Criteria: When capture is running and no live analysis updates (pace/crutch/pause) have been received for 3 seconds, the live feedback UI shows a non-blocking \"Waiting for speech\" message; the message clears immediately after the next analysis update; stopping capture hides the message; updates are throttled to avoid UI jank; unit tests cover the timer start, reset on analysis update, and stop/reset behavior.
43. [DONE][P1] Add toolbar navigation for Session, Recordings, and Settings
Acceptance Criteria: The app uses a macOS toolbar segmented control to switch between Session, Recordings, and Settings; Session is the default on launch; the Session screen only shows live session controls and feedback; Recordings and Settings content is moved to their respective screens; unit tests cover the default navigation selection and section titles; no network usage is introduced.
44. [DONE][P2] Add idle session prompt and single primary CTA
Acceptance Criteria: When not recording, the Session screen shows a short friendly prompt and a single primary Start control; live feedback panels and recording-only indicators are hidden while idle; the idle state remains the default on app launch; unit tests cover idle-state visibility and that the Start control is present.
45. [DONE][P2] Show recordings summary in recordings header
Acceptance Criteria: Recordings header shows the count of recordings and total duration when available; when durations are missing, only the count is shown; summary hides when there are no recordings; unit tests cover summary text formatting for count-only and count-with-duration cases; no network usage is introduced.
46. [DONE][P2] Disable mic test when permission or input is missing
Acceptance Criteria: The "Test Mic" control is disabled when microphone permission is not authorized or no microphone input device is available; it remains enabled when permission is authorized and a microphone is present; unit tests cover eligibility logic; no network usage is introduced.
