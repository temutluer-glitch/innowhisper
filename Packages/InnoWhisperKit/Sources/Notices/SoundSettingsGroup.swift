import SwiftUI

/// Group "Töne" in "Allgemein" (AC-10).
public struct SoundSettingsGroup: View {
    @Bindable var player: SoundPlayer

    public init(player: SoundPlayer) {
        self.player = player
    }

    public var body: some View {
        Toggle(isOn: $player.isEnabled) {
            Text("Töne bei Start und Ende")
            Text("Ein kurzer, leiser Klang, wenn eine Aufnahme startet und endet.")
        }
    }
}
