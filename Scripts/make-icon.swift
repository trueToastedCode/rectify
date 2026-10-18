// Draws the Rectify app icon and writes Resources/AppIcon.icns.
// Run from the repo root: swift Scripts/make-icon.swift
import AppKit

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let iconset = root.appendingPathComponent("build/AppIcon.iconset")
try? FileManager.default.removeItem(at: iconset)
try! FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

func draw(size px: Int) -> Data {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px, bitsPerSample: 8,
                               samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let ctx = NSGraphicsContext.current!.cgContext
    let s = CGFloat(px) / 1024   // design on a 1024 grid

    // macOS icon grid: 824pt rounded square centred in 1024, with a soft shadow.
    let plate = CGRect(x: 100 * s, y: 100 * s, width: 824 * s, height: 824 * s)
    let platePath = CGPath(roundedRect: plate, cornerWidth: 185 * s, cornerHeight: 185 * s, transform: nil)
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -12 * s), blur: 28 * s,
                  color: NSColor.black.withAlphaComponent(0.35).cgColor)
    ctx.addPath(platePath)
    ctx.setFillColor(NSColor.black.cgColor)
    ctx.fillPath()
    ctx.restoreGState()

    // Background: deep indigo to teal.
    ctx.saveGState()
    ctx.addPath(platePath)
    ctx.clip()
    let bg = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [
        NSColor(red: 0.16, green: 0.13, blue: 0.42, alpha: 1).cgColor,
        NSColor(red: 0.05, green: 0.52, blue: 0.62, alpha: 1).cgColor
    ] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(bg, start: CGPoint(x: plate.minX, y: plate.maxY),
                           end: CGPoint(x: plate.maxX, y: plate.minY), options: [])
    ctx.restoreGState()

    // Tiles: a tall left pane and two stacked right panes, like a tiled desktop.
    let gap: CGFloat = 36 * s
    let area = plate.insetBy(dx: 96 * s, dy: 96 * s)
    let leftW = (area.width - gap) * 0.5
    let rightH = (area.height - gap) / 2
    let rightX = area.minX + leftW + gap, rightW = area.width - leftW - gap
    let tiles: [(CGRect, CGFloat)] = [
        (CGRect(x: area.minX, y: area.minY, width: leftW, height: area.height), 0.95),
        (CGRect(x: rightX, y: area.minY + rightH + gap, width: rightW, height: rightH), 0.55),
        (CGRect(x: rightX, y: area.minY, width: rightW, height: rightH), 0.32)
    ]
    for (rect, alpha) in tiles {
        ctx.addPath(CGPath(roundedRect: rect, cornerWidth: 44 * s, cornerHeight: 44 * s, transform: nil))
        ctx.setFillColor(NSColor.white.withAlphaComponent(alpha).cgColor)
        ctx.fillPath()
    }
    // Title-bar dots on the main tile.
    let main = tiles[0].0
    let d: CGFloat = 26 * s
    for i in 0..<3 {
        let dot = CGRect(x: main.minX + 40 * s + CGFloat(i) * (d + 16 * s), y: main.maxY - 40 * s - d, width: d, height: d)
        ctx.setFillColor(NSColor(red: 0.16, green: 0.13, blue: 0.42, alpha: 0.35).cgColor)
        ctx.fillEllipse(in: dot)
    }

    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

for base in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let name = scale == 1 ? "icon_\(base)x\(base).png" : "icon_\(base)x\(base)@2x.png"
        try! draw(size: base * scale).write(to: iconset.appendingPathComponent(name))
    }
}
try! draw(size: 1024).write(to: root.appendingPathComponent("build/AppIcon-1024.png"))

let task = Process()
task.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
task.arguments = ["-c", "icns", iconset.path, "-o", root.appendingPathComponent("Resources/AppIcon.icns").path]
try! task.run()
task.waitUntilExit()
print(task.terminationStatus == 0 ? "Wrote Resources/AppIcon.icns" : "iconutil failed")
