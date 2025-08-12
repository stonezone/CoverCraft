// Version: 1.0.0
// Test Fixtures for Regression Tests - Historical Bug Prevention

import Foundation
import CoreGraphics
import CoverCraftDTO

/// Test fixtures for regression testing to prevent reoccurrence of known bugs
@available(iOS 18.0, macOS 15.0, *)
public struct RegressionFixtures {
    
    // MARK: - Historical Bug Scenarios
    
    /// Bug #001: Mesh validation crash with empty vertex array
    public static let bug001_EmptyMeshCrash = RegressionTestCase(
        bugId: "BUG-001",
        title: "Mesh validation crash with empty vertex array",
        description: "App crashed when attempting to validate a mesh with no vertices",
        severity: .critical,
        reportedVersion: "1.0.0",
        fixedVersion: "1.0.1",
        scenario: BugScenario(
            preconditions: [
                "User completes AR scan",
                "Mesh processing pipeline initiated"
            ],
            reproductionSteps: [
                "Pass empty MeshDTO to validation",
                "Call mesh.isValid property",
                "App should handle gracefully"
            ],
            expectedBehavior: "Mesh validation should return false without crashing",
            actualBehavior: "App crashed with nil pointer exception"
        ),
        testData: RegressionTestData(
            inputData: .meshDTO(MeshFixtures.emptyMesh),
            expectedOutput: .validationResult(false),
            errorConditions: [.shouldNotCrash],
            performanceExpectations: PerformanceExpectation(
                maxExecutionTime: 0.001,
                maxMemoryUsage: 1024
            )
        ),
        reproduced: true,
        fixed: true
    )
    
    /// Bug #002: Calibration scale factor infinite loop
    public static let bug002_CalibrationInfiniteLoop = RegressionTestCase(
        bugId: "BUG-002",
        title: "Calibration scale factor causes infinite loop",
        description: "When calibration points are identical, scale calculation enters infinite loop",
        severity: .high,
        reportedVersion: "1.0.1",
        fixedVersion: "1.0.2",
        scenario: BugScenario(
            preconditions: [
                "User sets two calibration points",
                "Both points have identical coordinates"
            ],
            reproductionSteps: [
                "Create calibration with identical points",
                "Access scaleFactor property",
                "Observe behavior"
            ],
            expectedBehavior: "Should return 1.0 as fallback scale factor",
            actualBehavior: "Enters infinite loop in scale calculation"
        ),
        testData: RegressionTestData(
            inputData: .calibrationDTO(CalibrationFixtures.zeroDistance),
            expectedOutput: .scaleFactor(1.0),
            errorConditions: [.shouldNotHang, .shouldNotCrash],
            performanceExpectations: PerformanceExpectation(
                maxExecutionTime: 0.01,
                maxMemoryUsage: 2048
            )
        ),
        reproduced: true,
        fixed: true
    )
    
    /// Bug #003: Panel segmentation memory leak
    public static let bug003_SegmentationMemoryLeak = RegressionTestCase(
        bugId: "BUG-003",
        title: "Memory leak in panel segmentation algorithm",
        description: "Large meshes cause memory to grow indefinitely during segmentation",
        severity: .high,
        reportedVersion: "1.0.2",
        fixedVersion: "1.0.3",
        scenario: BugScenario(
            preconditions: [
                "Process large mesh (>50k triangles)",
                "Run segmentation algorithm"
            ],
            reproductionSteps: [
                "Load large mesh fixture",
                "Run segmentation 10 times",
                "Monitor memory usage"
            ],
            expectedBehavior: "Memory should remain stable across iterations",
            actualBehavior: "Memory grows by 50MB per iteration"
        ),
        testData: RegressionTestData(
            inputData: .meshDTO(MeshFixtures.largeMesh),
            expectedOutput: .panelArray(PanelFixtures.validPanels),
            errorConditions: [.memoryLeakDetection],
            performanceExpectations: PerformanceExpectation(
                maxExecutionTime: 5.0,
                maxMemoryUsage: 256 * 1024 * 1024 // 256MB
            )
        ),
        reproduced: true,
        fixed: true
    )
    
