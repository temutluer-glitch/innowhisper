import Diagnostics
import Foundation

/// The folder of the recording files on this Mac (design.md → Datenmodell
/// "Aufnahme"): `~/Library/Application Support/InnoWhisper/Recordings/`.
/// Hands out a fresh file per recording, deletes files and reports free disk
/// space. Only touches files directly inside its own folder. Tests pass a
/// temporary base directory.
public struct RecordingStorage: Sendable {
    /// `~/Library/Application Support/InnoWhisper`.
    public static let defaultBaseDirectory = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Application Support/InnoWhisper", isDirectory: true)
    /// File extension of a recording (CAF, design.md → Datenmodell).
    public static let fileExtension = "caf"

    /// The folder holding the recording files.
    public let folder: URL

    public init(baseDirectory: URL = RecordingStorage.defaultBaseDirectory) {
        folder = baseDirectory.appendingPathComponent(RecordingInfo.folderName, isDirectory: true)
    }

    /// Creates the folder if it is missing.
    public func prepareFolder() throws {
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    }

    /// A new, unused file location for one recording: a random UUID name with
    /// the extension `caf`, inside the folder (created on demand). The file
    /// itself is written by the microphone capture.
    public func newFileURL() throws -> URL {
        try prepareFolder()
        return folder.appendingPathComponent(UUID().uuidString, isDirectory: false)
            .appendingPathExtension(Self.fileExtension)
    }

    /// `true` when `url` names a file directly inside the folder (symbolic
    /// links such as /var → /private/var resolved on both sides).
    public func contains(_ url: URL) -> Bool {
        let name = url.lastPathComponent
        guard url.isFileURL, !["", ".", "..", "/"].contains(name) else { return false }
        let parent = url.deletingLastPathComponent().resolvingSymlinksInPath().pathComponents
        return parent == folder.resolvingSymlinksInPath().pathComponents
    }

    /// Deletes one recording file. A missing file counts as deleted; a file
    /// outside the folder is never touched. Returns `true` when the file is gone.
    @discardableResult
    public func delete(_ url: URL) -> Bool {
        guard contains(url) else {
            Log.write("Refused to delete a file outside the recordings folder", category: .recording, level: .error)
            return false
        }
        do {
            try FileManager.default.removeItem(at: url)
            return true
        } catch CocoaError.fileNoSuchFile {
            return true
        } catch {
            Log.write("Recording file could not be deleted: \(error: error)", category: .recording, level: .error)
            return false
        }
    }

    /// Free space in bytes on the volume of the folder, as macOS reports it
    /// for important use (EC-4); `nil` when macOS cannot tell.
    public func availableBytes() -> Int64? {
        do {
            try prepareFolder()
            let values = try folder.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
            return values.volumeAvailableCapacityForImportantUsage
        } catch {
            Log.write("Free disk space unknown: \(error: error)", category: .recording, level: .error)
            return nil
        }
    }

    /// Deletes every file left in the folder, the remains of a crash; there
    /// is no recovery (design.md → Datenmodell). Called once at app start.
    /// Files named in `keeping` stay: recordings the transcription still has to
    /// convert or keeps for later (PROJ-6 AC-19, AC-20). Returns how many files
    /// were removed, for the log.
    @discardableResult
    public func removeLeftovers(keeping: Set<String> = []) -> Int {
        let files: [URL]
        do {
            files = try FileManager.default.contentsOfDirectory(
                at: folder, includingPropertiesForKeys: nil, options: [])
        } catch CocoaError.fileReadNoSuchFile {
            return 0
        } catch {
            Log.write("Recordings folder unreadable: \(error: error)", category: .recording, level: .error)
            return 0
        }
        let leftovers = files.filter { !keeping.contains($0.lastPathComponent) }
        var removed = 0
        for file in leftovers where delete(file) {
            removed += 1
        }
        if removed > 0 {
            Log.write("Leftover recordings removed at start: \(removed)", category: .recording)
        }
        if removed < leftovers.count {
            Log.write(
                "Leftover recordings not removed: \(leftovers.count - removed)", category: .recording, level: .error)
        }
        return removed
    }
}
