import SwiftUI

/// A small bar that shows how loud the microphone is right now (AC-19).
struct LevelMeter: View {
    /// 0…1
    let level: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(.quaternary)
                Capsule()
                    .fill(.tint)
                    .frame(width: max(0, min(1, level)) * proxy.size.width)
            }
        }
        .frame(height: 8)
        .animation(.linear(duration: 0.05), value: level)
        .accessibilityElement()
        .accessibilityLabel("Pegel")
        .accessibilityValue("\(Int((max(0, min(1, level)) * 100).rounded())) Prozent")
    }
}
