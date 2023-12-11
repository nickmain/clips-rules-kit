// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CLIPSRules",
    platforms: [
        .macOS(.v14), .iOS(.v17), .tvOS(.v17), .watchOS(.v9)
    ],
    products: [
        .library(
            name: "CLIPSCore",
            targets: ["CLIPSCore"]),
        .library(
            name: "CLIPSRules",
            targets: ["CLIPSRules"]),
        .library(
            name: "CLIPSConstructModels",
            targets: ["CLIPSConstructModels"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "CLIPSCore",
            dependencies: []),
        .target(
            name: "CLIPSConstructModels",
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