    /// Bug #004: Flattening produces self-intersecting polygons
    public static let bug004_SelfIntersectingPolygons = RegressionTestCase(
        bugId: "BUG-004",
        title: "Flattening algorithm creates self-intersecting polygons",
        description: "Complex 3D panels when flattened can create invalid 2D shapes",
        severity: .medium,
        reportedVersion: "1.0.3",
        fixedVersion: "1.0.4",
        scenario: BugScenario(
            preconditions: [
                "Panel has complex 3D curvature",
                "Flattening algorithm applied"
            ],
            reproductionSteps: [
                "Load complex polygon panel",
                "Apply flattening transformation",
                "Check for self-intersections"
            ],
            expectedBehavior: "Flattened polygon should not self-intersect",
            actualBehavior: "Polygon edges cross each other creating invalid shape"
        ),
        testData: RegressionTestData(
            inputData: .panelDTO(PanelFixtures.complexPolygonPanel),
            expectedOutput: .flattenedPanel(FlattenedPanelFixtures.hexagonFlattened),
            errorConditions: [.noSelfIntersections],
            performanceExpectations: PerformanceExpectation(
                maxExecutionTime: 1.0,
                maxMemoryUsage: 10 * 1024 * 1024 // 10MB
            )
        ),
        reproduced: true,
        fixed: true
    )
    
    /// Bug #005: Export PDF corruption with special characters
    public static let bug005_PDFCorruption = RegressionTestCase(
        bugId: "BUG-005",
        title: "PDF export corrupted when project name contains special characters",
        description: "Unicode characters in project names cause malformed PDF output",
        severity: .medium,
        reportedVersion: "1.0.4",
        fixedVersion: "1.0.5",
        scenario: BugScenario(
            preconditions: [
                "Project name contains Unicode characters",
                "Export to PDF format"
            ],
            reproductionSteps: [
                "Create project with name 'T-Shirt™ Design № 1'",
                "Export to PDF",
                "Verify PDF can be opened"
            ],
            expectedBehavior: "PDF should be valid and openable",
            actualBehavior: "PDF is corrupted and cannot be opened"
        ),
        testData: RegressionTestData(
            inputData: .exportConfig(ExportFixtures.pdfPatternConfig),
            expectedOutput: .validPDF,
            errorConditions: [.validPDFStructure],
            performanceExpectations: PerformanceExpectation(
                maxExecutionTime: 3.0,
                maxMemoryUsage: 50 * 1024 * 1024 // 50MB
            )
        ),
        reproduced: true,
        fixed: true
    )
    
    /// Bug #006: AR session crashes on device rotation
    public static let bug006_ARRotationCrash = RegressionTestCase(
        bugId: "BUG-006",
        title: "AR session crashes when device rotated during scanning",
        description: "Rotating device while AR session is active causes immediate crash",
        severity: .critical,
        reportedVersion: "1.0.5",
        fixedVersion: "1.0.6",
        scenario: BugScenario(
            preconditions: [
                "AR session is running",
                "User rotates device 90 degrees"
            ],
            reproductionSteps: [
                "Start AR scanning session",
                "Rotate device from portrait to landscape",
                "Observe behavior"
            ],
            expectedBehavior: "AR session should pause and resume gracefully",
            actualBehavior: "App crashes with ARKit exception"
        ),
        testData: RegressionTestData(
            inputData: .arSessionConfig(ARSessionFixtures.basicWorldTracking),
            expectedOutput: .sessionState(.paused),
            errorConditions: [.shouldNotCrash, .gracefulRotationHandling],
            performanceExpectations: PerformanceExpectation(
                maxExecutionTime: 2.0,
                maxMemoryUsage: 100 * 1024 * 1024 // 100MB
            )
        ),
        reproduced: true,
        fixed: true
    )
    
    /// Bug #007: UI becomes unresponsive during large export
    public static let bug007_UIFreezeOnExport = RegressionTestCase(
        bugId: "BUG-007",
        title: "UI freezes during large pattern export",
        description: "Exporting complex patterns blocks main thread causing UI freeze",
        severity: .medium,
        reportedVersion: "1.0.6",
        fixedVersion: "1.0.7",
        scenario: BugScenario(
            preconditions: [
                "Complex pattern with >20 panels",
                "Export to high-resolution PDF"
            ],
            reproductionSteps: [
                "Load complex garment project",
                "Initiate PDF export at 600 DPI",
                "Attempt to interact with UI"
            ],
            expectedBehavior: "UI should remain responsive with progress indicator",
            actualBehavior: "UI completely frozen for 30+ seconds"
        ),
        testData: RegressionTestData(
            inputData: .flattenedPanelArray(FlattenedPanelFixtures.validFlattenedPanels),
            expectedOutput: .exportProgress(0.5),
            errorConditions: [.mainThreadNotBlocked],
            performanceExpectations: PerformanceExpectation(
                maxExecutionTime: 10.0,
                maxMemoryUsage: 200 * 1024 * 1024 // 200MB
            )
        ),
        reproduced: true,
        fixed: true
    )
    
