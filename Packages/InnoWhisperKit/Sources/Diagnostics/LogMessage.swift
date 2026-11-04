import CoreServices
import Foundation

/// A value that may appear in a log message, typically a state enum. It can
/// describe itself only with fixed text from the source code (`StaticString`):
/// stored text — a struct field, an enum payload, a `String` — cannot be
/// turned into a `StaticString`, so the compiler rejects every way of
/// smuggling content into the log (QA BUG-1).
public protocol LogValue {
    var logDescription: StaticString { get }
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
            text += value.logDescription.description
        }

        /// An app identifier such as `com.apple.TextEdit`. Only identifiers of
        /// apps installed on this Mac are logged; anything else is replaced,
        /// so free text cannot slip through (QA BUG-1).
        public mutating func appendInterpolation(bundleID: String?) {
            text += BundleIdentifierFilter.loggable(bundleID)
        }

        /// Only domain and code of an error, never its message text. Domains
        /// that are not system error domains are replaced (QA BUG-1).
        public mutating func appendInterpolation(error: any Error) {
            let nsError = error as NSError
            text += "\(ErrorDomainFilter.loggable(nsError.domain))#\(nsError.code)"
        }
    }
}

enum BundleIdentifierFilter {
    static let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.-")

    static func loggable(_ value: String?) -> String {
        guard let value, !value.isEmpty else { return "<none>" }
        guard value.count <= 255, value.unicodeScalars.allSatisfy(allowed.contains), isInstalledApp(value)
        else { return "<unknown-app>" }
        return value
    }

    /// Asks Launch Services whether an app with this identifier is installed.
    static func isInstalledApp(_ identifier: String) -> Bool {
        let urls = LSCopyApplicationURLsForBundleIdentifier(identifier as CFString, nil)?.takeRetainedValue()
        return (urls as? [URL])?.isEmpty == false
    }
}

enum ErrorDomainFilter {
    static let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._")

    /// System error domains end in "ErrorDomain" (NSCocoaErrorDomain,
    /// SMAppServiceErrorDomain, …) or start with "com.apple.".
    static func loggable(_ domain: String) -> String {
        guard domain.count <= 80, domain.unicodeScalars.allSatisfy(allowed.contains),
            domain.hasSuffix("ErrorDomain") || domain.hasPrefix("com.apple.")
        else { return "<domain>" }
        return domain
    }
}
