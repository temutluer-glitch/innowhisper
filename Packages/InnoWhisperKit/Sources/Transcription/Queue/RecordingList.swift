import Diagnostics
import Foundation
import Recording

/// One recording known to the transcription (design.md → Datenmodell
/// "Aufnahme-Liste"). Holds no text and no model: only where the audio lives,
/// when it was spoken, how long it is and whether it was converted.
public struct RecordingListEntry: Equatable, Sendable, Codable {
    /// `open`: not converted yet or failed; `converted`: text was handed on.
    public enum State: String, Equatable, Sendable, Codable, LogValue {
        case open
        case converted

        public var logDescription: StaticString {
            switch self {
            case .open: "open"
            case .converted: "converted"
            }
        }
    }

    /// Name of the CAF file directly inside the recordings folder; unique.
    public let fileName: String
    /// Start of the recording; orders the entries across restarts.
    public let spokenAt: Date
    /// Length in seconds, always greater than 0.
    public let duration: Double
    public private(set) var state: State
    /// Set only when `state` is `converted`.
    public private(set) var convertedAt: Date?

    /// `nil` when the values break the rules of the list (odd file name,
    /// duration not above 0, conversion time not matching the state).
    public init?(fileName: String, spokenAt: Date, duration: Double, state: State = .open, convertedAt: Date? = nil) {
        guard Self.isValidFileName(fileName), duration.isFinite, duration > 0,
            (state == .converted) == (convertedAt != nil)
        else { return nil }
        self.fileName = fileName
        self.spokenAt = spokenAt
        self.duration = duration
        self.state = state
        self.convertedAt = convertedAt
    }

    /// A plain file name: not empty, no path separator, no "..", no NUL,
    /// not hidden. Anything else could point outside the recordings folder.
    public static func isValidFileName(_ name: String) -> Bool {
        !name.isEmpty && !name.contains("/") && !name.contains("\\") && !name.contains("..")
            && !name.contains("\0") && !name.hasPrefix(".")
    }

    mutating func markConverted(at date: Date) {
        state = .converted
        convertedAt = date
    }

    private enum CodingKeys: String, CodingKey {
        case fileName, spokenAt, duration, state, convertedAt
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        guard
            let entry = RecordingListEntry(
                fileName: try container.decode(String.self, forKey: .fileName),
                spokenAt: try container.decode(Date.self, forKey: .spokenAt),
                duration: try container.decode(Double.self, forKey: .duration),
                state: try container.decode(State.self, forKey: .state),
                convertedAt: try container.decodeIfPresent(Date.self, forKey: .convertedAt))
        else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: decoder.codingPath, debugDescription: "Recording list entry breaks the rules"))
        }
        self = entry
    }
}

/// The stored list of recordings (UserDefaults `transcription.recordings`,
/// JSON array). Every change is saved at once, so the caller can mark a
/// recording converted in the same step it hands the text on (EC-6). Keeps
/// at most `TranscriptionInfo.keptRecordings` converted entries, deleting the
/// oldest together with their files (AC-19); open entries never count and
/// are never removed automatically (AC-20).
@MainActor
public final class RecordingList {
    /// All entries in the order they were added.
    public private(set) var entries: [RecordingListEntry]

    private let defaults: UserDefaults
    private let storage: RecordingStorage
    private let now: () -> Date

    /// Reads the stored list. Entries whose file is gone are dropped and the
    /// list saved; an unreadable list counts as empty.
    public init(
        defaults: UserDefaults = .standard, storage: RecordingStorage = RecordingStorage(),
        now: @escaping () -> Date = Date.init
    ) {
        self.defaults = defaults
        self.storage = storage
        self.now = now
        entries = []
        load()
    }

    /// Open entries in spoken order: what still has to be converted.
    public var openEntries: [RecordingListEntry] {
        entries.filter { $0.state == .open }
            .sorted { ($0.spokenAt, $0.fileName) < ($1.spokenAt, $1.fileName) }
    }

    /// File names of every entry, for `RecordingStorage.removeLeftovers(keeping:)`.
    public var keptFileNames: Set<String> {
        Set(entries.map(\.fileName))
    }

    /// The entry for a file name, if there is one.
    public func entry(named fileName: String) -> RecordingListEntry? {
        entries.first { $0.fileName == fileName }
    }

    /// The location of an entry's file inside the recordings folder.
    public func fileURL(for fileName: String) -> URL {
        storage.folder.appendingPathComponent(fileName, isDirectory: false)
    }

