// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CoverCraftPackage",
    platforms: [.iOS(.v18), .macOS(.v15)],
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
        .package(url: "https://github.com/apple/swift-metrics", exact: "2.7.1")
    ],
    targets: [
        // DTO module - immutable data transfer objects (foundational, no dependencies)
        .target(
            name: "CoverCraftDTO",
            dependencies: []
        ),
        
        // Core module - foundational types, protocols, DI container
        .target(
            name: "CoverCraftCore",
            dependencies: [
                "CoverCraftDTO",  // Added for legacy type aliases
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Metrics", package: "swift-metrics")
            ]
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
        
        // Test utilities - shared testing infrastructure
        .target(
            name: "TestUtilities",
            dependencies: [
                "CoverCraftCore",
                "CoverCraftDTO",
                "CoverCraftSegmentation",
                "CoverCraftFlattening",
                "CoverCraftExport",
                "CoverCraftAR"
            ],
            path: "Tests/TestUtilities"
        ),
        
        // Test targets for each module
        .testTarget(
            name: "CoverCraftCoreTests",
            dependencies: [
                "CoverCraftCore",
                "TestUtilities",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ]
        ),
        .testTarget(
            name: "CoverCraftDTOTests",
            dependencies: [
                "CoverCraftDTO",
                "TestUtilities",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ]
        ),
        .testTarget(
            name: "CoverCraftARTests", 
            dependencies: [
                "CoverCraftAR",
                "CoverCraftCore",
                "TestUtilities",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ],
            resources: [.process("Fixtures")]
        ),
        .testTarget(
            name: "CoverCraftSegmentationTests",
            dependencies: [
                "CoverCraftSegmentation",
                "CoverCraftCore",
                "TestUtilities",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ],
            resources: [.process("Fixtures")]
        ),
        .testTarget(
            name: "CoverCraftFlatteningTests", 
            dependencies: [
                "CoverCraftFlattening",
                "CoverCraftCore",
                "TestUtilities",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ],
            resources: [.process("Fixtures")]
        ),
        .testTarget(
            name: "CoverCraftExportTests",
            dependencies: [
                "CoverCraftExport", 
                "CoverCraftCore",
                "TestUtilities",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ],
            resources: [.process("Fixtures")]
        ),
        .testTarget(
            name: "CoverCraftUITests",
            dependencies: [
                "CoverCraftUI",
                "CoverCraftCore",
                "TestUtilities", 
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ],
            resources: [.process("Fixtures")]
        ),
        .testTarget(
            name: "CoverCraftFeatureTests",
            dependencies: [
                "CoverCraftFeature",
                "TestUtilities",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ]
        ),
        
        // Integration and contract test targets
        .testTarget(
            name: "IntegrationTests",
            dependencies: [
                "CoverCraftFeature",
                "TestUtilities",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ],
            resources: [.process("Fixtures")]
        ),
        .testTarget(
            name: "ContractTests", 
            dependencies: [
                "CoverCraftDTO",
                "CoverCraftCore",
                "TestUtilities",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ]
        ),
        .testTarget(
            name: "RegressionTests",
            dependencies: [
                "CoverCraftFeature",
                "TestUtilities",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ],
            resources: [.process("Fixtures")]
        ),
        
        // Quality Assurance test targets
        .testTarget(
            name: "PerformanceTests",
            dependencies: [
                "CoverCraftCore",
                "CoverCraftDTO",
                "CoverCraftSegmentation",
                "CoverCraftFlattening",
                "CoverCraftExport",
                "TestUtilities"
            ]
        ),
        .testTarget(
            name: "ConcurrencyTests",
            dependencies: [
                "CoverCraftCore",
                "CoverCraftDTO",
                "CoverCraftSegmentation",
                "CoverCraftFlattening",
                "CoverCraftExport",
                "TestUtilities"
            ]
        ),
        .testTarget(
            name: "MemoryTests",
            dependencies: [
                "CoverCraftCore",
                "CoverCraftDTO",
                "CoverCraftSegmentation",
                "CoverCraftFlattening",
                "CoverCraftExport",
                "TestUtilities"
            ]
        )
    ]
)