import Foundation

/// A value that may appear in a log message. Opt-in: only types that declare
/// a safe, content-free description (e.g. enums of states) conform.
public protocol LogValue {
    var logDescription: String { get }
}

/// A log message that can only be built from fixed text in the source code
/// and safe values (AC-12). There is deliberately no way to interpolate a
/// free `String`: dictated text, clipboard contents or the access key cannot
/// end up in the log by accident — the compiler rejects it.
public struct LogMessage: Sendable, ExpressibleByStringInterpolation {
    public typealias StringLiteralType = StaticString

    public let text: String

    public init(stringLiteral value: StaticString) {
        text = value.description
    }

    public init(stringInterpolation: Interpolation) {
        text = stringInterpolation.text
    }

    public struct Interpolation: StringInterpolationProtocol {
        public typealias StringLiteralType = StaticString

        var text = ""

        public init(literalCapacity: Int, interpolationCount: Int) {
            text.reserveCapacity(literalCapacity + interpolationCount * 8)
        }

        public mutating func appendLiteral(_ literal: StaticString) {
            text += literal.description
        }

        public mutating func appendInterpolation<T: BinaryInteger>(_ value: T) {
            text += String(value)
        }

        public mutating func appendInterpolation(_ value: Double) {
            text += String(format: "%.2f", value)
        }

        public mutating func appendInterpolation(_ value: Bool) {
            text += value ? "true" : "false"
        }

        public mutating func appendInterpolation(_ value: Duration) {
            let (seconds, attoseconds) = value.components
            let milliseconds = seconds * 1000 + attoseconds / 1_000_000_000_000_000
            text += "\(milliseconds)ms"
        }

        public mutating func appendInterpolation(_ value: some LogValue) {
            text += value.logDescription
        }

        /// An app identifier such as `com.apple.TextEdit`. Anything that does
        /// not look like one is replaced, so free text cannot slip through.
        public mutating func appendInterpolation(bundleID: String?) {
            text += BundleIdentifierFilter.loggable(bundleID)
        }

        /// Only domain and code of an error, never its message text.
        public mutating func appendInterpolation(error: any Error) {
            let nsError = error as NSError
            text += "\(nsError.domain)#\(nsError.code)"
        }
    }
}

enum BundleIdentifierFilter {
    static let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.-")

    static func loggable(_ value: String?) -> String {
        guard let value, !value.isEmpty else { return "<none>" }
        guard value.count <= 255, value.contains("."),
            value.unicodeScalars.allSatisfy(allowed.contains)
        else { return "<invalid>" }
        return value
    }
}
