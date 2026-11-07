import AVFoundation
import CoreAudio
import Foundation
import Observation
import Synchronization

/// One audio input device as the user sees it.
public struct Microphone: Identifiable, Equatable, Hashable, Sendable {
    /// The fixed device id of macOS (`AVCaptureDevice.uniqueID`, equal to the CoreAudio device UID).
    public let id: String
    /// Localized name shown to the user.
    public let name: String

    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}

/// The audio input devices that are connected right now, for the microphone
/// choice in the settings and the onboarding (AC-12). Updates itself when a
/// device is plugged in or out and when the system microphone changes.
@MainActor
@Observable
public final class MicrophoneList {
    /// Connected microphones, sorted by name.
    public private(set) var microphones: [Microphone] = []
    /// The microphone macOS uses as its input right now ("Systemmikrofon"), if any.
    public private(set) var systemMicrophone: Microphone?

    @ObservationIgnored private nonisolated(unsafe) var observers: [NSObjectProtocol] = []
    @ObservationIgnored private nonisolated(unsafe) var defaultInputListener: AudioObjectPropertyListenerBlock?

    /// `listensForChanges: false` builds a list that only changes on `refresh()`.
    public init(listensForChanges: Bool = true) {
        refresh()
        guard listensForChanges else { return }
        let center = NotificationCenter.default
        for name in [AVCaptureDevice.wasConnectedNotification, AVCaptureDevice.wasDisconnectedNotification] {
            observers.append(
                center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                    MainActor.assumeIsolated { self?.refresh() }
                })
        }
        let listener: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
            MainActor.assumeIsolated { self?.refresh() }
        }
        var address = MicrophoneDevices.defaultInputAddress
        if AudioObjectAddPropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject), &address, DispatchQueue.main, listener) == noErr
        {
            defaultInputListener = listener
        }
    }

    deinit {
        observers.forEach(NotificationCenter.default.removeObserver)
        if let defaultInputListener {
            var address = MicrophoneDevices.defaultInputAddress
            AudioObjectRemovePropertyListenerBlock(
                AudioObjectID(kAudioObjectSystemObject), &address, DispatchQueue.main, defaultInputListener)
        }
    }

    /// Reads the connected devices and the system microphone again.
    public func refresh() {
        let devices = MicrophoneDevices.connected()
        let list = MicrophoneDevices.sorted(devices.map(Microphone.init(device:)))
        if list != microphones { microphones = list }
        let system = MicrophoneDevices.systemDefault().map(Microphone.init(device:))
        if system != systemMicrophone { systemMicrophone = system }
    }

    /// Name of the device with this id: connected now, or seen earlier while
    /// the app was running (needed for "‹Name› nicht gefunden …", AC-13).
    public func name(for id: String) -> String? {
        microphones.first { $0.id == id }?.name ?? MicrophoneNames.name(for: id)
    }
}

extension Microphone {
    init(device: AVCaptureDevice) {
        self.init(id: device.uniqueID, name: device.localizedName)
    }
}

/// Names of every device seen while the app runs. macOS only describes
/// connected devices, so the name of an unplugged microphone is only known
/// if it was connected at some point since launch (AC-13).
enum MicrophoneNames {
    private static let names = Mutex<[String: String]>([:])

    static func remember(_ microphones: [Microphone]) {
        names.withLock { stored in
            for microphone in microphones { stored[microphone.id] = microphone.name }
        }
    }

    static func name(for id: String) -> String? {
        names.withLock { $0[id] }
    }
}

/// Finds audio input devices. No permission is needed to list them.
enum MicrophoneDevices {
    static let defaultInputAddress = AudioObjectPropertyAddress(
        mSelector: kAudioHardwarePropertyDefaultInputDevice, mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain)

    /// Connected audio input devices, each once. Remembers their names.
    static func connected() -> [AVCaptureDevice] {
        let session = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.microphone, .external], mediaType: .audio, position: .unspecified)
        var seen = Set<String>()
        let devices = session.devices.filter { seen.insert($0.uniqueID).inserted }
        MicrophoneNames.remember(devices.map(Microphone.init(device:)))
        return devices
    }

    /// The device macOS uses as its input right now. Reads the setting of
    /// macOS directly (CoreAudio), so a change in System Settings counts at
    /// once; `AVCaptureDevice.default(for:)` is only the fallback.
    static func systemDefault() -> AVCaptureDevice? {
        if let uid = systemDefaultUID(), let device = AVCaptureDevice(uniqueID: uid),
            device.hasMediaType(.audio)
        {
            return device
        }
        return AVCaptureDevice.default(for: .audio)
    }

    /// UID of the default input device from CoreAudio, nil if there is none.
    static func systemDefaultUID() -> String? {
        var deviceID = AudioObjectID(kAudioObjectUnknown)
        var size = UInt32(MemoryLayout<AudioObjectID>.size)
        var address = defaultInputAddress
        guard
            AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &deviceID)
                == noErr, deviceID != kAudioObjectUnknown
        else { return nil }
        var uid: Unmanaged<CFString>?
        size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
        address.mSelector = kAudioDevicePropertyDeviceUID
        guard AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &uid) == noErr, let uid else {
            return nil
        }
        return uid.takeRetainedValue() as String
    }

    static func sorted(_ microphones: [Microphone]) -> [Microphone] {
        microphones.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }
}
