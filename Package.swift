// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "CLIPSRules",
    platforms: [
        .macOS(.v13), .iOS(.v16), .tvOS(.v16), .watchOS(.v8)
    ],
    products: [
        .library(
            name: "CLIPSCore",
            targets: ["CLIPSCore"]),
        .library(
            name: "CLIPSRules",
            targets: ["CLIPSRules"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "CLIPSCore",
            dependencies: []),
        .target(
            name: "CLIPSRules",
            dependencies: ["CLIPSCore"]),
        .testTarget(
            name: "CLIPSRulesTests",
            dependencies: ["CLIPSRules"],
            resources: [.copy("Resources/samples")]),
    ]
)
