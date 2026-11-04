import Testing

@testable import Notices

/// Sleep stand-in: each call waits until the test releases it.
@MainActor
final class SleepGate {
    private var waiting: [CheckedContinuation<Void, Never>] = []
    var requested: [Duration] = []

    func sleep(_ duration: Duration) async {
        requested.append(duration)
        await withCheckedContinuation { waiting.append($0) }
    }

    func releaseOldest() async {
        guard !waiting.isEmpty else { return }
        waiting.removeFirst().resume()
        await settle()
    }

    func settle() async {
        for _ in 0..<20 { await Task.yield() }
    }
}

@MainActor
struct NoticeCenterTests {
    // AC-2: kind, symbol, text
    @Test func showsKindAndText() {
        let center = NoticeCenter(sleep: { _ in })
        center.show(.success, "Text eingefügt")
        #expect(center.current?.kind == .success)
        #expect(center.current?.text == "Text eingefügt")
        #expect(NoticeKind.success.symbolName == "checkmark.circle.fill")
        #expect(Set([NoticeKind.info, .success, .error].map(\.symbolName)).count == 3)
    }

    @Test func longTextIsShortened() {
        let notice = Notice(kind: .info, text: String(repeating: "a", count: 200))
        #expect(notice.text.count == 120)
        #expect(notice.text.hasSuffix("…"))
    }

    // AC-3: info and success close after 2 s
    @Test(arguments: [NoticeKind.info, .success])
    func closesAfterTwoSeconds(kind: NoticeKind) async {
        let gate = SleepGate()
        let center = NoticeCenter(sleep: { await gate.sleep($0) })
        center.show(kind, "x")
        await gate.settle()
        #expect(gate.requested == [.seconds(2)])
        #expect(center.current != nil)
        await gate.releaseOldest()
        #expect(center.current == nil)
    }

    // AC-4: errors do not close by themselves, but on click/Esc or a new dictation
    @Test func errorStaysUntilDismissed() async {
        let gate = SleepGate()
        let center = NoticeCenter(sleep: { await gate.sleep($0) })
        center.show(.error, "Kein Internet")
        await gate.settle()
        #expect(gate.requested.isEmpty)
        center.dictationStarted()
        #expect(center.current == nil)
        center.show(.error, "Kein Internet")
        center.dismissCurrent()
        #expect(center.current == nil)
    }

    // AC-4: a new dictation does not close an info notice
    @Test func dictationStartKeepsNonErrors() {
        let center = NoticeCenter(sleep: { _ in })
        center.show(.info, "x")
        center.dictationStarted()
        #expect(center.current?.kind == .info)
    }

    // AC-5: a new notice replaces the old; the old timer never closes the new one
    @Test func replacedTimerDoesNotCloseNewNotice() async {
        let gate = SleepGate()
        let center = NoticeCenter(sleep: { await gate.sleep($0) })
        center.show(.info, "erster")
        await gate.settle()
        center.show(.success, "zweiter")
        await gate.settle()
        #expect(center.current?.text == "zweiter")
        await gate.releaseOldest()
        #expect(center.current?.text == "zweiter")
        await gate.releaseOldest()
        #expect(center.current == nil)
    }
}
