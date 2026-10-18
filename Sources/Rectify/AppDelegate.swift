import AppKit
import RectifyCore

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem!
    private let snapController = SnapController()
    private var trustTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = MenuBarIcon.make()
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu

        HotKeyCenter.shared.registerDefaults()
        snapController.start()

        if !Permissions.isTrusted {
            Permissions.request()
            // Refresh the menu icon once access is granted.
            trustTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] timer in
                guard Permissions.isTrusted else { return }
                timer.invalidate()
                self?.updateIcon()
            }
        }
        updateIcon()
    }

    private func updateIcon() {
        statusItem.button?.appearsDisabled = !Permissions.isTrusted
    }

    // Rebuilt on every open so checkmarks and permission state are current.
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        if !Permissions.isTrusted {
            menu.addItem(item("⚠︎ Grant Accessibility Access…", #selector(grantAccess)))
            menu.addItem(.separator())
        }

        for (i, group) in WindowAction.menuGroups.enumerated() {
            if i > 0 { menu.addItem(.separator()) }
            for action in group {
                let mi = item(action.title, #selector(runAction(_:)))
                mi.representedObject = action.rawValue
                if let s = action.defaultShortcut {
                    mi.keyEquivalent = s.keyEquivalent
                    mi.keyEquivalentModifierMask = s.modifierMask
                }
                menu.addItem(mi)
            }
        }

        menu.addItem(.separator())
        let snap = item("Snap Windows by Dragging", #selector(toggleSnap))
        snap.state = Preferences.snapEnabled ? .on : .off
        menu.addItem(snap)

        let gapsItem = NSMenuItem(title: "Gaps Between Windows", action: nil, keyEquivalent: "")
        let gaps = NSMenu()
        for value in [0, 4, 8, 12, 16, 24] {
            let g = item(value == 0 ? "None" : "\(value) pt", #selector(setGap(_:)))
            g.tag = value
            g.state = Preferences.gap == value ? .on : .off
            gaps.addItem(g)
        }
        gapsItem.submenu = gaps
        menu.addItem(gapsItem)

        let login = item("Launch at Login", #selector(toggleLogin))
        login.state = Preferences.launchAtLogin ? .on : .off
        menu.addItem(login)

        if !HotKeyCenter.shared.failed.isEmpty {
            let names = HotKeyCenter.shared.failed.map(\.title).joined(separator: ", ")
            let warn = NSMenuItem(title: "Shortcuts in use elsewhere: \(names)", action: nil, keyEquivalent: "")
            warn.isEnabled = false
            menu.addItem(warn)
        }

        menu.addItem(.separator())
        menu.addItem(item("About Rectify", #selector(about)))
        menu.addItem(item("Quit Rectify", #selector(quit)))
    }

    private func item(_ title: String, _ action: Selector) -> NSMenuItem {
        let mi = NSMenuItem(title: title, action: action, keyEquivalent: "")
        mi.target = self
        return mi
    }

    @objc private func runAction(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String, let action = WindowAction(rawValue: raw) else { return }
        // Let the menu close and focus return to the target window first.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { WindowManager.shared.perform(action) }
    }

    @objc private func grantAccess() {
        Permissions.request()
        Permissions.openSettings()
    }

    @objc private func toggleSnap() { Preferences.snapEnabled.toggle() }
    @objc private func setGap(_ sender: NSMenuItem) { Preferences.gap = sender.tag }
    @objc private func toggleLogin() { Preferences.launchAtLogin.toggle() }

    @objc private func about() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(options: [
            .credits: NSAttributedString(string: "Keyboard and drag-to-snap window management.")
        ])
    }

    @objc private func quit() { NSApp.terminate(nil) }
}
