import AppKit
import ApplicationServices
import ServiceManagement

enum Preferences {
    private static let defaults = UserDefaults.standard

    static var gap: Int {
        get { defaults.integer(forKey: "gap") }
        set { defaults.set(newValue, forKey: "gap") }
    }

    static var snapEnabled: Bool {
        get { defaults.object(forKey: "snapEnabled") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "snapEnabled") }
    }

    static var launchAtLogin: Bool {
        get { SMAppService.mainApp.status == .enabled }
        set {
            do {
                if newValue { try SMAppService.mainApp.register() }
                else { try SMAppService.mainApp.unregister() }
            } catch {
                let alert = NSAlert()
                alert.messageText = "Couldn't change Launch at Login"
                alert.informativeText = "\(error.localizedDescription)\n\nMove Rectify to /Applications and try again."
                alert.runModal()
            }
        }
    }
}

enum Permissions {
    static var isTrusted: Bool { AXIsProcessTrusted() }

    /// Shows the system prompt that deep-links to Privacy & Security.
    static func request() {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        AXIsProcessTrustedWithOptions([key: true] as CFDictionary)
    }

    static func openSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}
