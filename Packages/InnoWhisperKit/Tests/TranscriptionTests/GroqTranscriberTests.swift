import Foundation
import Synchronization
import Testing

@testable import Transcription

/// Stand-in for the Groq adapter, for the queue tests: answers each call with
/// the next scripted result (the last one repeats) and records the calls.
final class FakeTranscriber: Transcribing {
    struct Call: Equatable, Sendable {
        let piece: URL
        let duration: Duration
        let model: TranscriptionModel
        let language: TranscriptionLanguage
        let key: String
    }

    private let script: Mutex<[TranscriptionPieceResult]>
    private let recorded = Mutex<[Call]>([])
    private let delay: Duration?

    init(_ results: [TranscriptionPieceResult], delay: Duration? = nil) {
        script = Mutex(results)
        self.delay = delay
    }

    var calls: [Call] { recorded.withLock { $0 } }

    func transcribe(
        piece: URL, duration: Duration, model: TranscriptionModel, language: TranscriptionLanguage, key: String
    ) async -> TranscriptionPieceResult {
        recorded.withLock {
            $0.append(Call(piece: piece, duration: duration, model: model, language: language, key: key))
        }
        if let delay { try? await Task.sleep(for: delay) }
        return script.withLock { results in
            guard let first = results.first else { return .failure(.temporary) }
            if results.count > 1 { results.removeFirst() }
            return first
        }
    }
}

private func respond(_ status: Int, body: String = "", headers: [String: String] = [:]) -> GroqTranscriber.Send {
    { request in
        let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: headers)!
        return (Data(body.utf8), response)
    }
}

private let validAnswer = """
    {"text":" Hallo Welt. Zweiter Satz.","segments":[
      {"id":0,"text":" Hallo Welt.","no_speech_prob":0.01,"avg_logprob":-0.2},
      {"id":1,"text":" Zweiter Satz.","no_speech_prob":0.7,"avg_logprob":-1.4}]}
    """

@Suite struct GroqTranscriberTests {
    let piece: URL

    init() throws {
        piece = FileManager.default.temporaryDirectory
            .appendingPathComponent("geheim-kunde-\(UUID().uuidString).flac")
        try Data("FAKEAUDIO".utf8).write(to: piece)
    }

    private func run(
        _ send: @escaping GroqTranscriber.Send, language: TranscriptionLanguage = .german,
        timeout: Duration? = nil
    ) async -> TranscriptionPieceResult {
        let transcriber =
            if let timeout { GroqTranscriber(timeout: { _ in timeout }, send: send) } else {
                GroqTranscriber(send: send)
            }
        return await transcriber.transcribe(
            piece: piece, duration: .seconds(30), model: .fast, language: language, key: "gsk_secret")
    }

    /// Runs one call and returns the request that was sent.
    private func sentRequest(
        language: TranscriptionLanguage = .german, model: TranscriptionModel = .fast, duration: Duration = .seconds(30)
    ) async -> URLRequest? {
        let seen = Mutex<URLRequest?>(nil)
        let transcriber = GroqTranscriber(send: { request in
            seen.withLock { $0 = request }
            return try await respond(200, body: validAnswer)(request)
        })
        _ = await transcriber.transcribe(
            piece: piece, duration: duration, model: model, language: language, key: "gsk_secret")
        return seen.withLock { $0 }
    }

    private func body(of request: URLRequest?) -> String {
        String(decoding: request?.httpBody ?? Data(), as: UTF8.self)
    }

    // MARK: Request (AC-17, AC-18: no hint text, temperature 0; design.md → "Was an Groq geht")

