import Testing

@testable import Notices

/// A notice can carry one button (PROJ-5 AC-15, design.md → Code-Aufbau).
@MainActor
struct NoticeActionTests {
    @Test func buttonRunsItsActionAndClosesTheNotice() {
        let center = NoticeCenter(sleep: { _ in })
        var pressed = 0
        center.show(.error, "Mikrofon nicht erlaubt.", action: NoticeAction(title: "Jetzt erlauben") { pressed += 1 })
        let shown = center.current
        #expect(shown?.action?.title == "Jetzt erlauben")
        center.performAction(id: shown!.id)
        #expect(pressed == 1)
        #expect(center.current == nil)
    }

    @Test func staleButtonOfAReplacedNoticeDoesNothing() {
        let center = NoticeCenter(sleep: { _ in })
        var pressed = 0
        center.show(.error, "Alt", action: NoticeAction(title: "Los") { pressed += 1 })
        let old = center.current!.id
        var newPressed = 0
        center.show(.error, "Neu", action: NoticeAction(title: "Neu los") { newPressed += 1 })
        center.performAction(id: old)
        #expect(pressed == 0)
        #expect(newPressed == 0)
        #expect(center.current?.text == "Neu")
    }

    @Test func noticesWithoutButtonStayAsBefore() {
        let center = NoticeCenter(sleep: { _ in })
        center.show(.success, "Text eingefügt")
        #expect(center.current?.action == nil)
        center.performAction(id: center.current!.id)
        #expect(center.current?.text == "Text eingefügt")
        #expect(Notice(kind: .info, text: "a") != Notice(kind: .info, text: "a"))
    }
}
