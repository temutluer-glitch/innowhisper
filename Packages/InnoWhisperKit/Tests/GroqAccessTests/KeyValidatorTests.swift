import Foundation
import Synchronization
import Testing

@testable import GroqAccess

private func answer(_ status: Int) -> KeyValidator.Send {
    { request in
        let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!
        return (Data(), response)
    }
}

@Suite struct KeyValidatorTests {
    @Test func groqAnswersMapToTheThreeResults() async {
        let cases: [(Int, KeyCheckResult)] = [
            (200, .valid), (429, .valid), (401, .rejected), (403, .rejected), (500, .unreachable), (404, .unreachable),
        ]
        for (status, expected) in cases {
            let outcome = await KeyValidator(send: answer(status)).check("gsk_test")
            #expect(outcome.result == expected, "status \(status)")
            #expect(outcome.statusCode == status)
        }
    }

    @Test func keyGoesOnlyIntoTheAuthorizationHeader() async {
        let seen = Mutex<URLRequest?>(nil)
        let validator = KeyValidator { request in
            seen.withLock { $0 = request }
            return try await answer(200)(request)
        }
        _ = await validator.check("gsk_secret")
        let request = seen.withLock { $0 }
        #expect(request?.value(forHTTPHeaderField: "Authorization") == "Bearer gsk_secret")
        #expect(request?.url == GroqAccessInfo.checkURL)
        #expect(request?.url?.absoluteString.contains("gsk_secret") == false)
    }

    @Test func noNetworkCountsAsNotReachable() async {
        let validator = KeyValidator { _ in throw URLError(.notConnectedToInternet) }
        let outcome = await validator.check("gsk_test")
        #expect(outcome.result == .unreachable)
        #expect(outcome.statusCode == nil)
    }

    @Test func hangingAnswerStopsAtTheTimeLimit() async {
        let validator = KeyValidator(timeout: .milliseconds(50)) { request in
            try await Task.sleep(for: .seconds(30))
            return try await answer(200)(request)
        }
        let outcome = await validator.check("gsk_test")
        #expect(outcome.result == .unreachable)
        #expect(outcome.statusCode == nil)
        #expect(outcome.duration < .seconds(2))
    }
}