    /// Bug #008: Negative coordinates in flattened panels
    public static let bug008_NegativeCoordinates = RegressionTestCase(
        bugId: "BUG-008",
        title: "Flattened panels can have negative coordinates",
        description: "Panel flattening doesn't normalize coordinates, causing negative values",
        severity: .low,
        reportedVersion: "1.0.7",
        fixedVersion: "1.0.8",
        scenario: BugScenario(
            preconditions: [
                "3D panel extends in negative coordinate space",
                "Flattening algorithm applied"
            ],
            reproductionSteps: [
                "Create panel with negative 3D coordinates",
                "Flatten panel to 2D",
                "Check resulting coordinate bounds"
            ],
            expectedBehavior: "All coordinates should be positive after normalization",
            actualBehavior: "Some coordinates remain negative"
        ),
        testData: RegressionTestData(
            inputData: .panelDTO(PanelFixtures.complexPolygonPanel),
            expectedOutput: .coordinateBounds(minX: 0.0, minY: 0.0),
            errorConditions: [.allCoordinatesPositive],
            performanceExpectations: PerformanceExpectation(
                maxExecutionTime: 0.5,
                maxMemoryUsage: 5 * 1024 * 1024 // 5MB
            )
        ),
        reproduced: true,
        fixed: true
    )
    
    // MARK: - Performance Regression Cases
    
    /// Perf Regression #001: Mesh processing time increased 3x in v1.1.0
    public static let perfRegression001_MeshProcessing = PerformanceRegressionCase(
        regressionId: "PERF-001",
        title: "Mesh processing performance degradation",
        description: "Mesh processing time increased significantly in v1.1.0",
        baselineVersion: "1.0.8",
        regressionVersion: "1.1.0",
        fixedVersion: "1.1.1",
        operation: .meshProcessing,
        testData: PerformanceTestData(
            inputSize: "Large mesh (50k triangles)",
            baselineMetrics: PerformanceMetrics(
                executionTime: 2.5,
                memoryUsage: 100 * 1024 * 1024,
                cpuUsage: 0.6
            ),
            regressionMetrics: PerformanceMetrics(
                executionTime: 7.8, // 3x slower!
                memoryUsage: 300 * 1024 * 1024, // 3x memory
                cpuUsage: 0.9
            ),
            currentMetrics: PerformanceMetrics(
                executionTime: 2.2, // Better than baseline
                memoryUsage: 95 * 1024 * 1024,
                cpuUsage: 0.55
            )
        ),
        rootCause: "Inefficient algorithm introduced in mesh optimization",
        fixed: true
    )
    
    /// Perf Regression #002: Memory usage spike in segmentation
    public static let perfRegression002_MemorySpike = PerformanceRegressionCase(
        regressionId: "PERF-002",
        title: "Excessive memory usage in panel segmentation",
        description: "Memory consumption doubled for same input mesh",
        baselineVersion: "1.1.0",
        regressionVersion: "1.1.1",
        fixedVersion: "1.1.2",
        operation: .panelSegmentation,
        testData: PerformanceTestData(
            inputSize: "Standard T-shirt mesh",
            baselineMetrics: PerformanceMetrics(
                executionTime: 1.2,
                memoryUsage: 50 * 1024 * 1024,
                cpuUsage: 0.4
            ),
            regressionMetrics: PerformanceMetrics(
                executionTime: 1.3,
                memoryUsage: 120 * 1024 * 1024, // 2.4x memory
                cpuUsage: 0.45
            ),
            currentMetrics: PerformanceMetrics(
                executionTime: 1.1,
                memoryUsage: 48 * 1024 * 1024,
                cpuUsage: 0.38
            )
        ),
        rootCause: "Memory leaks in connectivity analysis",
        fixed: true
    )
    
    // MARK: - Edge Case Regression Tests
    
