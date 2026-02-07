# Release QA Reports

Store completed release QA reports in this folder. Create a new report by running:

```bash
./scripts/new-release-qa-report.sh
```

The script copies `RELEASE_QA_TEMPLATE.md` into `release/QA-YYYY-MM-DD.md` for the
current date. Fill in the results, especially the per-version packaged app
verification table, and keep the report alongside release notes.

To prefill the report with machine metadata (macOS version, hardware model, and
CPU arch) and pull the packaged app version/build if `dist/Calliope.app` exists,
run:

```bash
./scripts/packaged-app-qa-preflight.sh
```

For external testers, see `release/QA_HANDOFF.md` for a step-by-step packaged
app verification guide.

After verifying a packaged app on a specific macOS version, update the
per-version table row with the helper below (defaults to the latest QA report
in `release/`):

```bash
./scripts/packaged-app-qa-update-row.sh "macOS 14 (Sonoma)" "Apple Silicon, MacBookPro18,3" "Yes" "Yes" "Yes" "Yes" "Notes"
```
