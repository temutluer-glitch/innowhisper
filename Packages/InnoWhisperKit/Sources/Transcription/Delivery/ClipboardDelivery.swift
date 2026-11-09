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

    public func deliver(_ text: String, kind: DeliveryKind) {
        // Nothing to hand over: no clipboard change, no notice (AC-15 is the queue's job).
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        writeToPasteboard(text)
        notify(.info, Self.noticeText(for: kind), nil)
        // Only the kind and the length, never the text itself (PROJ-2 AC-12).
        Log.write("Text delivered: \(kind), \(text.count) characters", category: .transcription)
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
