// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CoverCraftPackage",
    platforms: [.iOS(.v18)],
    products: [
        .library(name: "CoverCraftCore", targets: ["CoverCraftCore"]),
        .library(name: "CoverCraftDTO", targets: ["CoverCraftDTO"]),
        .library(name: "CoverCraftAR", targets: ["CoverCraftAR"]),
        .library(name: "CoverCraftSegmentation", targets: ["CoverCraftSegmentation"]),
        .library(name: "CoverCraftFlattening", targets: ["CoverCraftFlattening"]),
        .library(name: "CoverCraftExport", targets: ["CoverCraftExport"]),
        .library(name: "CoverCraftUI", targets: ["CoverCraftUI"]),
        .library(name: "CoverCraftFeature", targets: ["CoverCraftFeature"])
    ],
    dependencies: [
        // Testing dependencies
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", exact: "1.17.4"),
        // Logging infrastructure
        .package(url: "https://github.com/apple/swift-log", exact: "1.6.1"),
        // Metrics infrastructure  
        .package(url: "https://github.com/apple/swift-metrics", exact: "2.5.0")
    ],
    targets: [
        // Core module - foundational types, protocols, DI container
        .target(
            name: "CoverCraftCore",
            dependencies: [
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Metrics", package: "swift-metrics")
            ]
        ),
        
        // DTO module - immutable data transfer objects
        .target(
            name: "CoverCraftDTO",
            dependencies: []
        ),
        
        // AR scanning functionality
        .target(
            name: "CoverCraftAR", 
            dependencies: [
                "CoverCraftCore",
                "CoverCraftDTO"
            ]
        ),
        
        // Mesh segmentation service
        .target(
            name: "CoverCraftSegmentation",
            dependencies: [
                "CoverCraftCore", 
                "CoverCraftDTO"
            ]
        ),
        
        // Pattern flattening service
        .target(
            name: "CoverCraftFlattening",
            dependencies: [
                "CoverCraftCore",
                "CoverCraftDTO"
            ]
        ),
        
        // Export functionality
        .target(
            name: "CoverCraftExport",
            dependencies: [
                "CoverCraftCore",
                "CoverCraftDTO"
            ]
        ),
        
        // UI components and views
        .target(
            name: "CoverCraftUI",
            dependencies: [
                "CoverCraftCore",
                "CoverCraftDTO",
                "CoverCraftAR",
                "CoverCraftSegmentation", 
                "CoverCraftFlattening",
                "CoverCraftExport"
            ]
        ),
        
        // Main feature module - orchestrates all other modules
        .target(
            name: "CoverCraftFeature",
            dependencies: [
                "CoverCraftCore",
                "CoverCraftDTO", 
                "CoverCraftAR",
                "CoverCraftSegmentation",
                "CoverCraftFlattening",
                "CoverCraftExport",
                "CoverCraftUI"
            ]
        ),
        
        // Test targets for each module
        .testTarget(
            name: "CoverCraftCoreTests",
            dependencies: [
                "CoverCraftCore",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ]
        ),
        .testTarget(
            name: "CoverCraftDTOTests",
            dependencies: [
                "CoverCraftDTO",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ]
        ),
        .testTarget(
            name: "CoverCraftARTests", 
            dependencies: [
                "CoverCraftAR",
                "CoverCraftCore",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ]
        ),
        .testTarget(
            name: "CoverCraftSegmentationTests",
            dependencies: [
                "CoverCraftSegmentation",
                "CoverCraftCore",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ]
        ),
        .testTarget(
            name: "CoverCraftFlatteningTests", 
            dependencies: [
                "CoverCraftFlattening",
                "CoverCraftCore",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ]
        ),
        .testTarget(
            name: "CoverCraftExportTests",
            dependencies: [
                "CoverCraftExport", 
                "CoverCraftCore",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ]
        ),
        .testTarget(
            name: "CoverCraftUITests",
            dependencies: [
                "CoverCraftUI",
                "CoverCraftCore", 
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ]
        ),
        .testTarget(
            name: "CoverCraftFeatureTests",
            dependencies: [
                "CoverCraftFeature",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ]
        ),
        
        // Integration and contract test targets
        .testTarget(
            name: "IntegrationTests",
            dependencies: [
                "CoverCraftFeature",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ]
        ),
        .testTarget(
            name: "ContractTests", 
            dependencies: [
                "CoverCraftDTO",
                "CoverCraftCore",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ]
        ),
        .testTarget(
            name: "RegressionTests",
            dependencies: [
                "CoverCraftFeature",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ],
            resources: [.process("Fixtures")]
        )
    ]
)