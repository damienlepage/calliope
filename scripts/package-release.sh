#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Calliope"
DIST_DIR="${ROOT_DIR}/dist"
APP_DIR="${DIST_DIR}/${APP_NAME}.app"
BUILD_SCRIPT="${ROOT_DIR}/scripts/build-app.sh"
INFO_TEMPLATE="${ROOT_DIR}/scripts/app/Info.plist"
DEFAULT_ENTITLEMENTS="${ROOT_DIR}/scripts/app/Calliope.entitlements"
SIGNING_IDENTITY="${SIGNING_IDENTITY:-}"
SIGNING_ENTITLEMENTS="${SIGNING_ENTITLEMENTS:-}"

if [[ ! -x "${BUILD_SCRIPT}" ]]; then
  echo "Missing build script at ${BUILD_SCRIPT}" >&2
  exit 1
fi

if [[ ! -f "${INFO_TEMPLATE}" ]]; then
  echo "Missing Info.plist template at ${INFO_TEMPLATE}" >&2
  exit 1
fi

"${BUILD_SCRIPT}"

if [[ ! -d "${APP_DIR}" ]]; then
  echo "App bundle not found at ${APP_DIR}" >&2
  exit 1
fi

if [[ -n "${SIGNING_IDENTITY}" ]]; then
  echo "Signing app bundle with identity: ${SIGNING_IDENTITY}"
  if [[ -z "${SIGNING_ENTITLEMENTS}" ]] && [[ -f "${DEFAULT_ENTITLEMENTS}" ]]; then
    SIGNING_ENTITLEMENTS="${DEFAULT_ENTITLEMENTS}"
  fi
  SIGNING_ARGS=(--force --options runtime --timestamp --sign "${SIGNING_IDENTITY}")
  if [[ -n "${SIGNING_ENTITLEMENTS}" ]]; then
    if [[ ! -f "${SIGNING_ENTITLEMENTS}" ]]; then
      echo "Signing entitlements not found at ${SIGNING_ENTITLEMENTS}" >&2
      exit 1
    fi
    SIGNING_ARGS+=(--entitlements "${SIGNING_ENTITLEMENTS}")
  fi
  /usr/bin/codesign --deep "${SIGNING_ARGS[@]}" "${APP_DIR}"
  /usr/bin/codesign --verify --deep --strict --verbose=2 "${APP_DIR}"
else
  echo "Skipping code signing (SIGNING_IDENTITY not set)"
fi

VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "${INFO_TEMPLATE}")
if [[ -z "${VERSION}" ]]; then
  echo "Unable to read version from ${INFO_TEMPLATE}" >&2
  exit 1
fi

ZIP_PATH="${DIST_DIR}/${APP_NAME}-${VERSION}.zip"
rm -f "${ZIP_PATH}"
/usr/bin/ditto -c -k --sequesterRsrc --keepParent "${APP_DIR}" "${ZIP_PATH}"

echo "Release bundle created at ${APP_DIR}"
echo "Release zip created at ${ZIP_PATH}"
