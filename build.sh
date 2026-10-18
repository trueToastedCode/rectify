#!/bin/bash
# Builds build/Rectify.app. Usage: ./build.sh [--install]
#   --install  also copies it to /Applications (needed for Launch at Login)
# Set SIGN_IDENTITY to a codesigning identity (e.g. "Apple Development: ...")
# so the Accessibility grant survives rebuilds; the default ad-hoc signature
# changes every build and macOS will ask again.
set -euo pipefail
cd "$(dirname "$0")"

swift build -c release
BIN="$(swift build -c release --show-bin-path)"

APP="build/Rectify.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN/Rectify" "$APP/Contents/MacOS/Rectify"
cp Resources/Info.plist "$APP/Contents/Info.plist"
[ -f Resources/AppIcon.icns ] && cp Resources/AppIcon.icns "$APP/Contents/Resources/"

codesign --force --options runtime --sign "${SIGN_IDENTITY:--}" "$APP"
echo "Built $APP"

if [[ "${1:-}" == "--install" ]]; then
  pkill -x Rectify 2>/dev/null || true
  rm -rf /Applications/Rectify.app
  cp -R "$APP" /Applications/
  echo "Installed /Applications/Rectify.app"
fi
