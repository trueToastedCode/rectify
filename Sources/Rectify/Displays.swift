import AppKit

/// A display with its frames converted to Accessibility coordinates
/// (top-left of the primary display, y down).
struct Display: Equatable {
    let axFrame: CGRect
    let axVisibleFrame: CGRect   // minus menu bar and Dock
}

enum Displays {
    private static var primaryHeight: CGFloat { NSScreen.screens.first?.frame.height ?? 0 }

    /// AppKit (bottom-left origin) <-> Accessibility (top-left origin).
    /// The flip is its own inverse, so one function serves both directions.
    static func flip(_ r: CGRect) -> CGRect {
        CGRect(x: r.minX, y: primaryHeight - r.maxY, width: r.width, height: r.height)
    }

    static func flip(_ p: CGPoint) -> CGPoint {
        CGPoint(x: p.x, y: primaryHeight - p.y)
    }

    /// All displays, left to right (then top to bottom).
    static var all: [Display] {
        NSScreen.screens
            .map { Display(axFrame: flip($0.frame), axVisibleFrame: flip($0.visibleFrame)) }
            .sorted { ($0.axFrame.minX, $0.axFrame.minY) < ($1.axFrame.minX, $1.axFrame.minY) }
    }

    /// The display holding most of a window.
    static func containing(_ rect: CGRect) -> Display? {
        let displays = all
        let best = displays.max { area($0.axFrame.intersection(rect)) < area($1.axFrame.intersection(rect)) }
        if let best, area(best.axFrame.intersection(rect)) > 0 { return best }
        return displays.first { $0.axFrame.contains(CGPoint(x: rect.midX, y: rect.midY)) } ?? displays.first
    }

    static func at(_ point: CGPoint) -> Display? {
        all.first { $0.axFrame.insetBy(dx: -1, dy: -1).contains(point) }
    }

    private static func area(_ r: CGRect) -> CGFloat { r.isNull ? 0 : r.width * r.height }
}
