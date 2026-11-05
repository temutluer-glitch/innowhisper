import SwiftUI

/// Section "Zugang & Erlaubnisse" with the group "Erlaubnisse" (AC-16, AC-17).
/// The problem hint above it comes from the settings frame (PROJ-1).
public struct AccessPane: View {
    let monitor: PermissionMonitor

    public init(monitor: PermissionMonitor) {
        self.monitor = monitor
    }

    public var body: some View {
        Form {
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
        }
        .formStyle(.grouped)
        .onAppear { monitor.refresh() }
    }
}
