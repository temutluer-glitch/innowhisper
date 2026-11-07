import CoreGraphics
import Observation

/// Shows at most one notice at a time (AC-2 to AC-5).
@MainActor
@Observable
public final class NoticeCenter {
    /// The visible notice, if any.
    public private(set) var current: Notice?
    /// Where the notice should sit (screen coordinates), reported by PROJ-8;
    /// nil = top centre (AC-1).
    public var anchor: CGRect?

    @ObservationIgnored private let sleep: @MainActor (Duration) async -> Void
    @ObservationIgnored private var timer: Task<Void, Never>?
    @ObservationIgnored public var onShow: (@MainActor (Notice) -> Void)?

    public init(sleep: @escaping @MainActor (Duration) async -> Void = { try? await Task.sleep(for: $0) }) {
        self.sleep = sleep
    }

    /// Shows a notice; it replaces any visible one (AC-5).
    public func show(_ kind: NoticeKind, _ text: String, action: NoticeAction? = nil) {
        timer?.cancel()
        let notice = Notice(kind: kind, text: text, action: action)
        current = notice
        onShow?(notice)
        guard kind.closesAutomatically else { return }
        // The timer belongs to exactly this notice: if it was replaced in the
        // meantime, the old timer must not close the new one (AC-5).
        timer = Task { [weak self] in
            await self?.sleep(NoticesInfo.autoDismissDelay)
            guard !Task.isCancelled else { return }
            self?.dismiss(id: notice.id)
        }
    }

    /// Closes the notice with this id, if it is still the visible one.
    public func dismiss(id: Notice.ID) {
        guard current?.id == id else { return }
        timer?.cancel()
        current = nil
    }

    /// The notice's button: runs its action and closes the notice (PROJ-5 AC-15).
    public func performAction(id: Notice.ID) {
        guard let notice = current, notice.id == id, let action = notice.action else { return }
        dismissCurrent()
        action.perform()
    }

    /// Click or Esc on an error notice (AC-4).
    public func dismissCurrent() {
        timer?.cancel()
        current = nil
    }

    /// A new dictation starts: an error notice goes away (AC-4).
    public func dictationStarted() {
        guard current?.kind == .error else { return }
        dismissCurrent()
    }
}
