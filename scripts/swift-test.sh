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

mkdir -p "${MODULE_CACHE_DIR}" "${SWIFTPM_CACHE_DIR}" "${XDG_CACHE_DIR}" "${TMP_DIR}" "${SWIFTPM_CONFIG_DIR}" "${SWIFTPM_SECURITY_DIR}"

export HOME="${LOCAL_HOME}"
export CFFIXED_USER_HOME="${LOCAL_HOME}"
export TMPDIR="${TMP_DIR}"
export XDG_CACHE_HOME="${XDG_CACHE_DIR}"
export SWIFTPM_CACHE_PATH="${SWIFTPM_CACHE_DIR}"
export SWIFTPM_CONFIG_PATH="${SWIFTPM_CONFIG_DIR}"
export SWIFTPM_SECURITY_PATH="${SWIFTPM_SECURITY_DIR}"
export SWIFTPM_MODULECACHE_OVERRIDE="${MODULE_CACHE_DIR}"
export CLANG_MODULE_CACHE_PATH="${MODULE_CACHE_DIR}"

exec swift test --disable-sandbox \
  -Xcc -fmodules-cache-path="${MODULE_CACHE_DIR}" \
  -Xswiftc -module-cache-path \
  -Xswiftc "${MODULE_CACHE_DIR}" \
  "$@"
