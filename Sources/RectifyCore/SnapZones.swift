import CoreGraphics

/// Maps a cursor position during a window drag to a snap action.
/// Coordinates are Accessibility space (top-left origin, y down).
public enum SnapZones {
    /// How close to an edge the cursor must be to trigger a snap.
    public static let edgeMargin: CGFloat = 5
    /// How far along an edge from a corner counts as the corner.
    public static let cornerSize: CGFloat = 20

    public static func action(at p: CGPoint, in s: CGRect) -> WindowAction? {
        guard p.x >= s.minX - 1, p.x <= s.maxX + 1, p.y >= s.minY - 1, p.y <= s.maxY + 1 else { return nil }

        let nearLeft = p.x <= s.minX + edgeMargin
        let nearRight = p.x >= s.maxX - edgeMargin
        let nearTop = p.y <= s.minY + edgeMargin
        let nearBottom = p.y >= s.maxY - edgeMargin

        let cornerLeft = p.x <= s.minX + cornerSize
        let cornerRight = p.x >= s.maxX - cornerSize
        let cornerTop = p.y <= s.minY + cornerSize
        let cornerBottom = p.y >= s.maxY - cornerSize

        // Corners: within the margin of one edge and the corner band of the other.
        if (nearLeft && cornerTop) || (nearTop && cornerLeft) { return .topLeft }
        if (nearRight && cornerTop) || (nearTop && cornerRight) { return .topRight }
        if (nearLeft && cornerBottom) || (nearBottom && cornerLeft) { return .bottomLeft }
        if (nearRight && cornerBottom) || (nearBottom && cornerRight) { return .bottomRight }

        if nearLeft { return .leftHalf }
        if nearRight { return .rightHalf }
        if nearTop { return .maximize }
        if nearBottom {
            // Bottom edge picks a third by horizontal position.
            let third = s.width / 3
            if p.x < s.minX + third { return .firstThird }
            if p.x < s.minX + 2 * third { return .centerThird }
            return .lastThird
        }
        return nil
    }
}
