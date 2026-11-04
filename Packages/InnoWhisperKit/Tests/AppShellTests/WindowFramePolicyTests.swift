import CoreGraphics
import Testing

@testable import AppShell

struct WindowFramePolicyTests {
    let main = CGRect(x: 0, y: 0, width: 1440, height: 900)
    let second = CGRect(x: 1440, y: 0, width: 1920, height: 1080)

    // EC-6: fully visible frame is kept
    @Test func visibleFrameIsKept() {
        let frame = CGRect(x: 100, y: 100, width: 760, height: 520)
        #expect(WindowFramePolicy.reachableFrame(for: frame, screens: [main], mainScreen: main) == frame)
    }

    // EC-6: frame on a disconnected second screen is centered on the main screen
    @Test func frameOnDisconnectedScreenIsCentered() {
        let frame = CGRect(x: 2000, y: 200, width: 760, height: 520)
        let result = WindowFramePolicy.reachableFrame(for: frame, screens: [main], mainScreen: main)
        #expect(result == CGRect(x: 340, y: 190, width: 760, height: 520))
    }

    // EC-6: frame still on a connected second screen is kept
    @Test func frameOnConnectedSecondScreenIsKept() {
        let frame = CGRect(x: 2000, y: 200, width: 760, height: 520)
        #expect(WindowFramePolicy.reachableFrame(for: frame, screens: [main, second], mainScreen: main) == frame)
    }

    // EC-6: 80 % threshold — 79 % visible moves, 80 % stays
    @Test func eightyPercentThreshold() {
        let width: CGFloat = 1000
        let partly79 = CGRect(x: main.maxX - 790, y: 100, width: width, height: 500)
        let partly80 = CGRect(x: main.maxX - 800, y: 100, width: width, height: 500)
        #expect(WindowFramePolicy.reachableFrame(for: partly79, screens: [main], mainScreen: main) != partly79)
        #expect(WindowFramePolicy.reachableFrame(for: partly80, screens: [main], mainScreen: main) == partly80)
    }

    // EC-6: window larger than the main screen is shrunk to fit
    @Test func oversizedFrameIsShrunk() {
        let frame = CGRect(x: 5000, y: 0, width: 3000, height: 2000)
        let result = WindowFramePolicy.reachableFrame(for: frame, screens: [main], mainScreen: main)
        #expect(result == main)
    }
}
