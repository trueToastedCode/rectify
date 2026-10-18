// Draws the DMG window background (600x400 @1x and @2x).
// Run from the repo root: swift Scripts/make-dmg-background.swift
import AppKit

let out = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("Resources/dmg")
try! FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)

func render(scale: CGFloat) -> Data {
    let w = Int(600 * scale), h = Int(400 * scale)
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: w, pixelsHigh: h, bitsPerSample: 8,
                               samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: 600, height: 400)   // draw in points
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let ctx = NSGraphicsContext.current!.cgContext

    // Soft light gradient so the default dark Finder labels stay readable.
    let bg = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [
        NSColor(red: 0.97, green: 0.97, blue: 0.99, alpha: 1).cgColor,
        NSColor(red: 0.89, green: 0.92, blue: 0.96, alpha: 1).cgColor
    ] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(bg, start: CGPoint(x: 0, y: 400), end: CGPoint(x: 0, y: 0), options: [])

    // Arrow from the app (x=150) to Applications (x=450); icons sit at y=200 from top.
    let accent = NSColor(red: 0.12, green: 0.36, blue: 0.55, alpha: 0.75)
    let y: CGFloat = 400 - 190
    let arrow = NSBezierPath()
    arrow.move(to: NSPoint(x: 240, y: y))
    arrow.line(to: NSPoint(x: 350, y: y))
    arrow.lineWidth = 6
    arrow.lineCapStyle = .round
    accent.setStroke()
    arrow.stroke()
    let head = NSBezierPath()
    head.move(to: NSPoint(x: 362, y: y))
    head.line(to: NSPoint(x: 342, y: y + 14))
    head.line(to: NSPoint(x: 342, y: y - 14))
    head.close()
    accent.setFill()
    head.fill()

    // Headline and hint.
    func text(_ s: String, size: CGFloat, weight: NSFont.Weight, y: CGFloat, alpha: CGFloat) {
        let para = NSMutableParagraphStyle()
        para.alignment = .center
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: size, weight: weight),
            .foregroundColor: NSColor(red: 0.1, green: 0.14, blue: 0.25, alpha: alpha),
            .paragraphStyle: para
        ]
        NSAttributedString(string: s, attributes: attrs).draw(in: NSRect(x: 0, y: y, width: 600, height: size + 8))
    }
    text("Install Rectify", size: 22, weight: .semibold, y: 400 - 64, alpha: 0.9)
    text("Drag Rectify into your Applications folder", size: 13, weight: .regular, y: 52, alpha: 0.6)

    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

try! render(scale: 1).write(to: out.appendingPathComponent("background.png"))
try! render(scale: 2).write(to: out.appendingPathComponent("background@2x.png"))
print("Wrote Resources/dmg/background.png and @2x")
