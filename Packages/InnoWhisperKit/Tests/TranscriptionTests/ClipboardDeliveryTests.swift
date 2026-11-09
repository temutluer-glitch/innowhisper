import Notices
import Testing

@testable import Transcription

/// Fake clipboard and notice receiver; the real pasteboard is never touched.
@MainActor
private final class DeliveryRecorder {
    var pasteboard: [String] = []
    var notices: [(kind: NoticeKind, text: String, hasAction: Bool)] = []

    func makeDelivery() -> ClipboardDelivery {
        ClipboardDelivery(
            writeToPasteboard: { [unowned self] in pasteboard.append($0) },
            notify: { [unowned self] kind, text, action in
                notices.append((kind, text, action != nil))
            })
    }
}

@MainActor
@Suite struct ClipboardDeliveryTests {
    // AC-3: live text → clipboard holds exactly the text, info "Text in der Zwischenablage."
    @Test func liveTextGoesToClipboardWithNotice() {
        let recorder = DeliveryRecorder()
        recorder.makeDelivery().deliver("Hallo Jasmin, bitte ruf zurück.", kind: .live)
        #expect(recorder.pasteboard == ["Hallo Jasmin, bitte ruf zurück."])
        #expect(recorder.notices.count == 1)
        #expect(recorder.notices.first?.kind == .info)
        #expect(recorder.notices.first?.text == "Text in der Zwischenablage.")
        #expect(recorder.notices.first?.hasAction == false)
    }

    // AC-20: recovered text → clipboard, info "Nachgeholtes Diktat in der Zwischenablage."
    @Test func recoveredTextGoesToClipboardWithRecoveredNotice() {
        let recorder = DeliveryRecorder()
        recorder.makeDelivery().deliver("Erstes Diktat.\n\nZweites Diktat.", kind: .recovered)
        #expect(recorder.pasteboard == ["Erstes Diktat.\n\nZweites Diktat."])
        #expect(recorder.notices.count == 1)
        #expect(recorder.notices.first?.kind == .info)
        #expect(recorder.notices.first?.text == "Nachgeholtes Diktat in der Zwischenablage.")
    }

    // Empty (or whitespace-only) text is never delivered: no clipboard write, no notice.
    @Test(arguments: ["", "  ", "\n\n"])
    func emptyTextIsNotDelivered(text: String) {
        let recorder = DeliveryRecorder()
        let delivery = recorder.makeDelivery()
        delivery.deliver(text, kind: .live)
        delivery.deliver(text, kind: .recovered)
        #expect(recorder.pasteboard.isEmpty)
        #expect(recorder.notices.isEmpty)
    }

    // Multi-line text reaches the clipboard unchanged (line breaks, blank lines, trailing space).
    @Test func multiLineTextIsKeptUnchanged() {
        let recorder = DeliveryRecorder()
        let text = "Zeile eins\nZeile zwei  \n\nAbsatz drei: ä ö ü ß\n"
        recorder.makeDelivery().deliver(text, kind: .live)
        #expect(recorder.pasteboard == [text])
    }

    // The notice texts are the shared constants (single source of truth).
    @Test func noticeTextsComeFromTranscriptionTexts() {
        #expect(ClipboardDelivery.noticeText(for: .live) == TranscriptionTexts.textInClipboard)
        #expect(ClipboardDelivery.noticeText(for: .recovered) == TranscriptionTexts.recoveredInClipboard)
    }
}
