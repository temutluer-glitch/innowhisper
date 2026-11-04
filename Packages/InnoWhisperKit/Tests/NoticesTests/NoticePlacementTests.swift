import CoreGraphics
import Testing

@testable import Notices

struct NoticePlacementTests {
    let main = CGRect(x: 0, y: 0, width: 1440, height: 875)
    let second = CGRect(x: 1440, y: 0, width: 1920, height: 1055)
    let size = CGSize(width: 200, height: 32)

    // AC-1: centred below the reported spot, 8 pt gap
    @Test func belowAnchor() {
        let anchor = CGRect(x: 400, y: 500, width: 100, height: 20)
        let frame = NoticePlacement.frame(size: size, anchor: anchor, screens: [main], mouse: .zero, mainScreen: main)
        #expect(frame == CGRect(x: 350, y: 460, width: 200, height: 32))
    }

    // AC-1: no room below → above the spot
    @Test func aboveWhenNoRoomBelow() {
        let anchor = CGRect(x: 400, y: 10, width: 100, height: 20)
        let frame = NoticePlacement.frame(size: size, anchor: anchor, screens: [main], mouse: .zero, mainScreen: main)
        #expect(frame.minY == 38)
    }

    // AC-1: kept inside the screen at the side
    @Test func clampedAtScreenEdge() {
        let anchor = CGRect(x: 1430, y: 500, width: 10, height: 20)
        let frame = NoticePlacement.frame(size: size, anchor: anchor, screens: [main], mouse: .zero, mainScreen: main)
        #expect(frame.maxX == main.maxX)
    }

    // AC-1, EC-1: no spot → top centre of the screen with the mouse
    @Test func topCentreOnMouseScreen() {
        let onSecond = NoticePlacement.frame(
            size: size, anchor: nil, screens: [main, second], mouse: CGPoint(x: 2000, y: 300), mainScreen: main)
        #expect(onSecond == CGRect(x: second.midX - 100, y: second.maxY - 12 - 32, width: 200, height: 32))
        let onMain = NoticePlacement.frame(
            size: size, anchor: nil, screens: [main, second], mouse: CGPoint(x: 100, y: 100), mainScreen: main)
        #expect(onMain.midX == main.midX)
    }
}
