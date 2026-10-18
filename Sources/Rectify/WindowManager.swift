import AppKit
import RectifyCore

/// Executes window actions on real windows: cycling, restore and display moves.
final class WindowManager {
    static let shared = WindowManager()

    private var restoreFrames: [AXWindow: CGRect] = [:]
    private var last: (window: AXWindow, action: WindowAction, frame: CGRect, step: Int)?

    var gap: CGFloat { CGFloat(Preferences.gap) }

    /// Keyboard / menu entry point: acts on the focused window.
    func perform(_ action: WindowAction) {
        guard Permissions.isTrusted else { Permissions.request(); return }
        guard let window = AXWindow.focused(), let current = window.frame else {
            NSSound.beep()
            return
        }
        apply(action, to: window, current: current)
    }

    /// `allowCycling` is off for drag-snapping, which always lands on step 0.
    func apply(_ action: WindowAction, to window: AXWindow, current: CGRect, allowCycling: Bool = true) {
        guard let display = Displays.containing(current) else { return }
        let target: CGRect?
        var step = 0

        switch action {
        case .restore:
            guard let saved = restoreFrames.removeValue(forKey: window) else { NSSound.beep(); return }
            window.setFrame(saved)
            last = nil
            return

        case .nextDisplay, .previousDisplay:
            let displays = Displays.all
            guard displays.count > 1, let i = displays.firstIndex(of: display) else { NSSound.beep(); return }
            let offset = action == .nextDisplay ? 1 : -1
            let dest = displays[(i + offset + displays.count) % displays.count]
            target = Layout.move(current, from: display.axVisibleFrame, to: dest.axVisibleFrame)

        default:
            if allowCycling, let last, last.window == window, last.action == action,
               last.frame.isClose(to: current) {
                step = last.step + 1
            }
            target = Layout.frame(for: action, in: display.axVisibleFrame,
                                  current: current, step: step, gap: gap)
        }

        guard let target else { return }
        if restoreFrames[window] == nil { restoreFrames[window] = current }
        window.setFrame(target)
        // Remember what the app actually accepted (it may enforce a min size),
        // so the next press of the same shortcut is recognised as a repeat.
        last = (window, action, window.frame ?? target, step)
    }

    /// Remembers a pre-snap frame (used by drag snapping).
    func rememberRestoreFrame(_ frame: CGRect, for window: AXWindow) {
        if restoreFrames[window] == nil { restoreFrames[window] = frame }
    }
}
