import CoreGraphics

/// Every window command Rectify knows. Raw values are stable identifiers
/// (used for preferences), titles are what the menu shows.
public enum WindowAction: String, CaseIterable, Sendable {
    case leftHalf, rightHalf, topHalf, bottomHalf, centerHalf
    case topLeft, topRight, bottomLeft, bottomRight
    case firstThird, centerThird, lastThird, firstTwoThirds, lastTwoThirds
    case firstFourth, secondFourth, thirdFourth, lastFourth
    case maximize, almostMaximize, maximizeHeight, center
    case larger, smaller
    case restore
    case nextDisplay, previousDisplay

    public var title: String {
        switch self {
        case .leftHalf: return "Left Half"
        case .rightHalf: return "Right Half"
        case .topHalf: return "Top Half"
        case .bottomHalf: return "Bottom Half"
        case .centerHalf: return "Center Half"
        case .topLeft: return "Top Left"
        case .topRight: return "Top Right"
        case .bottomLeft: return "Bottom Left"
        case .bottomRight: return "Bottom Right"
        case .firstThird: return "First Third"
        case .centerThird: return "Center Third"
        case .lastThird: return "Last Third"
        case .firstTwoThirds: return "First Two Thirds"
        case .lastTwoThirds: return "Last Two Thirds"
        case .firstFourth: return "First Fourth"
        case .secondFourth: return "Second Fourth"
        case .thirdFourth: return "Third Fourth"
        case .lastFourth: return "Last Fourth"
        case .maximize: return "Maximize"
        case .almostMaximize: return "Almost Maximize"
        case .maximizeHeight: return "Maximize Height"
        case .center: return "Center"
        case .larger: return "Make Larger"
        case .smaller: return "Make Smaller"
        case .restore: return "Restore"
        case .nextDisplay: return "Next Display"
        case .previousDisplay: return "Previous Display"
        }
    }

    /// Menu grouping; a separator is drawn between groups.
    public static let menuGroups: [[WindowAction]] = [
        [.leftHalf, .rightHalf, .centerHalf, .topHalf, .bottomHalf],
        [.topLeft, .topRight, .bottomLeft, .bottomRight],
        [.firstThird, .centerThird, .lastThird, .firstTwoThirds, .lastTwoThirds],
        [.firstFourth, .secondFourth, .thirdFourth, .lastFourth],
        [.maximize, .almostMaximize, .maximizeHeight, .center, .larger, .smaller, .restore],
        [.nextDisplay, .previousDisplay]
    ]

    /// Whether the result gets gaps applied (tiling actions only).
    public var usesGaps: Bool {
        switch self {
        case .center, .larger, .smaller, .restore, .nextDisplay, .previousDisplay, .almostMaximize:
            return false
        default:
            return true
        }
    }
}
