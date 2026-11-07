import Observation
import Onboarding
import SwiftUI

/// Outcome of the probe in the onboarding step (AC-19, AC-20). In memory only:
/// once the step is done the onboarding progress remembers it.
@MainActor
@Observable
public final class ShortcutProbe {
    public enum Result: Equatable {
        case worked
        case nothingHeard
    }

    public private(set) var result: Result?
    public var succeeded: Bool { result == .worked }

    public init() {}

    public func record(worked: Bool) {
        result = worked ? .worked : .nothingHeard
    }
}

/// The onboarding step "Tastenkürzel" (AC-19, AC-20, EC-6).
public enum ShortcutStep {
    public static let title = "Tastenkürzel"

    @MainActor
    public static func make(
        controller: RecordingController,
        probe: ShortcutProbe,
        shortcuts: ShortcutStore,
        microphone: MicrophoneChoiceStore,
        microphones: MicrophoneList
    ) -> OnboardingStep {
        controller.onProbeResult = { probe.record(worked: $0) }
        return OnboardingStep(
            id: RecordingInfo.stepID, logName: "shortcut", order: RecordingInfo.stepOrder, title: title,
            completesAutomatically: false,
            isSatisfied: { probe.succeeded },
            content: {
                ShortcutStepView(
                    controller: controller, probe: probe, shortcuts: shortcuts, microphone: microphone,
                    microphones: microphones)
            })
    }
}

struct ShortcutStepView: View {
    let controller: RecordingController
    let probe: ShortcutProbe
    let shortcuts: ShortcutStore
    let microphone: MicrophoneChoiceStore
    let microphones: MicrophoneList

    var body: some View {
        OnboardingPageLayout(
            symbol: "keyboard", title: ShortcutStep.title,
            text: ShortcutHint.text(for: shortcuts.shortcut, mode: shortcuts.mode)
        ) {
            VStack(alignment: .leading, spacing: 12) {
                LevelMeter(level: controller.level)
                MicrophonePicker(store: microphone, list: microphones)
                if let result = probe.result {
                    ProbeResultLine(result: result)
                } else {
                    Text("Probiere es jetzt einmal aus. Die Probe wird nicht eingefügt.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: 360)
        }
        .onAppear { controller.gate = .probe }
        .onDisappear { controller.gate = .blocked }
    }
}

/// Green check mark when the probe worked, otherwise what to do (AC-20).
struct ProbeResultLine: View {
    let result: ShortcutProbe.Result

    var body: some View {
        Label {
            Text(result == .worked ? RecordingTexts.probeWorked : RecordingTexts.nothingHeard)
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: result == .worked ? "checkmark.circle.fill" : "exclamationmark.circle")
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(result == .worked ? .green : .orange)
        }
        .font(.callout)
        .accessibilityElement(children: .combine)
    }
}
