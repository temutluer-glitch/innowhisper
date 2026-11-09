import Diagnostics

/// Where a finished text comes from (AC-3, AC-20).
public enum DeliveryKind: Sendable, Equatable, LogValue {
    /// A dictation that was just spoken.
    case live
    /// Recordings left over from the last run, converted at start (AC-20).
    case recovered

    public var logDescription: StaticString {
        switch self {
        case .live: "live"
        case .recovered: "recovered"
        }
    }
}

/// One finished text and where it comes from.
public struct DeliveredText: Equatable, Sendable {
    public let text: String
    public let kind: DeliveryKind

    public init(_ text: String, kind: DeliveryKind) {
        self.text = text
        self.kind = kind
    }
}

/// Hands finished texts over to the user. Until PROJ-7 every text goes to
/// the clipboard (`ClipboardDelivery`); PROJ-7 replaces only the live path
/// with inserting into the active field. Recovered texts always stay on the
/// clipboard (design.md, Technical Decisions).
@MainActor
public protocol TextDelivering: AnyObject {
    /// Delivers every text that became ready in one step, in spoken order
    /// (AC-8). A target with room for one text only (the clipboard) must keep
    /// all of them (BUG-1, BUG-4). Empty texts are never delivered; the queue
    /// reports "Nichts erkannt" itself (AC-15).
    func deliver(_ texts: [DeliveredText])
}
