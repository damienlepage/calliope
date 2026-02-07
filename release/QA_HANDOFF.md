# Packaged App QA Handoff

Use this guide when verifying the packaged Calliope app on macOS 13/14/15. The
goal is to confirm the packaged app launches, permissions work, sessions record,
and recordings are stored locally. Store your results in a release QA report so
we can track each macOS version tested.

## What You Need

- A Mac running macOS 13 (Ventura), macOS 14 (Sonoma), or macOS 15 (Sequoia).
- The latest packaged app in `dist/Calliope.app` (or the versioned zip if
  provided).
- This repository checked out locally.

## Run the QA Preflight

From the repo root, run:

```bash
./scripts/packaged-app-qa-preflight.sh
```

This creates a new QA report (or updates the latest one) with machine metadata
and the packaged app version/build if `dist/Calliope.app` is present.

## Verify the Packaged App

1. Launch `dist/Calliope.app`.
2. Start a session and confirm microphone permission prompts behave correctly.
3. Speak for a few seconds, then stop the session.
4. Confirm the recording appears in Recordings and playback includes only your
   voice.
5. Confirm local storage works by revealing the recordings folder.
6. Confirm Settings shows the expected permissions state.

Use the Release QA report checklist in `release/` (created by the preflight
script) for the full set of checks.

## Record Your Results

Update the per-version packaged app verification row with the helper script.
Use the macOS version label that matches the table row in the QA report.

```bash
./scripts/packaged-app-qa-update-row.sh "macOS 14 (Sonoma)" "Apple Silicon, MacBookPro18,3" "Yes" "Yes" "Yes" "Yes" "Notes"
```

The arguments are:
- macOS version label
- machine description
- launches (Yes/No)
- permissions (Yes/No)
- session flow (Yes/No)
- recordings storage (Yes/No)
- notes

## Where to Store the Report

Save the completed QA report under `release/` (for example,
`release/QA-YYYY-MM-DD.md`). If a report already exists for the current date,
append your results there.

## Share Back

Send the completed QA report (or the updated row details) back to the release
owner so we can mark the macOS version as verified.
