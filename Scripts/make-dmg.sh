#!/bin/bash
# Builds build/Rectify-<version>.dmg: open it, drag Rectify onto Applications.
# Uses only built-in macOS tools (hdiutil, tiffutil, osascript).
# The first run asks permission for the terminal to control Finder; that's
# what lays out the window. Without it the DMG still works, just unstyled.
set -euo pipefail
cd "$(dirname "$0")/.."

./build.sh
VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" Resources/Info.plist)
VOLNAME="Rectify"
DMG="build/Rectify-$VERSION.dmg"
STAGE="build/dmg-stage"
RW="build/rectify-rw.dmg"

# Regenerate the background if it's missing, then merge @1x/@2x for Retina.
[ -f Resources/dmg/background.png ] || swift Scripts/make-dmg-background.swift

rm -rf "$STAGE" "$RW" "$DMG"
mkdir -p "$STAGE/.background"
cp -R build/Rectify.app "$STAGE/"
ln -s /Applications "$STAGE/Applications"
tiffutil -cathidpicheck Resources/dmg/background.png Resources/dmg/background@2x.png \
  -out "$STAGE/.background/background.tiff" 2>/dev/null

# Eject a stale volume with the same name, if any.
[ -d "/Volumes/$VOLNAME" ] && hdiutil detach "/Volumes/$VOLNAME" -quiet || true

hdiutil create -quiet -srcfolder "$STAGE" -volname "$VOLNAME" -fs HFS+ \
  -format UDRW -size 60m "$RW"
DEVICE=$(hdiutil attach -readwrite -noverify -noautoopen "$RW" | awk '/Apple_HFS/ {print $1}')
sleep 1

# Window: 600x400 content, icons 128px, app left, Applications right.
osascript <<EOF || echo "Finder layout skipped (no automation permission)"
tell application "Finder"
  tell disk "$VOLNAME"
    open
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set the bounds of container window to {200, 120, 800, 548}
    set opts to the icon view options of container window
    set arrangement of opts to not arranged
    set icon size of opts to 128
    set text size of opts to 13
    set background picture of opts to file ".background:background.tiff"
    set position of item "Rectify.app" of container window to {150, 200}
    set position of item "Applications" of container window to {450, 200}
    update without registering applications
    delay 1
    close
  end tell
end tell
EOF

# Volume icon = app icon.
cp Resources/AppIcon.icns "/Volumes/$VOLNAME/.VolumeIcon.icns"
SetFile -a C "/Volumes/$VOLNAME" 2>/dev/null || xattr -wx com.apple.FinderInfo \
  "0000000000000000040000000000000000000000000000000000000000000000" "/Volumes/$VOLNAME"

chmod -Rf go-w "/Volumes/$VOLNAME" || true
sync
hdiutil detach "$DEVICE" -quiet
hdiutil convert "$RW" -quiet -format UDZO -imagekey zlib-level=9 -o "$DMG"
rm -rf "$RW" "$STAGE"
echo "Built $DMG"
