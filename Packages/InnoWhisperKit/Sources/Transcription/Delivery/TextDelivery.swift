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

/// Hands a finished text over to the user. Until PROJ-7 every text goes to
/// the clipboard (`ClipboardDelivery`); PROJ-7 replaces only the live path
/// with inserting into the active field. Recovered texts always stay on the
/// clipboard (design.md, Technical Decisions).
@MainActor
public protocol TextDelivering: AnyObject {
    /// Delivers `text`. Empty text is never delivered; the queue reports
    /// "Nichts erkannt" itself (AC-15).
    func deliver(_ text: String, kind: DeliveryKind)
}
