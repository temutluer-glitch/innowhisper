import Diagnostics
import Foundation

/// Picks up where the last run stopped (AC-20, EC-6): piece folders left by a
/// crash are removed, and every recording still open in the list is converted
/// in spoken order; their texts go to the clipboard as "Nachgeholtes Diktat".
/// What was handed on before quitting is `converted` and is not repeated.
@MainActor
public enum TranscriptionRecovery {
    /// Call once at app start, after the recordings folder was tidied up
    /// with the list's file names kept.
    public static func resume(
        list: RecordingList, queue: TranscriptionQueue,
        removePieceFolders: () -> Void = { AudioSplitter.removeAllPieceFolders() }
    ) {
        removePieceFolders()
        let open = list.openEntries
        guard !open.isEmpty else { return }
        Log.write("Recovering \(open.count) dictations not converted before", category: .transcription)
        queue.receiveRecovered(open)
    }
}
