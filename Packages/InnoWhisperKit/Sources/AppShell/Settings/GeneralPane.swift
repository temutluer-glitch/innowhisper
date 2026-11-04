import SwiftUI

/// The "Allgemein" section (AC-13 to AC-15): group "System" with the
/// autostart switch, then the groups other features register.
public struct GeneralPane: View {
    let registry: SettingsRegistry
    let loginItems: LoginItemController

    public init(registry: SettingsRegistry, loginItems: LoginItemController) {
        self.registry = registry
        self.loginItems = loginItems
    }

    public var body: some View {
        Form {
            Section("System") {
                Toggle(isOn: Binding(get: { loginItems.isEnabled }, set: { loginItems.setEnabled($0) })) {
                    Text("Start beim Anmelden")
                    Text("InnoWhisper startet automatisch, wenn du dich am Mac anmeldest.")
                }
            }
            ForEach(registry.generalGroups) { group in
                Section(group.title) { group.content() }
            }
        }
        .formStyle(.grouped)
        .onAppear { loginItems.refresh() }
    }
}
