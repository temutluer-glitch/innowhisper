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
    ],
    targets: [
        .target(name: "Diagnostics"),
        .target(name: "AppShell", dependencies: ["Diagnostics"]),
        .target(name: "Notices", dependencies: ["AppShell", "Diagnostics"]),
        .target(name: "Onboarding", dependencies: ["AppShell", "Diagnostics"]),
        .target(name: "Permissions", dependencies: ["AppShell", "Diagnostics", "Onboarding"]),
        .testTarget(name: "DiagnosticsTests", dependencies: ["Diagnostics"]),
        .testTarget(name: "AppShellTests", dependencies: ["AppShell"]),
        .testTarget(name: "NoticesTests", dependencies: ["Notices"]),
        .testTarget(name: "OnboardingTests", dependencies: ["Onboarding"]),
        .testTarget(name: "PermissionsTests", dependencies: ["Permissions"]),
    ]
)
