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
    ],
    targets: [
        .target(name: "Diagnostics"),
        .target(name: "AppShell", dependencies: ["Diagnostics"]),
        .target(name: "Notices", dependencies: ["AppShell", "Diagnostics"]),
        .testTarget(name: "DiagnosticsTests", dependencies: ["Diagnostics"]),
        .testTarget(name: "AppShellTests", dependencies: ["AppShell"]),
        .testTarget(name: "NoticesTests", dependencies: ["Notices"]),
    ]
)
