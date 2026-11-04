import CoreGraphics

/// Keeps the settings window reachable (EC-6): a window that is not at least
/// 80 % on a connected screen is centered on the main screen.
public enum WindowFramePolicy {
    public static let minimumVisibleShare: CGFloat = 0.8

    /// - Parameters:
    ///   - frame: the stored window frame.
    ///   - screens: visible frames of all connected screens.
    ///   - mainScreen: visible frame of the main screen.
    public static func reachableFrame(for frame: CGRect, screens: [CGRect], mainScreen: CGRect) -> CGRect {
        let area = frame.width * frame.height
        guard area > 0 else { return centered(frame.size, in: mainScreen) }
        let bestShare =
            screens
            .map { $0.intersection(frame) }
            .filter { !$0.isNull }
            .map { $0.width * $0.height / area }
            .max() ?? 0
        if bestShare >= minimumVisibleShare { return frame }
        return centered(frame.size, in: mainScreen)
    }

    static func centered(_ size: CGSize, in screen: CGRect) -> CGRect {
        let width = min(size.width, screen.width)
        let height = min(size.height, screen.height)
        return CGRect(
            x: screen.midX - width / 2,
            y: screen.midY - height / 2,
            width: width,
            height: height
        )
    }
}
