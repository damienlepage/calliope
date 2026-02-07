#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODULE_CACHE_DIR="${ROOT_DIR}/.build/module-cache"
SWIFTPM_CACHE_DIR="${ROOT_DIR}/.build/swiftpm-cache"
LOCAL_HOME="${ROOT_DIR}/.swift-test-home"
XDG_CACHE_DIR="${LOCAL_HOME}/.cache"
TMP_DIR="${LOCAL_HOME}/tmp"
SWIFTPM_CONFIG_DIR="${LOCAL_HOME}/.swiftpm/config"
SWIFTPM_SECURITY_DIR="${LOCAL_HOME}/.swiftpm/security"
BUILD_DIR="${ROOT_DIR}/.build"
DIST_DIR="${ROOT_DIR}/dist"
COVERAGE_THRESHOLD="${COVERAGE_THRESHOLD:-80}"
IGNORE_REGEX="Sources/Calliope/App/CalliopeApp\\.swift|Sources/Calliope/UI/(CompactFeedbackOverlay|ContentView|FeedbackPanel|InputLevelMeterView|PrivacyDisclosureSheet|RecordingsListView|RecordingsView|SessionView|SettingsView)\\.swift"

mkdir -p "${MODULE_CACHE_DIR}" "${SWIFTPM_CACHE_DIR}" "${XDG_CACHE_DIR}" "${TMP_DIR}" "${SWIFTPM_CONFIG_DIR}" "${SWIFTPM_SECURITY_DIR}" "${DIST_DIR}"

export HOME="${LOCAL_HOME}"
export CFFIXED_USER_HOME="${LOCAL_HOME}"
export TMPDIR="${TMP_DIR}"
export XDG_CACHE_HOME="${XDG_CACHE_DIR}"
export SWIFTPM_CACHE_PATH="${SWIFTPM_CACHE_DIR}"
export SWIFTPM_CONFIG_PATH="${SWIFTPM_CONFIG_DIR}"
export SWIFTPM_SECURITY_PATH="${SWIFTPM_SECURITY_DIR}"
export SWIFTPM_MODULECACHE_OVERRIDE="${MODULE_CACHE_DIR}"
export CLANG_MODULE_CACHE_PATH="${MODULE_CACHE_DIR}"

swift test --disable-sandbox --enable-code-coverage \
  -Xcc -fmodules-cache-path="${MODULE_CACHE_DIR}" \
  -Xswiftc -module-cache-path \
  -Xswiftc "${MODULE_CACHE_DIR}" \
  "$@"

profdata_path=""
if [[ -d "${BUILD_DIR}" ]]; then
  profdata_path=$(find "${BUILD_DIR}" -path "*codecov*" -name "*.profdata" -print -quit || true)
  if [[ -z "${profdata_path}" ]]; then
    profdata_path=$(find "${BUILD_DIR}" -name "*.profdata" -print -quit || true)
  fi
fi

if [[ -z "${profdata_path}" ]]; then
  echo "No .profdata coverage file found under ${BUILD_DIR}" >&2
  exit 1
fi

executables=()
while IFS= read -r -d '' bundle; do
  if [[ -d "${bundle}/Contents/MacOS" ]]; then
    exe=$(find "${bundle}/Contents/MacOS" -type f -maxdepth 1 -perm -111 -print -quit || true)
    if [[ -n "${exe}" ]]; then
      executables+=("${exe}")
      continue
    fi
  fi
  if [[ -f "${bundle}" ]]; then
    executables+=("${bundle}")
  fi
done < <(find "${BUILD_DIR}" -name "*.xctest" -print0)

if [[ ${#executables[@]} -eq 0 ]]; then
  echo "No test executables found under ${BUILD_DIR}" >&2
  exit 1
fi

report_path="${DIST_DIR}/coverage.txt"
coverage_report=$(xcrun llvm-cov report --ignore-filename-regex="${IGNORE_REGEX}" -instr-profile "${profdata_path}" "${executables[@]}")
line_coverage=$(printf "%s\n" "${coverage_report}" | awk '$1 == "TOTAL" {print $4}')
line_coverage="${line_coverage%\%}"

if [[ -z "${line_coverage}" ]]; then
  echo "Unable to determine line coverage percentage from llvm-cov report." >&2
  exit 1
fi

{
  echo "Coverage report generated at $(date '+%Y-%m-%d %H:%M:%S')"
  echo "Profile data: ${profdata_path}"
  echo "Ignored paths regex: ${IGNORE_REGEX}"
  echo "Line coverage: ${line_coverage}% (threshold ${COVERAGE_THRESHOLD}%)"
  echo ""
  printf "%s\n" "${coverage_report}"
} | tee "${report_path}"

if ! awk -v coverage="${line_coverage}" -v threshold="${COVERAGE_THRESHOLD}" 'BEGIN {exit (coverage + 0 < threshold + 0) ? 1 : 0}'; then
  echo "Line coverage ${line_coverage}% is below threshold ${COVERAGE_THRESHOLD}%." >&2
  exit 1
fi

echo "Wrote coverage report to ${report_path}"
