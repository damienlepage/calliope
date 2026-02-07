# Calliope PRD

## Summary
Calliope is a native macOS app that acts as a real-time communication coach during conference calls. It isolates the user’s voice and provides immediate, glanceable visual feedback on speaking pace, filler words, and pauses while keeping all audio and data local to the device. The app follows macOS Human Interface Guidelines so it feels calm, predictable, and at home alongside professional Mac apps.

## Goals
- Help users improve spoken clarity and confidence during live calls.
- Provide low-latency, real-time feedback without distracting the user.
- Preserve privacy by never recording other participants and keeping data local.

## Non-Goals
- Recording or transcribing other participants’ voices.
- Cloud storage, remote processing, or shared analytics.
- Post-production editing or detailed call analytics beyond what is listed in the requirements.
- Custom windowing systems, nonstandard overlays, or menubar-only UX in the initial release.

## Target Users
- Professionals who frequently present or lead meetings.
- Sales and customer-facing teams.
- Students and job seekers practicing interview communication.

## Use Cases
- Live coaching during Zoom/Google Meet/Teams calls.
- Practice runs for presentations with live feedback.
- Self-review of personal speaking habits over time using local recordings.

## Product & UX Principles
- Prefer macOS-native components and patterns over custom UI.
- Feedback must be glanceable and readable in under 500ms.
- One task per surface: live session, settings, and recordings are clearly separated.
- Respect macOS conventions for windows, navigation, settings, keyboard shortcuts, and accessibility.
- The UI should feel calm, focused, and non-intrusive during calls.

## Requirements

### Functional Requirements
1. Voice isolation that captures only the user’s voice during live calls.
2. Real-time visual cues for:
   - Speaking pace/speed.
   - Crutch word detection (e.g., “uh”, “ah”, “so”).
   - Pause analysis (effective frequency and duration).
3. Live feedback must show:
   - Elapsed time.
   - Speaking time.
   - Pace (WPM).
   - Crutch word count.
   - Pause indicator.
   - Input level meter.
   - Coaching profile.
4. Closed captions are captured on the fly, visible by default, and toggleable via a clearly visible CC control.
5. Local storage of recordings and analysis artifacts on the user’s file system.
6. Each session is saved with a default name including session date and start time.
7. Users can optionally add a title after clicking Stop (e.g. “1:1 with Alex”).
8. Session metadata and statistics are browsable and searchable.
9. For each session, record:
   - Number of times the user spoke.
   - Total duration of user speech.
10. Users can apply different coaching profiles per session, including:
    - Pace min/max.
    - Pause boundaries.
    - Crutch word list.
    - Speaking-time target.
11. Privacy safeguards ensuring other participants’ voices are not recorded.
12. Crutch word counts in live feedback must match post-session statistics.
13. WPM detection accuracy must closely align with actual speech.

### Non-Functional Requirements
1. Low-latency processing suitable for live feedback.
2. Reliable performance on typical macOS hardware (Apple Silicon and Intel).
3. Secure local storage with clear data ownership by the user.
4. Minimal CPU usage to avoid degrading call performance.
5. Built as a native macOS app using Swift/SwiftUI, AVFoundation, Speech, and Core Audio.
6. Audio capture must not interfere with conferencing app input/output; Calliope monitors the microphone in parallel without altering call audio.
7. Call quality for other participants must remain unchanged.
8. App must behave predictably when backgrounded, minimized, or reopened.

## UX Requirements

### Experience Principles
- Primary actions must be immediately visible without scrolling.
- Live session UI contains only session-relevant elements.
- Configuration and privacy settings belong exclusively in Settings.
- Use standard macOS components, layouts, and behaviors wherever possible.
- Feedback should be informative but never attention-grabbing.

### Information Architecture
- **Main Window**: Live session control and feedback only.
- **Settings Window**: All configuration, permissions, and privacy disclosures.
- **Recordings View/Window**: Browsing, playback, and management of past sessions.
- Privacy disclosures are shown at first launch and persist in Settings thereafter.

### Main Session Screen (Default)
- Prominent Start/Stop control with clear recording state.
- Fixed-layout live feedback panel that is clean, glanceable, and readable in under 500ms.
- Live feedback must show, at a glance:
  - Input level.
  - WPM count with a visual indicator and target zone.
  - Elapsed time.
  - Speaking time.
  - Pauses.
  - Crutch words.
  - Live captions.
  - Coaching profile.
- No scrolling at default window size.
- Minimal idle state:
  - Short friendly prompt.
  - Single primary CTA (Start Session).
- No settings, permissions, diagnostics, or recordings list visible.
- Closed captions are visible by default with a persistent CC toggle.
- Avoid charts, dense graphs, or multi-step interactions during a live session.

### Post-Session Behavior
- On Stop:
  - Immediately show summary statistics inline.
  - Prompt for optional session title using a macOS-style sheet.
  - Dismissing the sheet must not block access to stats.
- Naming a session is optional and never required to proceed.

### Settings & Permissions
- Presented in a dedicated macOS Settings window.
- Clean, grouped sections with user-facing language only.
- Only show the following controls:
  - Microphone access and preferred input.
  - Speech recognition permission state.
  - Coaching profiles.
  - Sensitivity preferences.
  - Pause detection boundaries:
    - Low boundary default: 1s.
    - High boundary default: 5s.
  - Crutch word list management.
  - Overlay preferences (if enabled).
  - Privacy disclosures and guardrails.
- Remove:
  - Zoom/Meet/Teams verification status.
  - Validation checklists.
  - Diagnostics or system health indicators.

### Recordings
- Accessible via a dedicated view or separate window.
- Never blocks or precedes the session start flow.
- Table-based layout using macOS table conventions.
- Columns:
  - Recording name/title (primary column).
  - Date.
  - Duration.
  - Speaking-time %.
- Supports:
  - Search.
  - Sorting by column headers.
- “Open Folder,” playback, and delete actions live only in this view.
- Detailed metadata is hidden behind a Details action.
- Recording details are shown in a modal or sheet with a clear Close button.

### Navigation & Behavior
- macOS-standard toolbar with a segmented control or sidebar for:
  - Session
  - Recordings
  - Settings
- App always defaults to Session on launch.
- Session uses the currently selected coaching profile by default.
- Coaching profile may be changed mid-session.
- Keyboard navigation and standard shortcuts must work as expected.

## Visual & Accessibility Requirements
- Use system font (SF Pro).
- Support Light and Dark Mode.
- Respect Dynamic Type and accessibility contrast settings.
- No information conveyed by color alone.
- Full VoiceOver support for live metrics and controls.

## Data & Privacy
- All audio and analysis remain on-device.
- No network transmission of audio or transcripts.
- Clear, explicit disclosure:
  > “Only your microphone input is analyzed. Other participants are never recorded.”

## Assumptions
- The app can access microphone and speech recognition permissions.
- Users are comfortable with local recording for self-improvement.
- Conference call audio routing allows monitoring the user’s microphone input.

## Out of Scope (Initial Release)
- Multi-user profiles or team dashboards.
- Cloud backup or cross-device sync.
- Advanced coaching such as sentiment or emotion analysis.
- Menubar-only or floating HUD-first experiences.

## Success Metrics
- User can start a session within 2 seconds of app launch.
- Live feedback is understandable without onboarding or documentation.
- Users describe the app as calm, non-distracting, and “feels native.”
- Low crash rate and stable real-time performance during calls.
