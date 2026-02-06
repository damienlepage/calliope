# Calliope PRD

## Summary
Calliope is a macOS app that acts as a real-time communication coach during conference calls. It isolates the user’s voice and provides immediate, visual feedback on speaking pace, filler words, and pauses while keeping all audio and data local to the device, plus a browsable history of session metadata and speaking statistics.

## Goals
- Help users improve spoken clarity and confidence during live calls.
- Provide low-latency, real-time feedback without distracting the user.
- Preserve privacy by never recording other participants and keeping data local.

## Non-Goals
- Recording or transcribing other participants’ voices.
- Cloud storage, remote processing, or shared analytics.
- Post-production editing or detailed call analytics beyond core feedback beyond what is listed in the requirements.

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
4. Each session is saved with a default name that includes the session date and start time.
5. Users can optionally add a title after clicking Stop (e.g. “1:1 with Alex”).
6. Sessions metadata and statistics are easily browsable and searchable.
7. For each session, record how often the user spoke and the total duration of user speech.
8. Users can apply different coaching profiles per session (e.g., different speaking-time targets and sensitivity to crutch words/pauses).
9. Privacy safeguards ensuring other participants’ voices are not recorded.
10. Support for common conferencing tools running on macOS (Zoom, Google Meet, Teams, etc.).

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
- Recordings list supports search and basic metadata sorting (e.g., date, duration, speaking-time %).

### Navigation & Behavior
- Use a macOS-standard toolbar with a segmented control or sidebar for:
  - Session
  - Recordings
  - Settings
- Always default to Session when starting the app.
- All elements on the Session screen must have a purpose for the current session.
- Session creation uses the currently selected profile.
- The profile can still be changed after the Session started.
- After Stop, prompt for optional session title without blocking immediate access to stats.

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
- What is the minimum viable profile system (e.g., presets only vs. editable targets)?
