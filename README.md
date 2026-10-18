# Rectify

A menu-bar window manager for macOS 14+. Keyboard tiling with size cycling,
drag-to-edge snapping with a live preview, gaps, display moves and restore.

## Build and run

```sh
swift test             # geometry + snap-zone unit tests
./build.sh             # -> build/Rectify.app
./build.sh --install   # also copies to /Applications (needed for Launch at Login)
open Package.swift     # to work on it in Xcode
```

First launch asks for **Accessibility** access (System Settings → Privacy &
Security → Accessibility). The build is ad-hoc signed, so macOS treats each
rebuild as a new app: remove the old Rectify entry and grant it again. To
avoid that, sign with a stable identity: `SIGN_IDENTITY="Apple Development: …" ./build.sh`.

Quit Rectangle / Rectangle Pro while using Rectify: they claim the same
shortcuts, and Rectify lists any shortcut it couldn't register in its menu.

## Shortcuts

| Action | Keys | Repeat to cycle |
|---|---|---|
| Left / Right half | ⌃⌥← / ⌃⌥→ | ½ → ⅔ → ⅓ |
| Top / Bottom half | ⌃⌥↑ / ⌃⌥↓ | ½ → ⅔ → ⅓ |
| Top-left, top-right, bottom-left, bottom-right | ⌃⌥U, I, J, K | |
| First, center, last third | ⌃⌥D, F, G | moves through the thirds |
| First / last two thirds | ⌃⌥E / ⌃⌥T | toggles |
| Fourths 1–4 | ⌃⌥⇧1 – 4 | moves through the fourths |
| Maximize | ⌃⌥↩ | |
| Maximize height | ⌃⌥⇧↑ | |
| Center | ⌃⌥C | |
| Larger / smaller | ⌃⌥= / ⌃⌥- | |
| Restore | ⌃⌥⌫ | |
| Next / previous display | ⌃⌥⌘→ / ⌃⌥⌘← | |

Center Half and Almost Maximize are in the menu without a shortcut.
Thirds and fourths become rows on portrait displays.

## Drag snapping

Drag a window by its title bar to:

- left / right edge → half
- top edge → maximize
- corners → quarter
- bottom edge → left, center or right third, depending on where you are

A translucent preview shows the result; release to apply. ⌃⌥⌫ restores the
pre-snap size. Toggle it under **Snap Windows by Dragging**.

## Layout

```
Sources/RectifyCore/   pure geometry (no AppKit), unit-tested
  WindowAction.swift   the action list
  Layout.swift         target frames, cycling, gaps, display moves
  SnapZones.swift      cursor position -> snap action
Sources/Rectify/       the app
  AXWindow.swift       Accessibility window access (get/set frame)
  Displays.swift       screens in Accessibility coordinates
  WindowManager.swift  runs actions: cycling, restore, displays
  HotKeys.swift        default shortcuts, Carbon hotkey registration
  SnapController.swift drag detection + preview window
  Preferences.swift    gaps, snapping, launch at login, permissions
  AppDelegate.swift    menu-bar menu
```

All geometry works in Accessibility coordinates (origin at the top-left of the
primary display, y down); `Displays.flip` converts to and from AppKit's.

## How this was made

Rectangle Pro was studied as a black box with REA: its bundle layout,
Info.plist, linked frameworks, preference keys and the names of the actions it
offers. That shaped the feature list. No Rectangle Pro code, assets or
artwork are used; everything here is written from scratch.

## Not yet built (ideas from Rectangle Pro)

Custom shortcut recording, sixths/eighths/ninths, saved app layouts,
window stashing, cursor-based "throw" moves, iCloud settings sync,
per-app ignore list, double-click title bar to maximize.
