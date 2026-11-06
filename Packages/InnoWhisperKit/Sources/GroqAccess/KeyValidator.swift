import Foundation

/// What Groq said about a key (AC-4, EC-4, EC-5).
public enum KeyCheckResult: Equatable, Sendable {
    /// Groq knows the key (200, or 429 "too many requests").
    case valid
    /// Groq refuses the key (401, 403).
    case rejected
    /// No usable answer: other status, no network, time limit reached.
    case unreachable
}

/// One check: the result plus what may go into the log (never the key).
public struct KeyCheckOutcome: Equatable, Sendable {
    public let result: KeyCheckResult
    /// HTTP status from Groq, `nil` when no answer arrived.
    public let statusCode: Int?
    public let duration: Duration

    public init(result: KeyCheckResult, statusCode: Int?, duration: Duration) {
        self.result = result
        self.statusCode = statusCode
        self.duration = duration
    }
}

/// Asks Groq whether a key is valid. Tests use a stand-in.
public protocol KeyChecking: Sendable {
    func check(_ key: String) async -> KeyCheckOutcome
}

/// Checks a key against Groq's model list, at most `timeout` long (AC-4, EC-5).
public struct KeyValidator: KeyChecking {
    public typealias Send = @Sendable (URLRequest) async throws -> (Data, URLResponse)

    private let send: Send
    private let timeout: Duration

    public init(
        timeout: Duration = GroqAccessInfo.checkTimeout,
        send: @escaping Send = { try await URLSession.shared.data(for: $0) }
    ) {
        self.timeout = timeout
        self.send = send
    }

    public func check(_ key: String) async -> KeyCheckOutcome {
        var request = URLRequest(url: GroqAccessInfo.checkURL)
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = Double(timeout.components.seconds)
        let started = ContinuousClock.now
        let status = await firstStatus(of: request)
        let duration = ContinuousClock.now - started
        return KeyCheckOutcome(result: Self.result(for: status), statusCode: status, duration: duration)
    }

    /// 200 and 429 mean Groq knows the key, 401 and 403 that it refuses it;
    /// everything else, and no answer, counts as "not reachable".
    static func result(for status: Int?) -> KeyCheckResult {
        switch status {
        case 200, 429: .valid
        case 401, 403: .rejected
        default: .unreachable
        }
    }

    /// The HTTP status of the answer, or `nil` on error or when the time limit hits first.
    private func firstStatus(of request: URLRequest) async -> Int? {
        let send = send
        let timeout = timeout
        return await withTaskGroup(of: Int?.self) { group in
            group.addTask {
                guard let (_, response) = try? await send(request) else { return nil }
                return (response as? HTTPURLResponse)?.statusCode
            }
            group.addTask {
                try? await Task.sleep(for: timeout)
                return nil
            }
            let first = await group.next() ?? nil
            group.cancelAll()
            return first
        }
    }
}
