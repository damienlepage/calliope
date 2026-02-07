#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd "${script_dir}/.." && pwd)

release_dir="${repo_root}/release"
qa_report_path="${1:-}"

if [[ -z "${qa_report_path}" ]]; then
  qa_report_path=$(ls "${release_dir}"/QA-*.md 2>/dev/null | sort | tail -n 1 || true)
fi

if [[ -z "${qa_report_path}" ]]; then
  echo "No release QA report found. Run ./scripts/new-release-qa-report.sh first." >&2
  exit 1
fi

if [[ ! -f "${qa_report_path}" ]]; then
  echo "Release QA report not found at ${qa_report_path}" >&2
  exit 1
fi

macos_version=$(sw_vers -productVersion)
hardware_model=$(sysctl -n hw.model 2>/dev/null || echo "Unknown")
arch=$(uname -m)

cpu_label="${arch}"
case "${arch}" in
  arm64)
    cpu_label="Apple Silicon (${arch})"
    ;;
  x86_64)
    cpu_label="Intel (${arch})"
    ;;
  *)
    cpu_label="${arch}"
    ;;
esac

hardware_summary="${cpu_label}, ${hardware_model}"

app_path="${repo_root}/dist/Calliope.app"
info_plist="${app_path}/Contents/Info.plist"
app_version_summary="Not run (dist/Calliope.app missing)"

if [[ -f "${info_plist}" ]]; then
  short_version=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "${info_plist}" 2>/dev/null || true)
  build_version=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "${info_plist}" 2>/dev/null || true)

  if [[ -n "${short_version}" && -n "${build_version}" ]]; then
    app_version_summary="${short_version} (${build_version})"
  elif [[ -n "${short_version}" ]]; then
    app_version_summary="${short_version}"
  fi
fi

python3 - "${qa_report_path}" "${macos_version}" "${hardware_summary}" "${app_version_summary}" <<'PY'
import re
import sys

path = sys.argv[1]
macos_version = sys.argv[2]
hardware_summary = sys.argv[3]
app_version_summary = sys.argv[4]

with open(path, "r", encoding="utf-8") as handle:
    contents = handle.read()

replacements = {
    r"^- Calliope version/build:.*$": f"- Calliope version/build: {app_version_summary}",
    r"^- macOS version:.*$": f"- macOS version: {macos_version}",
    r"^- Hardware \(Apple Silicon/Intel \+ model\):.*$": f"- Hardware (Apple Silicon/Intel + model): {hardware_summary}",
}

for pattern, replacement in replacements.items():
    contents = re.sub(pattern, replacement, contents, flags=re.MULTILINE)

with open(path, "w", encoding="utf-8") as handle:
    handle.write(contents)
PY

printf 'Release QA report updated: %s\n' "${qa_report_path}"
printf 'macOS version: %s\n' "${macos_version}"
printf 'Hardware: %s\n' "${hardware_summary}"

if [[ -f "${info_plist}" ]]; then
  printf 'Calliope version/build: %s\n' "${app_version_summary}"
else
  printf 'Calliope version/build: %s\n' "${app_version_summary}"
  printf 'Reminder: build the app with ./scripts/build-app.sh or ./scripts/package-release.sh\n'
fi
