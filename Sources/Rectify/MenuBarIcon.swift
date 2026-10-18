import AppKit

/// Menu-bar version of the app icon: a tall left pane and two stacked right
/// panes, fading like the app icon's tiles. It's a template image, so macOS
/// tints it for light/dark menu bars and the disabled state.
enum MenuBarIcon {
    static func make() -> NSImage {
        let size = NSSize(width: 18, height: 16)
        let image = NSImage(size: size, flipped: false) { _ in
            let gap: CGFloat = 1.5
            let area = NSRect(x: 1, y: 1.5, width: 16, height: 13)
            let leftW = (area.width - gap) / 2
            let rightX = area.minX + leftW + gap
            let rightW = area.maxX - rightX
            let rightH = (area.height - gap) / 2

            func tile(_ r: NSRect, _ alpha: CGFloat) {
                NSColor.black.withAlphaComponent(alpha).setFill()
                NSBezierPath(roundedRect: r, xRadius: 2, yRadius: 2).fill()
            }
            tile(NSRect(x: area.minX, y: area.minY, width: leftW, height: area.height), 1)
            tile(NSRect(x: rightX, y: area.minY + rightH + gap, width: rightW, height: rightH), 0.7)
            tile(NSRect(x: rightX, y: area.minY, width: rightW, height: rightH), 0.45)
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = "Rectify"
        return image
    }
}
