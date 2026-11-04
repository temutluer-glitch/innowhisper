import CoreGraphics

/// Where the notice capsule goes (AC-1, EC-1). AppKit screen coordinates
/// (origin bottom left).
public enum NoticePlacement {
    public static let gapBelowAnchor: CGFloat = 8
    public static let gapBelowMenuBar: CGFloat = 12

    /// - Parameters:
    ///   - size: size of the capsule.
    ///   - anchor: the spot reported by PROJ-8, or nil.
    ///   - screens: visible frames of all screens.
    ///   - mouse: mouse position.
    ///   - mainScreen: visible frame of the main screen (fallback).
    public static func frame(
        size: CGSize, anchor: CGRect?, screens: [CGRect], mouse: CGPoint, mainScreen: CGRect
    ) -> CGRect {
        if let anchor {
            let screen =
                screens.first { $0.contains(CGPoint(x: anchor.midX, y: anchor.midY)) }
                ?? screenOf(mouse, screens, mainScreen)
            var origin = CGPoint(x: anchor.midX - size.width / 2, y: anchor.minY - gapBelowAnchor - size.height)
            if origin.y < screen.minY {
                origin.y = anchor.maxY + gapBelowAnchor
            }
            return clamp(CGRect(origin: origin, size: size), into: screen)
        }
        let screen = screenOf(mouse, screens, mainScreen)
        let origin = CGPoint(x: screen.midX - size.width / 2, y: screen.maxY - gapBelowMenuBar - size.height)
        return clamp(CGRect(origin: origin, size: size), into: screen)
    }

    static func screenOf(_ point: CGPoint, _ screens: [CGRect], _ fallback: CGRect) -> CGRect {
        screens.first { $0.contains(point) } ?? fallback
    }

    static func clamp(_ rect: CGRect, into screen: CGRect) -> CGRect {
        var result = rect
        result.origin.x = min(max(result.origin.x, screen.minX), screen.maxX - result.width)
        result.origin.y = min(max(result.origin.y, screen.minY), screen.maxY - result.height)
        return result
    }
}