    /// Edge case that previously caused data corruption
    public static let edgeCase001_DataCorruption = EdgeCaseRegressionTest(
        caseId: "EDGE-001",
        title: "Mesh with single degenerate triangle corrupts segmentation",
        description: "Mesh containing degenerate triangle causes segmentation data corruption",
        inputData: EdgeCaseTestData(
            mesh: MeshFixtures.degenerateTriangles,
            expectedBehavior: "Should skip degenerate triangles and continue processing",
            previousBehavior: "Corrupted all subsequent triangle data"
        ),
        validationCriteria: [
            .meshTopologyPreserved,
            .noDataCorruption,
            .gracefulDegenerateHandling
        ],
        reproduced: true,
        fixed: true
    )
    
    /// Edge case with extreme scale values
    public static let edgeCase002_ExtremeScale = EdgeCaseRegressionTest(
        caseId: "EDGE-002", 
        title: "Extreme calibration scale values cause overflow",
        description: "Very small/large scale factors cause numeric overflow",
        inputData: EdgeCaseTestData(
            mesh: MeshFixtures.tinyDistance,
            expectedBehavior: "Should clamp scale factors to reasonable bounds",
            previousBehavior: "Numeric overflow causing infinite coordinates"
        ),
        validationCriteria: [
            .scaleFactorBounded,
            .noNumericOverflow,
            .coordinatesFinite
        ],
        reproduced: true,
        fixed: true
    )
    
    // MARK: - Collections
    
    /// All historical bug regression tests
    public static let allBugRegressionTests: [RegressionTestCase] = [
        bug001_EmptyMeshCrash,
        bug002_CalibrationInfiniteLoop,
        bug003_SegmentationMemoryLeak,
        bug004_SelfIntersectingPolygons,
        bug005_PDFCorruption,
        bug006_ARRotationCrash,
        bug007_UIFreezeOnExport,
        bug008_NegativeCoordinates
    ]
    
    /// All performance regression tests
    public static let allPerformanceRegressionTests: [PerformanceRegressionCase] = [
        perfRegression001_MeshProcessing,
        perfRegression002_MemorySpike
    ]
    
    /// All edge case regression tests
    public static let allEdgeCaseRegressionTests: [EdgeCaseRegressionTest] = [
        edgeCase001_DataCorruption,
        edgeCase002_ExtremeScale
    ]
    
    /// Critical bug tests (crashes, data loss)
    public static let criticalBugTests = allBugRegressionTests.filter { $0.severity == .critical }
    
    /// Fixed bug tests
    public static let fixedBugTests = allBugRegressionTests.filter { $0.fixed }
    
    /// Open bug tests (not yet fixed)
    public static let openBugTests = allBugRegressionTests.filter { !$0.fixed }
    
    // MARK: - Factory Methods
    
    /// Create regression test for specific bug ID
    public static func regressionTestForBug(_ bugId: String) -> RegressionTestCase? {
        allBugRegressionTests.first { $0.bugId == bugId }
    }
    
    /// Get all tests for specific version
    public static func testsForVersion(_ version: String) -> [RegressionTestCase] {
        allBugRegressionTests.filter { $0.reportedVersion == version || $0.fixedVersion == version }
    }
    
    /// Get tests by severity
    public static func testsBySeverity(_ severity: BugSeverity) -> [RegressionTestCase] {
        allBugRegressionTests.filter { $0.severity == severity }
    }
    
    /// Create test data for specific operation
    public static func performanceTestDataFor(_ operation: PerformanceOperation) -> PerformanceTestData {
        switch operation {
        case .meshProcessing:
            return perfRegression001_MeshProcessing.testData
        case .panelSegmentation:
            return perfRegression002_MemorySpike.testData
        case .patternFlattening:
            return PerformanceTestData(
                inputSize: "Complex garment",
                baselineMetrics: PerformanceMetrics(executionTime: 3.0, memoryUsage: 80 * 1024 * 1024, cpuUsage: 0.5),
                regressionMetrics: PerformanceMetrics(executionTime: 5.0, memoryUsage: 120 * 1024 * 1024, cpuUsage: 0.7),
                currentMetrics: PerformanceMetrics(executionTime: 2.8, memoryUsage: 75 * 1024 * 1024, cpuUsage: 0.48)
            )
        case .exportRendering:
            return PerformanceTestData(
                inputSize: "High-res PDF export",
                baselineMetrics: PerformanceMetrics(executionTime: 5.0, memoryUsage: 150 * 1024 * 1024, cpuUsage: 0.4),
                regressionMetrics: PerformanceMetrics(executionTime: 15.0, memoryUsage: 400 * 1024 * 1024, cpuUsage: 0.8),
                currentMetrics: PerformanceMetrics(executionTime: 4.5, memoryUsage: 140 * 1024 * 1024, cpuUsage: 0.38)
            )
        }
    }
}

