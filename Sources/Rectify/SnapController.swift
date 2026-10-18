import AppKit
import RectifyCore

/// Drag a window to a screen edge or corner, see a preview, release to snap.
final class SnapController {
    private var monitors: [Any] = []
    private let footprint = FootprintWindow()

    private var window: AXWindow?
    private var startFrame: CGRect?
    private var isMoving = false
    private var probes = 0
    private var pending: (action: WindowAction, display: Display)?

    func start() {
        let handlers: [(NSEvent.EventTypeMask, () -> Void)] = [
            (.leftMouseDown, { [weak self] in self?.mouseDown() }),
            (.leftMouseDragged, { [weak self] in self?.mouseDragged() }),
            (.leftMouseUp, { [weak self] in self?.mouseUp() })
        ]
        for (mask, handler) in handlers {
            if let m = NSEvent.addGlobalMonitorForEvents(matching: mask, handler: { _ in handler() }) {
                monitors.append(m)
            }
        }
    }

    private var cursor: CGPoint { Displays.flip(NSEvent.mouseLocation) }

    private func mouseDown() {
        reset()
        guard Preferences.snapEnabled, Permissions.isTrusted,
              let w = AXWindow.at(cursor), w.pid != getpid() else { return }
        window = w
        startFrame = w.frame
    }

    private func mouseDragged() {
        guard let window, let startFrame else { return }

        if !isMoving {
            // Only a drag that moves the window without resizing it is a
            // window move; text selection or edge-resizing is ignored.
            // Probe cheaply and give up after a while.
            probes += 1
            guard probes % 3 == 0 else { return }
            if probes > 45 { reset(); return }
            guard let f = window.frame else { return }
            if f.origin.distance(to: startFrame.origin) > 2 && f.size.isClose(to: startFrame.size) {
                isMoving = true
            } else { return }
        }

        let p = cursor
        guard let display = Displays.at(p),
              let action = SnapZones.action(at: p, in: display.axFrame) else {
            pending = nil
            footprint.hide()
            return
        }
        if pending?.action == action && pending?.display == display { return }
        pending = (action, display)
        if let rect = Layout.frame(for: action, in: display.axVisibleFrame, current: startFrame,
                                   gap: WindowManager.shared.gap) {
            footprint.show(axRect: rect)
        }
    }

    private func mouseUp() {
        defer { reset() }
        footprint.hide()
        guard isMoving, let window, let pending, let startFrame, let current = window.frame else { return }
        WindowManager.shared.rememberRestoreFrame(startFrame, for: window)
        // Let the app finish its own drag handling before we resize.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            WindowManager.shared.apply(pending.action, to: window, current: current, allowCycling: false)
        }
    }

    private func reset() {
        window = nil
        startFrame = nil
        isMoving = false
        probes = 0
        pending = nil
    }
}

private extension CGPoint {
    func distance(to o: CGPoint) -> CGFloat { hypot(x - o.x, y - o.y) }
}

private extension CGSize {
    func isClose(to o: CGSize) -> Bool { abs(width - o.width) < 2 && abs(height - o.height) < 2 }
}

/// Translucent preview of where the window will land.
final class FootprintWindow: NSPanel {
    convenience init() {
        self.init(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel],
                  backing: .buffered, defer: true)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        ignoresMouseEvents = true
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .transient, .ignoresCycle]
        isReleasedWhenClosed = false

        let view = NSVisualEffectView()
        view.material = .hudWindow
        view.blendingMode = .behindWindow
        view.state = .active
        view.wantsLayer = true
        view.layer?.cornerRadius = 12
        view.layer?.borderWidth = 2
        view.layer?.borderColor = NSColor.controlAccentColor.withAlphaComponent(0.7).cgColor
        contentView = view
    }

    func show(axRect: CGRect) {
        let frame = Displays.flip(axRect)
        if isVisible {
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.12
                animator().setFrame(frame, display: true)
            }
        } else {
            setFrame(frame, display: true)
            orderFrontRegardless()
        }
    }

    func hide() { orderOut(nil) }
}
