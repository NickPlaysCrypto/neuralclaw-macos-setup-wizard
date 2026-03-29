// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NeuralClawSetup",
    platforms: [
        .macOS(.v13),
    ],
    targets: [
        .executableTarget(
            name: "NeuralClawSetup",
            path: "Sources"
        ),
    ]
)
