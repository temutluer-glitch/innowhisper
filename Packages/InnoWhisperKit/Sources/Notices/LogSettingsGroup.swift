import AppKit
import Diagnostics
import SwiftUI

/// Group "Fehlerprotokoll" in "Allgemein" (AC-14, EC-3, EC-4).
public struct LogSettingsGroup: View {
    let logFile: LogFile
    @State private var available = true

    public init(logFile: LogFile) {
        self.logFile = logFile
    }

    public var body: some View {
        LabeledContent {
            Button(available ? "Fehlerprotokoll zeigen" : "Fehlerprotokoll nicht verfügbar") {
                guard let url = logFile.ensureFileExists() else {
                    available = false
                    return
                }
                NSWorkspace.shared.activateFileViewerSelecting([url])
            }
            .disabled(!available)
        } label: {
            Text("Fehlerprotokoll")
            Text("Enthält nur technische Abläufe, nie diktierten Text.")
        }
        .onAppear { available = logFile.isAvailable }
    }
}
