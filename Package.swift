// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "Rectify",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "Rectify", targets: ["Rectify"])
    ],
    targets: [
        // Pure geometry: no AppKit, fully unit-tested.
        .target(name: "RectifyCore"),
        // The menu-bar app: Accessibility, hotkeys, snapping, UI.
        .executableTarget(name: "Rectify", dependencies: ["RectifyCore"]),
        .testTarget(name: "RectifyCoreTests", dependencies: ["RectifyCore"])
    ]
)
