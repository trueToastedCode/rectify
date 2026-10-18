import AppKit
import Carbon.HIToolbox
import RectifyCore

struct Shortcut {
    let keyCode: UInt32
    let carbonModifiers: UInt32

    /// For showing the shortcut in the menu.
    var keyEquivalent: String {
        switch Int(keyCode) {
        case kVK_LeftArrow: return String(UnicodeScalar(NSLeftArrowFunctionKey)!)
        case kVK_RightArrow: return String(UnicodeScalar(NSRightArrowFunctionKey)!)
        case kVK_UpArrow: return String(UnicodeScalar(NSUpArrowFunctionKey)!)
        case kVK_DownArrow: return String(UnicodeScalar(NSDownArrowFunctionKey)!)
        case kVK_Return: return "\r"
        case kVK_Delete: return "\u{8}"
        case kVK_ANSI_Minus: return "-"
        case kVK_ANSI_Equal: return "="
        default: return Self.letters[Int(keyCode)] ?? ""
        }
    }

    var modifierMask: NSEvent.ModifierFlags {
        var m: NSEvent.ModifierFlags = []
        if carbonModifiers & UInt32(controlKey) != 0 { m.insert(.control) }
        if carbonModifiers & UInt32(optionKey) != 0 { m.insert(.option) }
        if carbonModifiers & UInt32(cmdKey) != 0 { m.insert(.command) }
        if carbonModifiers & UInt32(shiftKey) != 0 { m.insert(.shift) }
        return m
    }

    private static let letters: [Int: String] = [
        kVK_ANSI_C: "c", kVK_ANSI_D: "d", kVK_ANSI_E: "e", kVK_ANSI_F: "f", kVK_ANSI_G: "g",
        kVK_ANSI_T: "t", kVK_ANSI_U: "u", kVK_ANSI_I: "i", kVK_ANSI_J: "j", kVK_ANSI_K: "k",
        kVK_ANSI_1: "1", kVK_ANSI_2: "2", kVK_ANSI_3: "3", kVK_ANSI_4: "4"
    ]
}

extension WindowAction {
    /// Default shortcuts: ⌃⌥ for tiling, ⌃⌥⌘ for displays.
    var defaultShortcut: Shortcut? {
        let co = UInt32(controlKey | optionKey)
        let cos = UInt32(controlKey | optionKey | shiftKey)
        let coc = UInt32(controlKey | optionKey | cmdKey)
        func s(_ key: Int, _ mods: UInt32) -> Shortcut { Shortcut(keyCode: UInt32(key), carbonModifiers: mods) }
        switch self {
        case .leftHalf: return s(kVK_LeftArrow, co)
        case .rightHalf: return s(kVK_RightArrow, co)
        case .topHalf: return s(kVK_UpArrow, co)
        case .bottomHalf: return s(kVK_DownArrow, co)
        case .topLeft: return s(kVK_ANSI_U, co)
        case .topRight: return s(kVK_ANSI_I, co)
        case .bottomLeft: return s(kVK_ANSI_J, co)
        case .bottomRight: return s(kVK_ANSI_K, co)
        case .firstThird: return s(kVK_ANSI_D, co)
        case .centerThird: return s(kVK_ANSI_F, co)
        case .lastThird: return s(kVK_ANSI_G, co)
        case .firstTwoThirds: return s(kVK_ANSI_E, co)
        case .lastTwoThirds: return s(kVK_ANSI_T, co)
        case .firstFourth: return s(kVK_ANSI_1, cos)
        case .secondFourth: return s(kVK_ANSI_2, cos)
        case .thirdFourth: return s(kVK_ANSI_3, cos)
        case .lastFourth: return s(kVK_ANSI_4, cos)
        case .maximize: return s(kVK_Return, co)
        case .maximizeHeight: return s(kVK_UpArrow, cos)
        case .center: return s(kVK_ANSI_C, co)
        case .larger: return s(kVK_ANSI_Equal, co)
        case .smaller: return s(kVK_ANSI_Minus, co)
        case .restore: return s(kVK_Delete, co)
        case .nextDisplay: return s(kVK_RightArrow, coc)
        case .previousDisplay: return s(kVK_LeftArrow, coc)
        case .centerHalf, .almostMaximize: return nil
        }
    }
}

/// System-wide hotkeys via Carbon's RegisterEventHotKey. Unlike an event tap,
/// this needs no Accessibility or Input Monitoring permission.
final class HotKeyCenter {
    static let shared = HotKeyCenter()

    private var refs: [EventHotKeyRef] = []
    private var handlers: [UInt32: () -> Void] = [:]
    private var handlerInstalled = false
    private(set) var failed: [WindowAction] = []

    func registerDefaults() {
        unregisterAll()
        for action in WindowAction.allCases {
            guard let shortcut = action.defaultShortcut else { continue }
            if !register(shortcut, handler: { WindowManager.shared.perform(action) }) {
                failed.append(action)   // usually: already taken by another app
            }
        }
    }

    func unregisterAll() {
        refs.forEach { UnregisterEventHotKey($0) }
        refs.removeAll()
        handlers.removeAll()
        failed.removeAll()
    }

    private func register(_ shortcut: Shortcut, handler: @escaping () -> Void) -> Bool {
        installHandlerIfNeeded()
        let id = UInt32(refs.count + 1)
        var ref: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: OSType(0x5243_5459), id: id) // 'RCTY'
        let status = RegisterEventHotKey(shortcut.keyCode, shortcut.carbonModifiers, hotKeyID,
                                         GetApplicationEventTarget(), 0, &ref)
        guard status == noErr, let ref else { return false }
        refs.append(ref)
        handlers[id] = handler
        return true
    }

    private func installHandlerIfNeeded() {
        guard !handlerInstalled else { return }
        handlerInstalled = true
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, event, _ in
            var hotKeyID = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID),
                              nil, MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID)
            HotKeyCenter.shared.handlers[hotKeyID.id]?()
            return noErr
        }, 1, &spec, nil, nil)
    }
}
