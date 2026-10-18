import XCTest
@testable import RectifyCore

final class LayoutTests: XCTestCase {
    // 1920x1080 display, 25pt menu bar on top (AX coords: y down).
    let screen = CGRect(x: 0, y: 25, width: 1920, height: 1055)
    let window = CGRect(x: 300, y: 200, width: 800, height: 600)

    func f(_ a: WindowAction, step: Int = 0, gap: CGFloat = 0) -> CGRect? {
        Layout.frame(for: a, in: screen, current: window, step: step, gap: gap)
    }

    func testHalves() {
        XCTAssertEqual(f(.leftHalf), CGRect(x: 0, y: 25, width: 960, height: 1055))
        XCTAssertEqual(f(.rightHalf), CGRect(x: 960, y: 25, width: 960, height: 1055))
        XCTAssertEqual(f(.topHalf)?.minY, 25)
        XCTAssertEqual(f(.bottomHalf)?.maxY, 1080)
    }

    func testHalfCyclesThroughTwoThirdsAndOneThird() {
        XCTAssertEqual(f(.leftHalf, step: 1)?.width, 1280)
        XCTAssertEqual(f(.leftHalf, step: 2)?.width, 640)
        XCTAssertEqual(f(.leftHalf, step: 3)?.width, 960)
        XCTAssertEqual(f(.rightHalf, step: 1)?.minX, 640)
    }

    func testQuarters() {
        XCTAssertEqual(f(.bottomRight), CGRect(x: 960, y: 552, width: 960, height: 528))
    }

    func testThirdsTileWithoutOverlap() {
        let a = f(.firstThird)!, b = f(.centerThird)!, c = f(.lastThird)!
        XCTAssertEqual(a.maxX, b.minX)
        XCTAssertEqual(b.maxX, c.minX)
        XCTAssertEqual(c.maxX, 1920)
        XCTAssertEqual(f(.firstThird, step: 1), b)   // cycling
        XCTAssertEqual(f(.lastTwoThirds), CGRect(x: 640, y: 25, width: 1280, height: 1055))
    }

    func testPortraitThirdsAreRows() {
        let portrait = CGRect(x: 0, y: 0, width: 1080, height: 1920)
        let r = Layout.frame(for: .firstThird, in: portrait, current: window)!
        XCTAssertEqual(r, CGRect(x: 0, y: 0, width: 1080, height: 640))
    }

    func testGapsMeetInTheMiddle() {
        let l = f(.leftHalf, gap: 10)!, r = f(.rightHalf, gap: 10)!
        XCTAssertEqual(l.minX, 10)
        XCTAssertEqual(r.minX - l.maxX, 10)
        XCTAssertEqual(r.maxX, 1910)
        XCTAssertEqual(l.minY, 35)
    }

    func testCenterAndMaximize() {
        XCTAssertEqual(f(.maximize), screen)
        XCTAssertEqual(f(.center), CGRect(x: 560, y: 253, width: 800, height: 600))
        XCTAssertEqual(f(.maximizeHeight), CGRect(x: 300, y: 25, width: 800, height: 1055))
    }

    func testLargerStaysOnScreenSmallerHasAFloor() {
        let big = Layout.frame(for: .larger, in: screen, current: screen, step: 0)!
        XCTAssertEqual(big, screen)
        let tiny = CGRect(x: 0, y: 0, width: 210, height: 160)
        XCTAssertEqual(Layout.frame(for: .smaller, in: screen, current: tiny), tiny)
    }

    func testMoveToOtherDisplayKeepsRelativePosition() {
        let left = CGRect(x: -1680, y: 0, width: 1680, height: 1050)
        let moved = Layout.move(CGRect(x: 0, y: 25, width: 960, height: 1055), from: screen, to: left)
        XCTAssertEqual(moved, CGRect(x: -1680, y: 0, width: 960, height: 1050))
    }
}

final class SnapZoneTests: XCTestCase {
    let screen = CGRect(x: 0, y: 0, width: 1920, height: 1080)

    func testZones() {
        XCTAssertEqual(SnapZones.action(at: CGPoint(x: 1, y: 500), in: screen), .leftHalf)
        XCTAssertEqual(SnapZones.action(at: CGPoint(x: 1919, y: 500), in: screen), .rightHalf)
        XCTAssertEqual(SnapZones.action(at: CGPoint(x: 900, y: 0), in: screen), .maximize)
        XCTAssertEqual(SnapZones.action(at: CGPoint(x: 2, y: 3), in: screen), .topLeft)
        XCTAssertEqual(SnapZones.action(at: CGPoint(x: 1919, y: 1070), in: screen), .bottomRight)
        XCTAssertEqual(SnapZones.action(at: CGPoint(x: 960, y: 1079), in: screen), .centerThird)
        XCTAssertNil(SnapZones.action(at: CGPoint(x: 900, y: 500), in: screen))
    }
}
