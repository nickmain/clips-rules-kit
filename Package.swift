// swift-tools-version: 5.10
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
            name: "CLIPSInteraction",
            targets: ["CLIPSInteraction"]),
        .library(
            name: "CLIPSUI",
            targets: ["CLIPSUI"]),
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
        .target(
            name: "CLIPSInteraction",
            dependencies: ["CLIPSCore", "CLIPSRules"],
            resources: [.copy("Resources")]),
        .target(
            name: "CLIPSUI",
            dependencies: ["CLIPSInteraction"]),
        .testTarget(
            name: "CLIPSRulesTests",
            dependencies: ["CLIPSRules"],
            resources: [.copy("Resources/samples")]),
    ]
)