// MARK: - Supporting Data Structures

@available(iOS 18.0, macOS 15.0, *)
public struct RegressionTestCase: Sendable, Equatable {
    public let bugId: String
    public let title: String
    public let description: String
    public let severity: BugSeverity
    public let reportedVersion: String
    public let fixedVersion: String?
    public let scenario: BugScenario
    public let testData: RegressionTestData
    public let reproduced: Bool
    public let fixed: Bool
    
    public init(
        bugId: String,
        title: String,
        description: String,
        severity: BugSeverity,
        reportedVersion: String,
        fixedVersion: String?,
        scenario: BugScenario,
        testData: RegressionTestData,
        reproduced: Bool,
        fixed: Bool
    ) {
        self.bugId = bugId
        self.title = title
        self.description = description
        self.severity = severity
        self.reportedVersion = reportedVersion
        self.fixedVersion = fixedVersion
        self.scenario = scenario
        self.testData = testData
        self.reproduced = reproduced
        self.fixed = fixed
    }
}

@available(iOS 18.0, macOS 15.0, *)
public enum BugSeverity: String, Sendable, CaseIterable {
    case critical = "critical"   // Crashes, data loss
    case high = "high"          // Major functionality broken
    case medium = "medium"      // Minor functionality issues
    case low = "low"           // Cosmetic, usability issues
}

@available(iOS 18.0, macOS 15.0, *)
public struct BugScenario: Sendable, Equatable {
    public let preconditions: [String]
    public let reproductionSteps: [String]
    public let expectedBehavior: String
    public let actualBehavior: String
    
    public init(
        preconditions: [String],
        reproductionSteps: [String],
        expectedBehavior: String,
        actualBehavior: String
    ) {
        self.preconditions = preconditions
        self.reproductionSteps = reproductionSteps
        self.expectedBehavior = expectedBehavior
        self.actualBehavior = actualBehavior
    }
}

@available(iOS 18.0, macOS 15.0, *)
public struct RegressionTestData: Sendable, Equatable {
    public let inputData: TestInputData
    public let expectedOutput: TestOutputData
    public let errorConditions: [ErrorCondition]
    public let performanceExpectations: PerformanceExpectation
    
    public init(
        inputData: TestInputData,
        expectedOutput: TestOutputData,
        errorConditions: [ErrorCondition],
        performanceExpectations: PerformanceExpectation
    ) {
        self.inputData = inputData
        self.expectedOutput = expectedOutput
        self.errorConditions = errorConditions
        self.performanceExpectations = performanceExpectations
    }
}

@available(iOS 18.0, macOS 15.0, *)
public enum TestInputData: Sendable, Equatable {
    case meshDTO(MeshDTO)
    case calibrationDTO(CalibrationDTO)
    case panelDTO(PanelDTO)
    case flattenedPanelDTO(FlattenedPanelDTO)
    case exportConfig(ExportConfiguration)
    case arSessionConfig(ARSessionConfig)
    case flattenedPanelArray([FlattenedPanelDTO])
}

@available(iOS 18.0, macOS 15.0, *)
public enum TestOutputData: Sendable, Equatable {
    case validationResult(Bool)
    case scaleFactor(Float)
    case panelArray([PanelDTO])
    case flattenedPanel(FlattenedPanelDTO)
    case validPDF
    case sessionState(ARSessionState)
    case exportProgress(Double)
    case coordinateBounds(minX: Double, minY: Double)
}

@available(iOS 18.0, macOS 15.0, *)
public enum ErrorCondition: Sendable, Equatable {
    case shouldNotCrash
    case shouldNotHang
    case memoryLeakDetection
    case noSelfIntersections
    case validPDFStructure
    case gracefulRotationHandling
    case mainThreadNotBlocked
    case allCoordinatesPositive
}

@available(iOS 18.0, macOS 15.0, *)
public struct PerformanceExpectation: Sendable, Equatable {
    public let maxExecutionTime: TimeInterval
    public let maxMemoryUsage: Int64
    
