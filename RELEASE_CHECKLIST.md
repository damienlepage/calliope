# Release Candidate Checklist

This checklist is for validating a release candidate before packaging or distribution.
It focuses on core functionality, privacy guarantees, and build artifacts.
Record results in `RELEASE_QA_TEMPLATE.md` for each release candidate.

## Build & Run
1. `swift build` succeeds without warnings that block release.
2. `swift run` launches the app and defaults to the Session screen.
3. App window renders correctly at first launch with no missing assets.

## Permissions Flow
1. Fresh install: Microphone permission prompt appears on first Start.
2. Deny mic permission: Session remains idle; Settings shows recovery actions.
3. Grant mic permission: Session can start and shows live input level.
4. Speech recognition permission status is shown in Settings and gating works.

## Session Lifecycle
1. Start a session and confirm status text updates to Recording.
2. Stop a session and confirm the post-session recap appears.
3. Optional session title prompt appears after Stop and can be saved.
4. Active coaching profile label is visible and updates if changed mid-session.

## Live Feedback
1. Pace, crutch words, and pauses update while speaking.
2. Input level is responsive to your voice.
3. Warnings appear for high latency or risky audio routes when applicable.
4. Feedback panel remains minimal and calm (no settings/permissions controls).

## PRD Acceptance
1. Complete the PRD Acceptance Checklist in `RELEASE_QA_TEMPLATE.md`.
2. Confirm success metrics are met and record any deviations.

## Recordings & Playback
1. A recording appears in the Recordings list after Stop.
2. Open the recording detail sheet and verify stats are populated.
3. Playback works and audio sounds like only the local speaker.
4. Reveal/Open Folder action shows the recording in Finder.

## Diagnostics Export
1. Use Settings > Export Diagnostics.
2. Verify JSON file is created under the diagnostics folder.
3. Open the file and confirm it contains no audio or transcript data.

## Packaging & Artifacts
1. `./scripts/build-app.sh` produces `dist/Calliope.app`.
2. `./scripts/package-release.sh` produces `dist/Calliope.app` and a versioned zip.
3. If signing is enabled, verify the signing identity is applied to the app bundle.
4. Launch the packaged app from `dist/Calliope.app` on each supported macOS version and confirm it opens without Gatekeeper warnings (beyond expected first-run verification).

## Packaged App Verification (Supported macOS Versions)
Fill one line per macOS version tested.

| macOS Version | Machine | Launches | Permissions Prompt | Session Start/Stop | Recordings Flow | Notes |
| --- | --- | --- | --- | --- | --- | --- |
|  |  | Pass/Fail | Pass/Fail | Pass/Fail | Pass/Fail |  |
|  |  | Pass/Fail | Pass/Fail | Pass/Fail | Pass/Fail |  |

## Packaged App Flow Checklist
Run these steps in the packaged app on each supported macOS version.
1. Launch `dist/Calliope.app` and confirm it defaults to the Session screen.
2. Start a session and confirm the microphone permission prompt appears if not previously granted.
3. Confirm Session start/stop works and the post-session recap appears.
4. Confirm a recording appears in the Recordings view and playback works.

## Notarization & Signing Reminders
1. Notarization is required for distribution outside the App Store.
2. Ensure the app bundle is signed with a Developer ID Application certificate.
3. If notarized, staple the ticket to `dist/Calliope.app`.

## Privacy Confirmation
- No audio or transcripts leave the device at any point in the flow above.
- Calliope only monitors the local microphone input and does not capture other participants.