    /// Adds a recording that arrived at the transcription as `open`. A file
    /// name already on the list keeps its entry unchanged. Returns `false`
    /// when the recording breaks the rules (file outside the folder, odd
    /// name, duration not above 0).
    @discardableResult
    public func add(_ recording: FinishedRecording) -> Bool {
        let fileName = recording.fileURL.lastPathComponent
        guard storage.contains(recording.fileURL),
            let entry = RecordingListEntry(
                fileName: fileName, spokenAt: recording.startedAt, duration: Self.seconds(recording.duration))
        else {
            Log.write("Recording not added to the list: invalid", category: .transcription, level: .error)
            return false
        }
        guard self.entry(named: fileName) == nil else { return true }
        entries.append(entry)
        save()
        return true
    }

    /// Marks an entry converted now and deletes the oldest converted entries
    /// beyond the limit, with their files. Returns `false` when the file name
    /// is not on the list.
    @discardableResult
    public func markConverted(_ fileName: String) -> Bool {
        guard let index = entries.firstIndex(where: { $0.fileName == fileName }) else {
            Log.write("Recording to mark converted is not on the list", category: .transcription, level: .error)
            return false
        }
        entries[index].markConverted(at: now())
        pruneConverted()
        save()
        return true
    }

    /// Removes an entry, e.g. after "Nichts erkannt" (AC-15) or a broken
    /// file (EC-4); with `deleteFile` its file goes too. Returns `false`
    /// when the file name is not on the list.
    @discardableResult
    public func remove(_ fileName: String, deleteFile: Bool) -> Bool {
        guard let index = entries.firstIndex(where: { $0.fileName == fileName }) else { return false }
        entries.remove(at: index)
        if deleteFile {
            storage.delete(fileURL(for: fileName))
        }
        save()
        return true
    }

    // MARK: - Storage

    private func load() {
        guard let stored = defaults.object(forKey: TranscriptionInfo.recordingsDefaultsKey) else { return }
        guard let data = stored as? Data,
            let decoded = try? JSONDecoder().decode([LenientEntry].self, from: data)
        else {
            Log.write("Recording list unreadable, starting empty", category: .transcription, level: .error)
            defaults.removeObject(forKey: TranscriptionInfo.recordingsDefaultsKey)
            return
        }
        var seen = Set<String>()
        var invalid = 0
        var missing = 0
        for item in decoded {
            guard let entry = item.entry, seen.insert(entry.fileName).inserted else {
                invalid += 1
                continue
            }
            guard FileManager.default.fileExists(atPath: fileURL(for: entry.fileName).path) else {
                missing += 1
                continue
            }
            entries.append(entry)
        }
        let pruned = pruneConverted()
        if invalid > 0 {
            Log.write("Recording list entries dropped as invalid: \(invalid)", category: .transcription, level: .error)
        }
        if missing > 0 {
            Log.write("Recording list entries dropped, file missing: \(missing)", category: .transcription)
        }
        if invalid + missing + pruned > 0 {
            save()
        }
        Log.write(
            "Recording list loaded: \(openEntries.count) open, \(entries.count - openEntries.count) converted",
            category: .transcription)
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(entries)
            defaults.set(data, forKey: TranscriptionInfo.recordingsDefaultsKey)
        } catch {
            Log.write("Recording list not saved: \(error: error)", category: .transcription, level: .error)
        }
    }

    /// Drops the oldest converted entries (by conversion time) beyond the
    /// limit and deletes their files. Returns how many were dropped.
    @discardableResult
    private func pruneConverted() -> Int {
        let converted = entries.filter { $0.state == .converted }
        let excess = converted.count - TranscriptionInfo.keptRecordings
        guard excess > 0 else { return 0 }
        let oldest = converted.sorted { ($0.convertedAt ?? .distantPast) < ($1.convertedAt ?? .distantPast) }
            .prefix(excess)
        let names = Set(oldest.map(\.fileName))
        var notDeleted = 0
        for name in names where !storage.delete(fileURL(for: name)) {
            notDeleted += 1
        }
        entries.removeAll { names.contains($0.fileName) }
        Log.write("Oldest converted recordings removed: \(names.count)", category: .transcription)
        if notDeleted > 0 {
            Log.write(
                "Oldest converted recording files not deleted: \(notDeleted)", category: .transcription, level: .error)
        }
        return names.count
    }

    private static func seconds(_ duration: Duration) -> Double {
        Double(duration.components.seconds) + Double(duration.components.attoseconds) / 1e18
    }

    /// Decodes one stored entry and turns a broken one into `nil` instead of
    /// failing the whole list.
    private struct LenientEntry: Decodable {
        let entry: RecordingListEntry?

        init(from decoder: any Decoder) throws {
            entry = try? RecordingListEntry(from: decoder)
        }
    }
}
