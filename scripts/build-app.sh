#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Calliope"
BUILD_DIR="${ROOT_DIR}/.build/release"
DIST_DIR="${ROOT_DIR}/dist"
APP_DIR="${DIST_DIR}/${APP_NAME}.app"
CONTENTS_DIR="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"
INFO_TEMPLATE="${ROOT_DIR}/scripts/app/Info.plist"
PKGINFO_TEMPLATE="${ROOT_DIR}/scripts/app/PkgInfo"
ICON_TEMPLATE="${ROOT_DIR}/scripts/app/AppIcon.icns"
MODULE_CACHE_DIR="${ROOT_DIR}/.build/module-cache"
SWIFTPM_CACHE_DIR="${ROOT_DIR}/.build/swiftpm-cache"
LOCAL_HOME="${ROOT_DIR}/.swift-build-home"
XDG_CACHE_DIR="${LOCAL_HOME}/.cache"
TMP_DIR="${LOCAL_HOME}/tmp"
SWIFTPM_CONFIG_DIR="${LOCAL_HOME}/.swiftpm/config"
SWIFTPM_SECURITY_DIR="${LOCAL_HOME}/.swiftpm/security"

if [[ ! -f "${INFO_TEMPLATE}" ]]; then
  echo "Missing Info.plist template at ${INFO_TEMPLATE}" >&2
  exit 1
fi

if [[ ! -f "${PKGINFO_TEMPLATE}" ]]; then
  echo "Missing PkgInfo template at ${PKGINFO_TEMPLATE}" >&2
  exit 1
fi

if [[ ! -f "${ICON_TEMPLATE}" ]]; then
  echo "Missing AppIcon.icns at ${ICON_TEMPLATE}" >&2
  exit 1
fi

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

swift build -c release --disable-sandbox --package-path "${ROOT_DIR}" \
  -Xcc -fmodules-cache-path="${MODULE_CACHE_DIR}" \
  -Xswiftc -module-cache-path \
  -Xswiftc "${MODULE_CACHE_DIR}"

if [[ ! -x "${BUILD_DIR}/${APP_NAME}" ]]; then
  echo "Release binary not found at ${BUILD_DIR}/${APP_NAME}" >&2
  exit 1
fi

rm -rf "${APP_DIR}"
mkdir -p "${MACOS_DIR}" "${RESOURCES_DIR}"

cp "${BUILD_DIR}/${APP_NAME}" "${MACOS_DIR}/${APP_NAME}"
cp "${INFO_TEMPLATE}" "${CONTENTS_DIR}/Info.plist"
cp "${PKGINFO_TEMPLATE}" "${CONTENTS_DIR}/PkgInfo"
cp "${ICON_TEMPLATE}" "${RESOURCES_DIR}/AppIcon.icns"

echo "App bundle created at ${APP_DIR}"
