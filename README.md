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
