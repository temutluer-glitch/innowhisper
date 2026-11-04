import Diagnostics
import Foundation

/// The three kinds of notices (AC-2).
public enum NoticeKind: Sendable, Equatable, LogValue {
    case info
    case success
    case error

    public var symbolName: String {
        switch self {
        case .info: "info.circle.fill"
        case .success: "checkmark.circle.fill"
        case .error: "exclamationmark.triangle.fill"
        }
    }

    /// Info and success close by themselves (AC-3); errors stay (AC-4).
    public var closesAutomatically: Bool { self != .error }

    public var logDescription: String {
        switch self {
        case .info: "info"
        case .success: "success"
        case .error: "error"
        }
    }
}

/// One notice. In memory only.
public struct Notice: Identifiable, Sendable, Equatable {
    public static let maxLength = 120

    public let id: UUID
    public let kind: NoticeKind
    /// One line, at most 120 characters; longer text ends with "…".
    public let text: String

    public init(kind: NoticeKind, text: String, id: UUID = UUID()) {
        self.id = id
        self.kind = kind
        let oneLine = text.replacingOccurrences(of: "\n", with: " ")
        self.text = oneLine.count > Self.maxLength ? String(oneLine.prefix(Self.maxLength - 1)) + "…" : oneLine
    }
}