    @Test func requestCarriesModelLanguageTemperatureAndFormat() async {
        let request = await sentRequest(language: .german, model: .accurate)
        let body = body(of: request)
        #expect(request?.httpMethod == "POST")
        #expect(request?.url == TranscriptionInfo.endpoint)
        #expect(body.contains("name=\"model\"\r\n\r\nwhisper-large-v3\r\n"))
        #expect(body.contains("name=\"language\"\r\n\r\nde\r\n"))
        #expect(body.contains("name=\"temperature\"\r\n\r\n0\r\n"))
        #expect(body.contains("name=\"response_format\"\r\n\r\nverbose_json\r\n"))
        #expect(
            body.contains("name=\"file\"; filename=\"piece.flac\"\r\nContent-Type: audio/flac\r\n\r\nFAKEAUDIO\r\n"))
        let contentType = request?.value(forHTTPHeaderField: "Content-Type") ?? ""
        #expect(contentType.hasPrefix("multipart/form-data; boundary="))
        let boundary = String(contentType.dropFirst("multipart/form-data; boundary=".count))
        #expect(!boundary.isEmpty)
        #expect(body.hasSuffix("\r\n--\(boundary)--\r\n"))
    }

    @Test func noHintTextIsSent() async {
        let body = body(of: await sentRequest())
        #expect(!body.contains("prompt"))
    }

    @Test func automaticLanguageIsNotSent() async {
        let body = body(of: await sentRequest(language: .automatic))
        #expect(!body.contains("name=\"language\""))
        #expect(body.contains("name=\"model\"\r\n\r\nwhisper-large-v3-turbo\r\n"))
    }

    @Test func keyOnlyInAuthorizationHeaderAndFileNameNeverSent() async {
        let request = await sentRequest()
        #expect(request?.value(forHTTPHeaderField: "Authorization") == "Bearer gsk_secret")
        #expect(request?.url?.absoluteString.contains("gsk_secret") == false)
        #expect(!body(of: request).contains("gsk_secret"))
        #expect(!body(of: request).contains("geheim-kunde"))
    }

    @Test func timeoutGrowsWithPieceLength() async {
        let short = await sentRequest(duration: .seconds(30))
        let long = await sentRequest(duration: .seconds(5 * 60))
        #expect(short?.timeoutInterval == 25)
        #expect(long?.timeoutInterval == 70)
    }

    @Test func wavPieceIsDeclaredAsWav() {
        #expect(GroqTranscriber.fileDescription(for: "WAV") == ("piece.wav", "audio/wav"))
        #expect(GroqTranscriber.fileDescription(for: "flac") == ("piece.flac", "audio/flac"))
    }

    // MARK: Answers (AC-10, AC-13, AC-14)

    @Test func validAnswerGivesSegmentsWithProbabilities() async {
        let result = await run(respond(200, body: validAnswer))
        #expect(
            result
                == .success([
                    TranscriptSegment(text: " Hallo Welt.", noSpeechProbability: 0.01, averageLogProbability: -0.2),
                    TranscriptSegment(text: " Zweiter Satz.", noSpeechProbability: 0.7, averageLogProbability: -1.4),
                ]))
    }

    @Test func segmentsWithoutProbabilitiesKeepNil() async {
        let body = #"{"segments":[{"text":"Hallo","no_speech_prob":"hoch","avg_logprob":true}]}"#
        let result = await run(respond(200, body: body))
        #expect(result == .success([TranscriptSegment(text: "Hallo")]))
    }

    @Test func answerWithoutSegmentsFallsBackToText() async {
        let result = await run(respond(200, body: #"{"text":"Nur Text"}"#))
        #expect(result == .success([TranscriptSegment(text: "Nur Text")]))
    }

    @Test func controlCharactersAreRemovedExceptNewline() async {
        let body = #"{"segments":[{"text":"A\u0000B\u0007C\nD\tE\u001bF\r"}]}"#
        let result = await run(respond(200, body: body))
        #expect(result == .success([TranscriptSegment(text: "ABC\nDEF")]))
    }

    @Test func brokenJSONIsUnusable() async {
        #expect(await run(respond(200, body: "<html>oops")) == .failure(.unusable))
        #expect(await run(respond(200, body: "[1,2]")) == .failure(.unusable))
        #expect(await run(respond(200, body: #"{"segments":"x"}"#)) == .failure(.unusable))
        #expect(await run(respond(200, body: #"{"segments":[{"no_text":1}]}"#)) == .failure(.unusable))
        #expect(await run(respond(200, body: #"{"other":1}"#)) == .failure(.unusable))
    }

    @Test func textOverLimitIsUnusable() async {
        let limit = TranscriptionInfo.maximumPieceCharacters
        let atLimit = #"{"text":"\#(String(repeating: "a", count: limit))"}"#
        let overLimit = #"{"segments":[{"text":"\#(String(repeating: "a", count: limit))"},{"text":"b"}]}"#
        #expect(
            await run(respond(200, body: atLimit))
                == .success([TranscriptSegment(text: String(repeating: "a", count: limit))]))
        #expect(await run(respond(200, body: overLimit)) == .failure(.unusable))
    }

    @Test func rejectedKeyIsReported() async {
        #expect(await run(respond(401)) == .failure(.keyRejected))
        #expect(await run(respond(403)) == .failure(.keyRejected))
    }

    @Test func limitWithRetryAfterCarriesTheWait() async {
        #expect(await run(respond(429, headers: ["retry-after": "30"])) == .failure(.rateLimited(wait: .seconds(30))))
        #expect(
            await run(respond(429, headers: ["Retry-After": "1.5"]))
                == .failure(.rateLimited(wait: .milliseconds(1500))))
    }

    @Test func limitWithoutUsableRetryAfterHasNoWait() async {
        #expect(await run(respond(429)) == .failure(.rateLimited(wait: nil)))
        #expect(await run(respond(429, headers: ["retry-after": "soon"])) == .failure(.rateLimited(wait: nil)))
        #expect(await run(respond(429, headers: ["retry-after": "-5"])) == .failure(.rateLimited(wait: nil)))
    }

    @Test func serverErrorIsTemporary() async {
        #expect(await run(respond(500)) == .failure(.temporary))
        #expect(await run(respond(503)) == .failure(.temporary))
    }

    @Test func ownRequestErrorsCarryTheStatus() async {
        #expect(await run(respond(400)) == .failure(.ownError(status: 400)))
        #expect(await run(respond(413)) == .failure(.ownError(status: 413)))
        #expect(await run(respond(415)) == .failure(.ownError(status: 415)))
        #expect(await run(respond(404)) == .failure(.ownError(status: 404)))
    }

    @Test func noConnectionIsNoInternet() async {
        for code in [URLError.notConnectedToInternet, .networkConnectionLost, .cannotFindHost, .dnsLookupFailed] {
            #expect(await run({ _ in throw URLError(code) }) == .failure(.noInternet), "\(code)")
        }
    }

    @Test func networkTimeoutIsTemporary() async {
        #expect(await run({ _ in throw URLError(.timedOut) }) == .failure(.temporary))
        #expect(await run({ _ in throw URLError(.badServerResponse) }) == .failure(.temporary))
    }

    @Test func hangingAnswerStopsAtTheTimeLimit() async {
        let started = ContinuousClock.now
        let result = await run(
            { request in
                try await Task.sleep(for: .seconds(30))
                return try await respond(200, body: validAnswer)(request)
            }, timeout: .milliseconds(50))
        #expect(result == .failure(.temporary))
        #expect(ContinuousClock.now - started < .seconds(2))
    }

    @Test func unreadablePieceIsOwnErrorWithoutUpload() async {
        let sent = Mutex(false)
        let transcriber = GroqTranscriber(send: { request in
            sent.withLock { $0 = true }
            return try await respond(200, body: validAnswer)(request)
        })
        let missing = FileManager.default.temporaryDirectory.appendingPathComponent("missing-\(UUID()).flac")
        let result = await transcriber.transcribe(
            piece: missing, duration: .seconds(5), model: .fast, language: .german, key: "gsk_secret")
        #expect(result == .failure(.ownError(status: nil)))
        #expect(sent.withLock { $0 } == false)
    }

    // MARK: Log (AC-21) and stand-in

    @Test func resultKindsHaveFixedLogNames() {
        #expect(
            TranscriptionPieceResult.success([TranscriptSegment(text: "geheim")]).logDescription.description
                == "success")
        #expect(
            TranscriptionPieceResult.failure(.rateLimited(wait: .seconds(3))).logDescription.description
                == "rateLimited")
        #expect(TranscriptionPieceResult.failure(.ownError(status: 400)).logDescription.description == "ownError")
    }

    @Test func fakeAnswersInOrderAndRecordsCalls() async {
        let fake = FakeTranscriber([.failure(.temporary), .success([TranscriptSegment(text: "ok")])])
        let first = await fake.transcribe(
            piece: piece, duration: .seconds(1), model: .fast, language: .german, key: "k")
        let second = await fake.transcribe(
            piece: piece, duration: .seconds(1), model: .fast, language: .german, key: "k")
        let third = await fake.transcribe(
            piece: piece, duration: .seconds(1), model: .fast, language: .german, key: "k")
        #expect(first == .failure(.temporary))
        #expect(second == .success([TranscriptSegment(text: "ok")]))
        #expect(third == second)
        #expect(fake.calls.count == 3)
    }
}
