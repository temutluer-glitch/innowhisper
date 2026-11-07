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

    public var logDescription: StaticString {
        switch self {
        case .info: "info"
        case .success: "success"
        case .error: "error"
        }
    }
}

/// A button on a notice, e.g. "Jetzt erlauben" (PROJ-5 AC-15).
public struct NoticeAction: Sendable {
    public let title: String
    public let perform: @MainActor @Sendable () -> Void

    public init(title: String, perform: @escaping @MainActor @Sendable () -> Void) {
        self.title = title
        self.perform = perform
    }
}

/// One notice. In memory only.
public struct Notice: Identifiable, Sendable, Equatable {
    public static let maxLength = 120

    public let id: UUID
    public let kind: NoticeKind
    /// One line, at most 120 characters; longer text ends with "…".
    public let text: String
    /// Optional button; notices without one behave as before.
    public let action: NoticeAction?

    public init(kind: NoticeKind, text: String, action: NoticeAction? = nil, id: UUID = UUID()) {
        self.id = id
        self.kind = kind
        self.action = action
        let oneLine = text.replacingOccurrences(of: "\n", with: " ")
        self.text = oneLine.count > Self.maxLength ? String(oneLine.prefix(Self.maxLength - 1)) + "…" : oneLine
    }

    public static func == (lhs: Notice, rhs: Notice) -> Bool {
        lhs.id == rhs.id && lhs.kind == rhs.kind && lhs.text == rhs.text && lhs.action?.title == rhs.action?.title
    }
}
