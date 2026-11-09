import Diagnostics
import Foundation

/// Sends one piece to Groq and translates the answer (design.md → "Was an
/// Groq geht", "Fehlerarten an der Groq-Schnittstelle", SEC-07).
public struct GroqTranscriber: Transcribing {
    public typealias Send = @Sendable (URLRequest) async throws -> (Data, URLResponse)

    /// Answers larger than this are not even parsed (SEC-07).
    static let maximumAnswerBytes = 5 * 1024 * 1024
    /// Waits named by Groq are capped here so odd values cannot overflow.
    static let longestAcceptedWait: Double = 24 * 60 * 60

    private let send: Send
    private let timeout: @Sendable (Duration) -> Duration

    /// - Parameters:
    ///   - timeout: Time limit for a piece of the given length; tests shorten it.
    ///   - send: Performs the HTTP request; tests inject a stand-in.
    public init(
        timeout: @escaping @Sendable (Duration) -> Duration = TranscriptionInfo.requestTimeout(for:),
        send: @escaping Send = { try await URLSession.shared.data(for: $0) }
    ) {
        self.timeout = timeout
        self.send = send
    }

    public func transcribe(
        piece: URL, duration: Duration, model: TranscriptionModel, language: TranscriptionLanguage, key: String
    ) async -> TranscriptionPieceResult {
        let started = ContinuousClock.now
        let limit = timeout(duration)
        let result: TranscriptionPieceResult
        var status: Int?
        if let audio = try? Data(contentsOf: piece) {
            let request = Self.request(
                audio: audio, fileExtension: piece.pathExtension, model: model, language: language, key: key,
                timeout: limit)
            let answer = await firstAnswer(to: request, within: limit)
            status = answer.status
            result = answer.result
        } else {
            result = .failure(.ownError(status: nil))
        }
        Self.log(
            result, status: status, model: model, language: language, audio: duration,
            took: ContinuousClock.now - started)
        return result
    }

    // MARK: Request

