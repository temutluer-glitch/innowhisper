/// Decides whether quitting needs a confirmation (AC-19, AC-20, EC-5).
public enum QuitPolicy {
    public enum Decision: Sendable, Equatable {
        case quitNow
        case askFirst
    }

    public static let confirmationTitle = "Ein Diktat läuft noch."
    public static let confirmationMessage = "Wenn du jetzt beendest, geht es verloren. Trotzdem beenden?"
    public static let cancelTitle = "Abbrechen"
    public static let quitTitle = "Beenden"

    public static func decide(activity: DictationActivity, systemIsShuttingDown: Bool) -> Decision {
        if systemIsShuttingDown { return .quitNow }
        return activity.isActive ? .askFirst : .quitNow
    }
}