    public init(maxExecutionTime: TimeInterval, maxMemoryUsage: Int64) {
        self.maxExecutionTime = maxExecutionTime
        self.maxMemoryUsage = maxMemoryUsage
    }
}

@available(iOS 18.0, macOS 15.0, *)
public struct PerformanceRegressionCase: Sendable, Equatable {
    public let regressionId: String
    public let title: String
    public let description: String
    public let baselineVersion: String
    public let regressionVersion: String
    public let fixedVersion: String?
    public let operation: PerformanceOperation
    public let testData: PerformanceTestData
    public let rootCause: String
    public let fixed: Bool
    
    public init(
        regressionId: String,
        title: String,
        description: String,
        baselineVersion: String,
        regressionVersion: String,
        fixedVersion: String?,
        operation: PerformanceOperation,
        testData: PerformanceTestData,
        rootCause: String,
        fixed: Bool
    ) {
        self.regressionId = regressionId
        self.title = title
        self.description = description
        self.baselineVersion = baselineVersion
        self.regressionVersion = regressionVersion
        self.fixedVersion = fixedVersion
        self.operation = operation
        self.testData = testData
        self.rootCause = rootCause
        self.fixed = fixed
    }
}

@available(iOS 18.0, macOS 15.0, *)
public enum PerformanceOperation: String, Sendable, CaseIterable {
    case meshProcessing = "meshProcessing"
    case panelSegmentation = "panelSegmentation"
    case patternFlattening = "patternFlattening"
    case exportRendering = "exportRendering"
}

@available(iOS 18.0, macOS 15.0, *)
public struct PerformanceTestData: Sendable, Equatable {
    public let inputSize: String
    public let baselineMetrics: PerformanceMetrics
    public let regressionMetrics: PerformanceMetrics
    public let currentMetrics: PerformanceMetrics
    
    public init(
        inputSize: String,
        baselineMetrics: PerformanceMetrics,
        regressionMetrics: PerformanceMetrics,
        currentMetrics: PerformanceMetrics
    ) {
        self.inputSize = inputSize
        self.baselineMetrics = baselineMetrics
        self.regressionMetrics = regressionMetrics
        self.currentMetrics = currentMetrics
    }
}

@available(iOS 18.0, macOS 15.0, *)
public struct PerformanceMetrics: Sendable, Equatable {
    public let executionTime: TimeInterval
    public let memoryUsage: Int64
    public let cpuUsage: Double
    
    public init(executionTime: TimeInterval, memoryUsage: Int64, cpuUsage: Double) {
        self.executionTime = executionTime
        self.memoryUsage = memoryUsage
        self.cpuUsage = max(0.0, min(1.0, cpuUsage))
    }
}

@available(iOS 18.0, macOS 15.0, *)
public struct EdgeCaseRegressionTest: Sendable, Equatable {
    public let caseId: String
    public let title: String
    public let description: String
    public let inputData: EdgeCaseTestData
    public let validationCriteria: [ValidationCriterion]
    public let reproduced: Bool
    public let fixed: Bool
    
    public init(
        caseId: String,
        title: String,
        description: String,
        inputData: EdgeCaseTestData,
        validationCriteria: [ValidationCriterion],
        reproduced: Bool,
        fixed: Bool
    ) {
        self.caseId = caseId
        self.title = title
        self.description = description
        self.inputData = inputData
        self.validationCriteria = validationCriteria
        self.reproduced = reproduced
        self.fixed = fixed
    }
}

@available(iOS 18.0, macOS 15.0, *)
public struct EdgeCaseTestData: Sendable, Equatable {
    public let mesh: MeshDTO
    public let expectedBehavior: String
    public let previousBehavior: String
    
    public init(mesh: MeshDTO, expectedBehavior: String, previousBehavior: String) {
        self.mesh = mesh
        self.expectedBehavior = expectedBehavior
        self.previousBehavior = previousBehavior
    }
}

@available(iOS 18.0, macOS 15.0, *)
public enum ValidationCriterion: String, Sendable, CaseIterable {
    case meshTopologyPreserved = "meshTopologyPreserved"
    case noDataCorruption = "noDataCorruption"
    case gracefulDegenerateHandling = "gracefulDegenerateHandling"
    case scaleFactorBounded = "scaleFactorBounded"
    case noNumericOverflow = "noNumericOverflow"
    case coordinatesFinite = "coordinatesFinite"
}