import Diagnostics
import Foundation
import Observation
import SwiftUI

/// The chosen microphone (AC-12, AC-13). Besides the device id the name is
/// kept too: macOS cannot name a microphone that is not plugged in, but the
/// notice of AC-13 needs it (deviation from design.md, see Bau-Notizen).
@MainActor
@Observable
public final class MicrophoneChoiceStore {
    /// `nil` = system microphone.
    public private(set) var id: String?
    public private(set) var name: String?

    @ObservationIgnored private let defaults: UserDefaults
    static let nameDefaultsKey = "recording.microphoneName"

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let stored = defaults.string(forKey: RecordingInfo.microphoneDefaultsKey)
        id = (stored?.isEmpty ?? true) ? nil : stored
        name = id == nil ? nil : defaults.string(forKey: Self.nameDefaultsKey)
    }

    /// The choice for the controller: id plus remembered name.
    public var chosen: (id: String, name: String?)? {
        id.map { (id: $0, name: name) }
    }

    public func choose(_ microphone: Microphone?) {
        id = microphone?.id
        name = microphone?.name
        if let microphone {
            defaults.set(microphone.id, forKey: RecordingInfo.microphoneDefaultsKey)
            defaults.set(microphone.name, forKey: Self.nameDefaultsKey)
        } else {
            defaults.removeObject(forKey: RecordingInfo.microphoneDefaultsKey)
            defaults.removeObject(forKey: Self.nameDefaultsKey)
        }
        Log.write("Microphone choice changed, system microphone \(microphone == nil)", category: .recording)
    }
}

/// Picker "Systemmikrofon" or one connected microphone (AC-12). A chosen
/// microphone that is unplugged stays visible as "… (nicht angeschlossen)".
public struct MicrophonePicker: View {
    let store: MicrophoneChoiceStore
    let list: MicrophoneList

    public init(store: MicrophoneChoiceStore, list: MicrophoneList) {
        self.store = store
        self.list = list
    }

    public var body: some View {
        Picker("Mikrofon", selection: selection) {
            Text(systemTitle).tag(String?.none)
            ForEach(list.microphones) { microphone in
                Text(microphone.name).tag(String?.some(microphone.id))
            }
            if let id = store.id, !list.microphones.contains(where: { $0.id == id }) {
                Text("\(store.name ?? "Gewähltes Mikrofon") (nicht angeschlossen)").tag(String?.some(id))
            }
        }
        .onAppear { list.refresh() }
    }

    private var systemTitle: String {
        if let system = list.systemMicrophone { return "Systemmikrofon (\(system.name))" }
        return "Systemmikrofon"
    }

    private var selection: Binding<String?> {
        Binding(
            get: { store.id },
            set: { newID in
                guard newID != store.id else { return }
                store.choose(newID.flatMap { id in list.microphones.first { $0.id == id } })
            })
    }
}
