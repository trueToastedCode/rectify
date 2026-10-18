import AppKit
import ApplicationServices

/// A window of another app, reached through the Accessibility API.
struct AXWindow: Hashable {
    let element: AXUIElement

    static func == (a: AXWindow, b: AXWindow) -> Bool { CFEqual(a.element, b.element) }
    func hash(into hasher: inout Hasher) { hasher.combine(CFHash(element)) }

    /// The focused window of the frontmost app.
    static func focused() -> AXWindow? {
        guard let app = NSWorkspace.shared.frontmostApplication else { return nil }
        let axApp = AXUIElementCreateApplication(app.processIdentifier)
        guard let value = copy(axApp, kAXFocusedWindowAttribute) else { return nil }
        return AXWindow(element: value as! AXUIElement)
    }

    /// The window under a point (Accessibility coordinates).
    static func at(_ point: CGPoint) -> AXWindow? {
        var hit: AXUIElement?
        guard AXUIElementCopyElementAtPosition(AXUIElementCreateSystemWide(),
                                               Float(point.x), Float(point.y), &hit) == .success,
              var current = hit else { return nil }
        for _ in 0..<25 {
            if (copy(current, kAXRoleAttribute) as? String) == kAXWindowRole {
                return AXWindow(element: current)
            }
            if let window = copy(current, kAXWindowAttribute) {
                return AXWindow(element: window as! AXUIElement)
            }
            guard let parent = copy(current, kAXParentAttribute) else { return nil }
            current = parent as! AXUIElement
        }
        return nil
    }

    var pid: pid_t {
        var pid: pid_t = 0
        AXUIElementGetPid(element, &pid)
        return pid
    }

    var frame: CGRect? {
        guard let posValue = Self.copy(element, kAXPositionAttribute),
              let sizeValue = Self.copy(element, kAXSizeAttribute) else { return nil }
        var origin = CGPoint.zero, size = CGSize.zero
        AXValueGetValue(posValue as! AXValue, .cgPoint, &origin)
        AXValueGetValue(sizeValue as! AXValue, .cgSize, &size)
        return CGRect(origin: origin, size: size)
    }

    var isResizable: Bool {
        var settable: DarwinBoolean = false
        AXUIElementIsAttributeSettable(element, kAXSizeAttribute as CFString, &settable)
        return settable.boolValue
    }

    /// Size, then position, then size again: the first resize may be
    /// clamped by the old position near a screen edge.
    func setFrame(_ rect: CGRect) {
        let app = AXUIElementCreateApplication(pid)
        // Apps with "enhanced UI" on (often set by assistive tools) animate
        // and fight programmatic moves; switch it off for the duration.
        let enhancedKey = "AXEnhancedUserInterface" as CFString
        let enhanced = (Self.copy(app, enhancedKey as String) as? Bool) ?? false
        if enhanced { AXUIElementSetAttributeValue(app, enhancedKey, kCFBooleanFalse) }
        defer { if enhanced { AXUIElementSetAttributeValue(app, enhancedKey, kCFBooleanTrue) } }

        var size = rect.size, origin = rect.origin
        if isResizable, let v = AXValueCreate(.cgSize, &size) {
            AXUIElementSetAttributeValue(element, kAXSizeAttribute as CFString, v)
        }
        if let v = AXValueCreate(.cgPoint, &origin) {
            AXUIElementSetAttributeValue(element, kAXPositionAttribute as CFString, v)
        }
        if isResizable, let v = AXValueCreate(.cgSize, &size) {
            AXUIElementSetAttributeValue(element, kAXSizeAttribute as CFString, v)
        }
    }

    private static func copy(_ element: AXUIElement, _ attribute: String) -> CFTypeRef? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success else { return nil }
        return value
    }
}
