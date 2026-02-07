# Release QA Reports

Store completed release QA reports in this folder. Create a new report by running:

```bash
./scripts/new-release-qa-report.sh
```

The script copies `RELEASE_QA_TEMPLATE.md` into `release/QA-YYYY-MM-DD.md` for the
current date. Fill in the results, especially the per-version packaged app
verification table, and keep the report alongside release notes.
