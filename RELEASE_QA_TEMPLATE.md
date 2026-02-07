# Release QA Report Template

Use this template to record a release candidate QA run. Store completed reports alongside release notes.

## Release Metadata
- Date:
- Calliope version/build:
- macOS version:
- Hardware (Apple Silicon/Intel + model):
- Microphone device:
- Reviewer:

## Build & Run
- `swift build` succeeds
- `swift run` launches and defaults to Session screen
- First launch renders without missing assets

## Permissions Flow
- Microphone prompt appears on first Start
- Denied mic shows Settings recovery actions
- Granted mic enables session + input level
- Speech recognition status shows in Settings and gating works

## Session Lifecycle
- Start updates status to Recording
- Stop shows post-session recap
- Optional title prompt appears and saves
- Active coaching profile label updates during session

## Live Feedback
- Pace, crutch words, pauses update while speaking
- Input level is responsive
- Latency/risky audio warnings appear when triggered
- Feedback panel remains minimal and calm

## Recordings & Playback
- Recording appears after Stop
- Detail sheet shows stats
- Playback sounds like only the local speaker
- Reveal/Open Folder works

## Diagnostics Export
- Export generates JSON under diagnostics folder
- JSON contains no audio or transcript data

## Packaging & Artifacts
- `./scripts/build-app.sh` produces `dist/Calliope.app`
- `./scripts/package-release.sh` produces `dist/Calliope.app` + versioned zip
- Signing identity applied when configured

## Notarization & Signing
- Notarization submission command recorded (if applicable)
- Staple step completed (if applicable)

## Performance Validation
- Completed `PERFORMANCE_CHECKLIST.md` and attached results

## Privacy Confirmation
- No audio or transcripts leave the device
- Only the local microphone input is captured

## User-Facing Release Notes
### What Changed
- 

### Known Issues
- 

### Support / Contact
- 
