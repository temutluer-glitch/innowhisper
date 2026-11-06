import SwiftUI

/// Group "Erlaubnisse" of the section "Zugang & Erlaubnisse" (AC-16, AC-17).
/// The app puts it into one form with the Groq key group (PROJ-4); the
/// problem hint above it comes from the settings frame (PROJ-1).
public struct AccessPane: View {
    let monitor: PermissionMonitor

    public init(monitor: PermissionMonitor) {
        self.monitor = monitor
    }

    public var body: some View {
        Section("Erlaubnisse") {
            ForEach(PermissionKind.allCases, id: \.self) { kind in
                LabeledContent {
                    HStack(spacing: 12) {
                        PermissionStatusLabel(granted: monitor.isGranted(kind))
                            .font(.body)
                        if !monitor.isGranted(kind) {
                            Button("Jetzt erlauben") { monitor.requestPermission(kind) }
                                .controlSize(.regular)
                        }
                    }
                } label: {
                    Text(kind.title)
                    Text(kind.explanation)
                }
            }
        }
        .onAppear { monitor.refresh() }
    }
}
