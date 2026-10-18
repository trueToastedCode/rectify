import CoreGraphics

/// Pure window geometry.
///
/// All rects use the Accessibility coordinate space: origin at the top-left
/// of the primary display, y growing downward. So `minY` is the TOP edge.
public enum Layout {
    /// Width/height fractions that halves cycle through on repeated presses.
    public static let halfCycle: [CGFloat] = [1.0 / 2.0, 2.0 / 3.0, 1.0 / 3.0]
    public static let resizeStep: CGFloat = 30
    public static let minimumSize = CGSize(width: 200, height: 150)

    /// Target frame for `action` on a display whose usable area is `screen`.
    /// `step` counts consecutive repeats of the same action (0 = first press).
    /// Returns nil for actions that are not pure geometry (restore, displays).
    public static func frame(for action: WindowAction,
                             in screen: CGRect,
                             current: CGRect,
                             step: Int = 0,
                             gap: CGFloat = 0) -> CGRect? {
        let s = screen
        let landscape = s.width >= s.height
        var r: CGRect

        switch action {
        case .leftHalf, .rightHalf:
            let w = (s.width * halfCycle[step % halfCycle.count]).rounded()
            r = CGRect(x: action == .leftHalf ? s.minX : s.maxX - w, y: s.minY, width: w, height: s.height)
        case .topHalf, .bottomHalf:
            let h = (s.height * halfCycle[step % halfCycle.count]).rounded()
            r = CGRect(x: s.minX, y: action == .topHalf ? s.minY : s.maxY - h, width: s.width, height: h)
        case .centerHalf:
            let w = (s.width / 2).rounded()
            r = CGRect(x: s.minX + ((s.width - w) / 2).rounded(), y: s.minY, width: w, height: s.height)

        case .topLeft, .topRight, .bottomLeft, .bottomRight:
            let w = (s.width / 2).rounded(), h = (s.height / 2).rounded()
            let left = action == .topLeft || action == .bottomLeft
            let top = action == .topLeft || action == .topRight
            r = CGRect(x: left ? s.minX : s.maxX - w, y: top ? s.minY : s.maxY - h, width: w, height: h)

        case .firstThird, .centerThird, .lastThird:
            let base = action == .firstThird ? 0 : (action == .centerThird ? 1 : 2)
            r = slice(s, index: (base + step) % 3, of: 3, span: 1, landscape: landscape)
        case .firstTwoThirds, .lastTwoThirds:
            let base = action == .firstTwoThirds ? 0 : 1
            r = slice(s, index: (base + step) % 2, of: 3, span: 2, landscape: landscape)
        case .firstFourth, .secondFourth, .thirdFourth, .lastFourth:
            let base: Int = [.firstFourth: 0, .secondFourth: 1, .thirdFourth: 2, .lastFourth: 3][action]!
            r = slice(s, index: (base + step) % 4, of: 4, span: 1, landscape: landscape)

        case .maximize:
            r = s
        case .almostMaximize:
            let w = (s.width * 0.9).rounded(), h = (s.height * 0.9).rounded()
            r = CGRect(x: s.minX + ((s.width - w) / 2).rounded(), y: s.minY + ((s.height - h) / 2).rounded(), width: w, height: h)
        case .maximizeHeight:
            r = CGRect(x: current.minX, y: s.minY, width: min(current.width, s.width), height: s.height)
        case .center:
            let w = min(current.width, s.width), h = min(current.height, s.height)
            r = CGRect(x: s.minX + ((s.width - w) / 2).rounded(), y: s.minY + ((s.height - h) / 2).rounded(), width: w, height: h)
        case .larger:
            r = current.insetBy(dx: -resizeStep, dy: -resizeStep).intersection(s)
            if r.isNull { r = s }
        case .smaller:
            let shrunk = current.insetBy(dx: resizeStep, dy: resizeStep)
            // At the floor already: leave the window where it is.
            r = (shrunk.width < minimumSize.width || shrunk.height < minimumSize.height) ? current : shrunk

        case .restore, .nextDisplay, .previousDisplay:
            return nil
        }

        return action.usesGaps ? applyGap(r, screen: s, gap: gap) : r
    }

    /// `index`-th slice of `count` equal parts, `span` parts wide.
    /// Columns on landscape displays, rows on portrait ones.
    static func slice(_ s: CGRect, index: Int, of count: Int, span: Int, landscape: Bool) -> CGRect {
        if landscape {
            let x0 = (s.minX + s.width * CGFloat(index) / CGFloat(count)).rounded()
            let x1 = (s.minX + s.width * CGFloat(index + span) / CGFloat(count)).rounded()
            return CGRect(x: x0, y: s.minY, width: x1 - x0, height: s.height)
        } else {
            let y0 = (s.minY + s.height * CGFloat(index) / CGFloat(count)).rounded()
            let y1 = (s.minY + s.height * CGFloat(index + span) / CGFloat(count)).rounded()
            return CGRect(x: s.minX, y: y0, width: s.width, height: y1 - y0)
        }
    }

    /// Full gap against screen edges, half gap on edges shared with neighbours,
    /// so two adjacent windows end up exactly `gap` apart.
    public static func applyGap(_ r: CGRect, screen s: CGRect, gap g: CGFloat) -> CGRect {
        guard g > 0 else { return r }
        let eps: CGFloat = 1
        let left = abs(r.minX - s.minX) < eps ? g : g / 2
        let right = abs(r.maxX - s.maxX) < eps ? g : g / 2
        let top = abs(r.minY - s.minY) < eps ? g : g / 2
        let bottom = abs(r.maxY - s.maxY) < eps ? g : g / 2
        return CGRect(x: r.minX + left, y: r.minY + top,
                      width: r.width - left - right, height: r.height - top - bottom).integral
    }

    /// Moves a window to another display, keeping its relative position and
    /// shrinking it if it does not fit.
    public static func move(_ frame: CGRect, from source: CGRect, to dest: CGRect) -> CGRect {
        let w = min(frame.width, dest.width), h = min(frame.height, dest.height)
        let rx = source.width > frame.width ? (frame.minX - source.minX) / (source.width - frame.width) : 0
        let ry = source.height > frame.height ? (frame.minY - source.minY) / (source.height - frame.height) : 0
        let x = dest.minX + (dest.width - w) * min(max(rx, 0), 1)
        let y = dest.minY + (dest.height - h) * min(max(ry, 0), 1)
        return CGRect(x: x.rounded(), y: y.rounded(), width: w, height: h)
    }
}

public extension CGRect {
    func isClose(to other: CGRect, tolerance: CGFloat = 3) -> Bool {
        abs(minX - other.minX) <= tolerance && abs(minY - other.minY) <= tolerance &&
        abs(width - other.width) <= tolerance && abs(height - other.height) <= tolerance
    }
}
