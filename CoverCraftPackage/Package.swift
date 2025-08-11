// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CoverCraftPackage",
    platforms: [.iOS(.v18)],
    products: [
        .library(name: "CoverCraftFeature", targets: ["CoverCraftFeature"])
    ],
    dependencies: [
        // Currently no third-party dependencies - using Apple frameworks only
        // Future dependencies should be added here with exact version constraints
        // Example: .package(url: "https://github.com/example/package.git", exact: "1.0.0")
    ],
    targets: [
        .target(
            name: "CoverCraftFeature",
            dependencies: []
        ),
        .testTarget(
            name: "CoverCraftFeatureTests",
            dependencies: ["CoverCraftFeature"]
        ),
    ]
)