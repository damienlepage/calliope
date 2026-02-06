---
id: cal-bo3w
status: closed
deps: []
links: []
created: 2026-02-06T16:24:46Z
type: task
priority: 2
assignee: dlepage
tags: [release, packaging]
---
# G6: Add default signing entitlements template

Provide a default entitlements template for release signing and wire it into the packaging script when SIGNING_IDENTITY is set.

## Acceptance Criteria

- Add scripts/app/Calliope.entitlements with a minimal dictionary suitable for hardened runtime signing\n- Update scripts/package-release.sh to use the default entitlements file when SIGNING_IDENTITY is set and SIGNING_ENTITLEMENTS is not provided\n- Extend ReleasePackagingScriptTests to assert the entitlements hook exists\n- Document default entitlements usage in README

