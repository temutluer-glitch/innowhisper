// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "InnoWhisperKit",
    defaultLocalization: "de",
    platforms: [.macOS(.v26)],
    products: [
        .library(name: "AppShell", targets: ["AppShell"])
    ],
    targets: [
        .target(name: "AppShell"),
        .testTarget(name: "AppShellTests", dependencies: ["AppShell"]),
    ]
)
