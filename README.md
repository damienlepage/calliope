# Calliope

A macOS app that acts as a real-time communication coach during conference calls.

## Features

- **Voice Isolation**: Records only your voice during conference calls (Google Meet, Zoom, Teams, etc.)
- **Real-time Feedback**: Visual cues for:
  - Voice pace/speed
  - Crutch word detection (uh, ah, so, etc.)
  - Pause analysis
- **Local Storage**: All recordings stored securely on your local file system
- **Privacy First**: Never records other participants' voices

## Privacy Notes

- Calliope only processes microphone input on-device and does not transmit audio or transcripts.
- Use headphones or a headset to avoid capturing other participants through speaker bleed.

## Conferencing Compatibility Notes

These steps help validate mic capture, ensure Calliope isolates your voice, and confirm your call audio is unaffected.

### Zoom

1. Join a Zoom call with a headset connected.
2. Start Calliope and begin a session while the call is live.
3. Confirm the Session screen shows a live input level and capture status while you speak.
4. Speak a few sentences; verify pace, crutch words, and pauses update in real time.
5. Ask another participant to speak while you stay silent; ensure Calliope does not register their speech and the input level remains near idle.
6. Verify the call audio sounds normal to others and that your Zoom mic behaves the same with Calliope running.

### Google Meet (Chrome)

1. Join a Google Meet call in Chrome with a headset connected.
2. Start Calliope and begin a session.
3. Confirm the input level moves only when you speak and that pace/pauses update.
4. Keep silent while another participant speaks; Calliope should stay idle.
5. Toggle Meet mute/unmute and confirm Calliope remains responsive to your microphone.

### Microsoft Teams

1. Join a Teams call with a headset connected.
2. Start Calliope and begin a session.
3. Confirm the Session screen input level and capture status update as you speak.
4. Speak briefly, then stay silent while another participant speaks; Calliope should not react to them.
5. Ask a participant to confirm your call audio is unaffected.

### Troubleshooting Tips

- Confirm microphone permission is granted in System Settings for Calliope.
- Verify the input device shown in the Session screen matches your active microphone.
- Use a headset to reduce speaker bleed and avoid capturing other participants.
- If levels are flat, quit and relaunch Calliope, then restart the call.
- If the call audio changes, check that no virtual audio device or system-wide audio enhancer is enabled.

## Conferencing Compatibility Verification Log

Use this template to capture compatibility checks for Zoom, Google Meet, and Microsoft Teams. Confirm that Calliope only tracks the local speaker and does not alter call audio.

```markdown
## Compatibility Check - <DATE>

- macOS version:
- Calliope version/build:
- Device model:
- Audio input device:
- Notes:

### Zoom

- Call audio unchanged:
- Calliope tracks only local speaker:
- Pace/crutch/pause updates while speaking:
- Observations:

### Google Meet (Chrome)

- Call audio unchanged:
- Calliope tracks only local speaker:
- Pace/crutch/pause updates while speaking:
- Observations:

### Microsoft Teams

- Call audio unchanged:
- Calliope tracks only local speaker:
- Pace/crutch/pause updates while speaking:
- Observations:
```

### Adding Future App IDs for Per-App Profiles

Per-app profiles are managed in Settings > Per-App Profiles. Add a new profile by entering the conferencing app bundle identifier (shown in Activity Monitor or System Settings), then customize pace, pause, and crutch-word targets. Example bundle IDs: `us.zoom.xos`, `com.microsoft.teams`, `com.google.Chrome`.

## Project Structure

```
Calliope/
├── Calliope/                    # Main app target
│   ├── App/                     # App entry point
│   ├── Audio/                   # Audio capture & processing
│   ├── Analysis/                # Speech analysis engines
│   ├── UI/                      # User interface
│   ├── Storage/                 # File management
│   └── Utils/                   # Utilities
└── README.md
```

## Technology Stack

- Swift/SwiftUI
- AVFoundation (audio capture)
- Speech framework (transcription)
- Core Audio (real-time processing)

## Supported macOS Versions

Calliope supports macOS 13 (Ventura) and later. For release verification, test the packaged app on the supported major versions:

- macOS 13 (Ventura)
- macOS 14 (Sonoma)
- macOS 15 (Sequoia)

## Development Status

🚧 In Development

## Building and Running

This project uses Swift Package Manager and can be developed entirely in Cursor (or any editor).

### Prerequisites

You need Xcode Command Line Tools (not the full Xcode app):
```bash
xcode-select --install
```

### Build from Terminal

```bash
# Build the project
swift build

# Run the app
swift run
```

## Testing

Use the provided scripts to run tests with local cache directories, which avoids permission issues in shared system cache locations.

```bash
# Run unit tests with local caches
./scripts/swift-test.sh

# Run tests with coverage enforcement (default 80% threshold)
./scripts/coverage.sh

# Optional: override the coverage threshold
COVERAGE_THRESHOLD=85 ./scripts/coverage.sh
```

## Release Checklist

Release validation steps are documented in `RELEASE_CHECKLIST.md`.
Use `RELEASE_QA_TEMPLATE.md` to capture release candidate QA results and user-facing notes.

### Development Workflow

1. **Write code in Cursor** - All source files are in `Sources/Calliope/`
2. **Build from terminal** - Use `swift build` to compile
3. **Run from terminal** - Use `swift run` to execute
4. **No Xcode GUI needed** - Everything can be done from Cursor + terminal

### Creating a macOS App Bundle

For a proper macOS app (with icon and bundle metadata), run:

```bash
./scripts/build-app.sh
```

The bundle will be created at `dist/Calliope.app`.

The code structure is designed to work with both SPM and Xcode projects.

### Packaging a Release Artifact

To generate a distributable app bundle and a versioned zip, run:

```bash
./scripts/package-release.sh
```

This creates `dist/Calliope.app` and a versioned zip in `dist/` (for example, `Calliope-1.0.0.zip`).

Optional code signing for distribution:

```bash
SIGNING_IDENTITY="Developer ID Application: Example Corp (TEAMID)" ./scripts/package-release.sh
```

If `SIGNING_ENTITLEMENTS` is not set, the packaging script will use `scripts/app/Calliope.entitlements` by default.
Override with:

```bash
SIGNING_IDENTITY="Developer ID Application: Example Corp (TEAMID)" \
SIGNING_ENTITLEMENTS="/path/to/Your.entitlements" \
./scripts/package-release.sh
```

### Optional Notarization (Release Only)

Notarization is optional and is not run by default. It is only required for distribution outside the App Store.

Short checklist:
1. Create an Apple Developer API key (Issuer ID, Key ID, and a `.p8` key file).
2. Ensure the app bundle is signed with a Developer ID Application certificate.
3. Submit the zip for notarization:
   ```bash
   xcrun notarytool submit dist/Calliope-<VERSION>.zip \
     --issuer "<ISSUER_ID>" \
     --key "<PATH_TO_P8>" \
     --key-id "<KEY_ID>" \
     --wait
   ```
4. Staple the ticket to the app:
   ```bash
   xcrun stapler staple dist/Calliope.app
   ```

These release steps do not change Calliope’s privacy posture: all audio and analysis remain on-device, and the app never transmits audio or transcripts.
