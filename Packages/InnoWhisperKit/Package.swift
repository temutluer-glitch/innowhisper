// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "InnoWhisperKit",
    defaultLocalization: "de",
    platforms: [.macOS(.v26)],
    products: [
        .library(name: "Diagnostics", targets: ["Diagnostics"]),
        .library(name: "AppShell", targets: ["AppShell"]),
        .library(name: "Notices", targets: ["Notices"]),
        .library(name: "Onboarding", targets: ["Onboarding"]),
        .library(name: "Permissions", targets: ["Permissions"]),
        .library(name: "GroqAccess", targets: ["GroqAccess"]),
        .library(name: "Recording", targets: ["Recording"]),
        .library(name: "Transcription", targets: ["Transcription"]),
    ],
    targets: [
        .target(name: "Diagnostics"),
        .target(name: "AppShell", dependencies: ["Diagnostics"]),
        .target(name: "Notices", dependencies: ["AppShell", "Diagnostics"]),
        .target(name: "Onboarding", dependencies: ["AppShell", "Diagnostics"]),
        .target(name: "Permissions", dependencies: ["AppShell", "Diagnostics", "Onboarding"]),
        .target(name: "GroqAccess", dependencies: ["AppShell", "Diagnostics", "Onboarding"]),
        .target(
            name: "Recording", dependencies: ["AppShell", "Diagnostics", "Notices", "Onboarding", "Permissions"]),
        .target(name: "Transcription", dependencies: ["AppShell", "Diagnostics", "Notices", "Recording"]),
        .testTarget(name: "DiagnosticsTests", dependencies: ["Diagnostics"]),
        .testTarget(name: "AppShellTests", dependencies: ["AppShell"]),
        .testTarget(name: "NoticesTests", dependencies: ["Notices"]),
        .testTarget(name: "OnboardingTests", dependencies: ["Onboarding"]),
        .testTarget(name: "PermissionsTests", dependencies: ["Permissions"]),
        .testTarget(name: "GroqAccessTests", dependencies: ["GroqAccess"]),
        .testTarget(name: "RecordingTests", dependencies: ["Recording"]),
        .testTarget(name: "TranscriptionTests", dependencies: ["Transcription"]),
    ]
)
