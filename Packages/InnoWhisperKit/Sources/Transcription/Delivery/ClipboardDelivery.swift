import AppKit
import Diagnostics
import Notices

/// Puts the finished text on the general clipboard and shows a short info
/// notice: "Text in der Zwischenablage." for live dictations (AC-3),
/// "Nachgeholtes Diktat in der Zwischenablage." for recovered ones (AC-20).
@MainActor
public final class ClipboardDelivery: TextDelivering {
    /// Replaces the clipboard contents with a plain string.
    private let writeToPasteboard: @MainActor (String) -> Void
    /// Shows a notice; passed in by the app (same shape as in `Recording`).
    private let notify: @MainActor (NoticeKind, String, NoticeAction?) -> Void

    public init(
        writeToPasteboard: @escaping @MainActor (String) -> Void = ClipboardDelivery.writeToGeneralPasteboard,
        notify: @escaping @MainActor (NoticeKind, String, NoticeAction?) -> Void
    ) {
        self.writeToPasteboard = writeToPasteboard
        self.notify = notify
    }

    /// The clipboard holds one text: several texts of one step go together,
    /// in spoken order, separated by a blank line (AC-20, BUG-4). The notice
    /// says "Nachgeholtes …" as soon as one of them was recovered.
    public func deliver(_ texts: [DeliveredText]) {
        // Nothing to hand over: no clipboard change, no notice (AC-15 is the queue's job).
        let usable = texts.filter { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        guard !usable.isEmpty else { return }
        let text = usable.map(\.text).joined(separator: "\n\n")
        let kind: DeliveryKind = usable.contains { $0.kind == .recovered } ? .recovered : .live
        writeToPasteboard(text)
        notify(.info, Self.noticeText(for: kind), nil)
        // Only the kind, the count and the length, never the text itself (PROJ-2 AC-12).
        Log.write(
            "Text delivered: \(kind), \(usable.count) texts, \(text.count) characters", category: .transcription)
    }

    /// The notice shown after delivering.
    public static func noticeText(for kind: DeliveryKind) -> String {
        switch kind {
        case .live: TranscriptionTexts.textInClipboard
        case .recovered: TranscriptionTexts.recoveredInClipboard
        }
    }

    /// Production pasteboard: the general clipboard, contents replaced.
    public static func writeToGeneralPasteboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}
