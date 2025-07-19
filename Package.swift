// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ime-poc",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(
            name: "ime-poc",
            targets: ["ime-poc"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "ime-poc",
            dependencies: [],
            path: "Sources/ime-poc",
            resources: [
                .process("Resources")
            ],
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug))
            ],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("Carbon"),
                .linkedFramework("CoreGraphics"),
                .linkedFramework("ApplicationServices")
            ]
        ),
        .testTarget(
            name: "ime-pocTests",
            dependencies: ["ime-poc"],
            path: "Tests/ime-pocTests"
        )
    ]
)