    /// The multipart request: file, model, language (unless automatic),
    /// temperature 0, answer format with sections. No hint text ("prompt"),
    /// no original file name (design.md → Technical Decisions).
    static func request(
        audio: Data, fileExtension: String, model: TranscriptionModel, language: TranscriptionLanguage,
        key: String, timeout: Duration, boundary: String = "InnoWhisper-\(UUID().uuidString)"
    ) -> URLRequest {
        var request = URLRequest(url: TranscriptionInfo.endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = seconds(of: timeout)

        var fields: [(String, String)] = [("model", model.groqName)]
        if let code = language.groqCode { fields.append(("language", code)) }
        fields.append(("temperature", "0"))
        fields.append(("response_format", "verbose_json"))

        var body = Data()
        for (name, value) in fields {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n")
            body.append("\(value)\r\n")
        }
        let (fileName, mimeType) = fileDescription(for: fileExtension)
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n")
        body.append("Content-Type: \(mimeType)\r\n\r\n")
        body.append(audio)
        body.append("\r\n--\(boundary)--\r\n")
        request.httpBody = body
        return request
    }

    /// A neutral file name (Groq reads the format from the extension) and the
    /// matching content type. The real file name never leaves the Mac.
    static func fileDescription(for fileExtension: String) -> (name: String, mimeType: String) {
        switch fileExtension.lowercased() {
        case "flac": ("piece.flac", "audio/flac")
        case "wav": ("piece.wav", "audio/wav")
        case "m4a": ("piece.m4a", "audio/mp4")
        case "mp3": ("piece.mp3", "audio/mpeg")
        default: ("piece", "application/octet-stream")
        }
    }

    static func seconds(of duration: Duration) -> Double {
        let (seconds, attoseconds) = duration.components
        return Double(seconds) + Double(attoseconds) / 1e18
    }

    // MARK: Sending

    private struct Answer: Sendable {
        let result: TranscriptionPieceResult
        let status: Int?
    }

    /// The translated answer, or "temporary" when the time limit hits first.
    private func firstAnswer(to request: URLRequest, within limit: Duration) async -> Answer {
        let send = send
        return await withTaskGroup(of: Answer.self) { group in
            group.addTask {
                do {
                    let (data, response) = try await send(request)
                    guard let http = response as? HTTPURLResponse else {
                        return Answer(result: .failure(.temporary), status: nil)
                    }
                    return Answer(
                        result: Self.result(status: http.statusCode, headers: http, data: data), status: http.statusCode
                    )
                } catch {
                    return Answer(result: .failure(Self.failure(for: error)), status: nil)
                }
            }
            group.addTask {
                try? await Task.sleep(for: limit)
                return Answer(result: .failure(.temporary), status: nil)
            }
            let first = await group.next() ?? Answer(result: .failure(.temporary), status: nil)
            group.cancelAll()
            return first
        }
    }

    // MARK: Translating

    /// Maps the HTTP status (and for 200 the body) to a result.
    static func result(status: Int, headers: HTTPURLResponse, data: Data) -> TranscriptionPieceResult {
        switch status {
        case 200...299:
            guard let segments = segments(from: data) else { return .failure(.unusable) }
            return .success(segments)
        case 401, 403: return .failure(.keyRejected)
        case 429: return .failure(.rateLimited(wait: wait(from: headers.value(forHTTPHeaderField: "retry-after"))))
        case 400...499: return .failure(.ownError(status: status))
        default: return .failure(.temporary)
        }
    }

    /// Connection problems count as "no internet", everything else as temporary.
    static func failure(for error: any Error) -> TranscriptionFailure {
        guard let urlError = error as? URLError else { return .temporary }
        switch urlError.code {
        case .notConnectedToInternet, .networkConnectionLost, .cannotFindHost, .cannotConnectToHost,
            .dnsLookupFailed, .dataNotAllowed:
            return .noInternet
        default:
            return .temporary
        }
    }

    /// Groq's `retry-after` in seconds; `nil` when absent or not a plain number.
    static func wait(from header: String?) -> Duration? {
        guard let header, let seconds = Double(header.trimmingCharacters(in: .whitespaces)),
            seconds.isFinite, seconds >= 0
        else { return nil }
        return .milliseconds(Int((min(seconds, longestAcceptedWait) * 1000).rounded(.up)))
    }

    /// Reads Groq's `verbose_json` answer as untrusted input (SEC-07): checks
    /// every type, removes control characters except newlines and rejects
    /// more than `maximumPieceCharacters` of text. `nil` means unusable.
    static func segments(from data: Data) -> [TranscriptSegment]? {
        guard data.count <= maximumAnswerBytes,
            let object = try? JSONSerialization.jsonObject(with: data),
            let root = object as? [String: Any]
        else { return nil }

        var segments: [TranscriptSegment] = []
        if let rawSegments = root["segments"] {
            guard let list = rawSegments as? [Any] else { return nil }
            for item in list {
                guard let entry = item as? [String: Any], let text = entry["text"] as? String else { return nil }
                segments.append(
                    TranscriptSegment(
                        text: cleaned(text), noSpeechProbability: number(entry["no_speech_prob"]),
                        averageLogProbability: number(entry["avg_logprob"])))
            }
        }
        if segments.isEmpty {
            guard let text = root["text"] as? String else { return nil }
            let clean = cleaned(text)
            segments = clean.isEmpty ? [] : [TranscriptSegment(text: clean)]
        }
        let characters = segments.reduce(0) { $0 + $1.text.count }
        guard characters <= TranscriptionInfo.maximumPieceCharacters else { return nil }
        return segments
    }

    /// A finite JSON number; booleans, strings and odd values give `nil`.
    static func number(_ value: Any?) -> Double? {
        guard let number = value as? NSNumber, CFGetTypeID(number) != CFBooleanGetTypeID() else { return nil }
        let double = number.doubleValue
        return double.isFinite ? double : nil
    }

    /// Removes control characters (Unicode category Cc) except the newline.
    static func cleaned(_ text: String) -> String {
        var scalars = String.UnicodeScalarView()
        scalars.append(
            contentsOf: text.unicodeScalars.filter { $0 == "\n" || $0.properties.generalCategory != .control })
        return String(scalars)
    }

    // MARK: Log

    /// One line per call: never text, key or file name (AC-21, SEC-01).
    static func log(
        _ result: TranscriptionPieceResult, status: Int?, model: TranscriptionModel,
        language: TranscriptionLanguage, audio: Duration, took: Duration
    ) {
        let level: Log.Level
        switch result {
        case .failure(.ownError), .failure(.unusable): level = .error
        default: level = .notice
        }
        // Status 0 means no HTTP answer arrived.
        Log.write(
            "Groq piece: model \(model), language \(language), audio \(audio), status \(status ?? 0), took \(took), result \(result)",
            category: .transcription, level: level)
    }
}

extension Data {
    fileprivate mutating func append(_ string: String) {
        append(Data(string.utf8))
    }
}
