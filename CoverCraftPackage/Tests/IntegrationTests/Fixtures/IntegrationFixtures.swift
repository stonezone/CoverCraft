// Version: 1.0.0
// Test Fixtures for Integration Tests - Cross-Module Data Flows

import Foundation
import CoreGraphics
import CoverCraftDTO

/// Test fixtures for integration testing between modules
@available(iOS 18.0, *)
public struct IntegrationFixtures {
    
    // MARK: - Complete Workflow Scenarios
    
    /// End-to-end T-shirt scanning and pattern generation workflow
    public static let tshirtWorkflow = WorkflowScenario(
        name: "T-Shirt Complete Workflow",
        description: "Full workflow from AR scan to exported pattern",
        steps: [
            .arInitialization(ARSessionFixtures.basicWorldTracking),
            .meshCapture(MeshFixtures.tshirtMesh),
            .calibration(CalibrationFixtures.ruler30cm),
            .segmentation(PanelFixtures.tshirtPanelSet),
            .flattening(FlattenedPanelFixtures.tshirtFlattenedSet),
            .export(ExportFixtures.pdfPatternConfig, expectedData: ExportFixtures.samplePDFData)
        ],
        expectedDuration: 120.0, // 2 minutes
        requiredDeviceCapabilities: [.lidar, .worldTracking],
        testData: WorkflowTestData(
            inputMesh: MeshFixtures.tshirtMesh,
            calibrationData: CalibrationFixtures.ruler30cm,
            expectedPanelCount: 4,
            expectedOutputSize: CGSize(width: 612, height: 792),
            validationChecks: [
                .meshIsValid,
                .calibrationComplete,
                .allPanelsSegmented,
                .flatteningSuccessful,
                .exportGenerated
            ]
        )
    )
    
    /// Simple cube workflow (basic geometric shape)
    public static let cubeWorkflow = WorkflowScenario(
        name: "Simple Cube Workflow",
        description: "Basic workflow with simple geometric mesh",
        steps: [
            .arInitialization(ARSessionFixtures.minimalConfig),
            .meshCapture(MeshFixtures.simpleCube),
            .calibration(CalibrationFixtures.creditCard),
            .segmentation([PanelFixtures.rectangularPanel]),
            .flattening([FlattenedPanelFixtures.rectangularFlattened]),
            .export(ExportFixtures.svgDigitalConfig, expectedData: ExportFixtures.sampleSVGData)
        ],
        expectedDuration: 30.0,
        requiredDeviceCapabilities: [.worldTracking],
        testData: WorkflowTestData(
            inputMesh: MeshFixtures.simpleCube,
            calibrationData: CalibrationFixtures.creditCard,
            expectedPanelCount: 1,
            expectedOutputSize: CGSize(width: 1200, height: 1600),
            validationChecks: [
                .meshIsValid,
                .calibrationComplete,
                .allPanelsSegmented,
                .flatteningSuccessful,
                .exportGenerated
            ]
        )
    )
    
    /// Complex garment workflow (stress test)
    public static let complexGarmentWorkflow = WorkflowScenario(
        name: "Complex Garment Workflow",
        description: "High-complexity workflow with detailed mesh",
        steps: [
            .arInitialization(ARSessionFixtures.highQualityScanning),
            .meshCapture(MeshFixtures.largeMesh),
            .calibration(CalibrationFixtures.tapeMeasure1m),
            .segmentation([
                PanelFixtures.frontTorso,
                PanelFixtures.backTorso,
                PanelFixtures.leftSleeve,
                PanelFixtures.rightSleeve,
                PanelFixtures.complexPolygonPanel
            ]),
            .flattening([
                FlattenedPanelFixtures.frontTorsoFlattened,
                FlattenedPanelFixtures.backTorsoFlattened,
                FlattenedPanelFixtures.leftSleeveFlattened,
                FlattenedPanelFixtures.rightSleeveFlattened,
                FlattenedPanelFixtures.hexagonFlattened
            ]),
            .export(ExportFixtures.professionalPrintConfig, expectedData: ExportFixtures.samplePDFData)
        ],
        expectedDuration: 300.0, // 5 minutes
        requiredDeviceCapabilities: [.lidar, .worldTracking, .highResolutionCamera],
        testData: WorkflowTestData(
            inputMesh: MeshFixtures.largeMesh,
            calibrationData: CalibrationFixtures.tapeMeasure1m,
            expectedPanelCount: 5,
            expectedOutputSize: CGSize(width: 595, height: 842),
            validationChecks: [
                .meshIsValid,
                .calibrationComplete,
                .allPanelsSegmented,
                .flatteningSuccessful,
                .exportGenerated,
                .highResolutionOutput
            ]
        )
    )
    
    // MARK: - Error Recovery Scenarios
    
    /// AR tracking lost recovery
    public static let trackingLostRecovery = ErrorRecoveryScenario(
        name: "AR Tracking Lost Recovery",
        description: "Recovery from AR tracking interruption",
        initialState: WorkflowState.scanning(MeshFixtures.tshirtMesh, progress: 0.6),
        errorCondition: .arTrackingLost("Motion too fast"),
        expectedRecoverySteps: [
            .pauseScanning,
            .displayTrackingGuidance,
            .waitForTrackingRecovery,
            .resumeScanning
        ],
        recoveryTimeoutSeconds: 30.0,
        fallbackAction: .restartScan,
        testData: ErrorRecoveryTestData(
            preErrorMeshData: MeshFixtures.tshirtMesh,
            errorMessage: "AR tracking lost - please slow down",
            expectedUserAction: .reduceCameraMotion,
            recoverySuccessRate: 0.85
        )
    )
    
    /// Calibration failure recovery
    public static let calibrationFailureRecovery = ErrorRecoveryScenario(
        name: "Calibration Failure Recovery",
        description: "Recovery from failed calibration attempt",
        initialState: WorkflowState.calibrating(CalibrationFixtures.emptyCalibration),
        errorCondition: .calibrationFailed("Reference object not detected"),
        expectedRecoverySteps: [
            .clearCalibrationData,
            .showCalibrationInstructions,
            .retryCalibration
        ],
        recoveryTimeoutSeconds: 60.0,
        fallbackAction: .useDefaultScale,
        testData: ErrorRecoveryTestData(
            preErrorMeshData: MeshFixtures.tshirtMesh,
            errorMessage: "Could not detect reference object",
            expectedUserAction: .repositionReferenceObject,
            recoverySuccessRate: 0.75
        )
    )
    
    /// Memory pressure recovery
    public static let memoryPressureRecovery = ErrorRecoveryScenario(
        name: "Memory Pressure Recovery",
        description: "Recovery from low memory conditions",
        initialState: WorkflowState.processing(MeshFixtures.largeMesh, progress: 0.8),
        errorCondition: .insufficientMemory("Low memory warning"),
        expectedRecoverySteps: [
            .reduceMeshResolution,
            .clearTemporaryData,
            .continueProcessing
        ],
        recoveryTimeoutSeconds: 15.0,
        fallbackAction: .simplifyMesh,
        testData: ErrorRecoveryTestData(
            preErrorMeshData: MeshFixtures.largeMesh,
            errorMessage: "Insufficient memory for processing",
            expectedUserAction: .waitForProcessing,
            recoverySuccessRate: 0.90
        )
    )
    
    // MARK: - Module Integration Test Cases
    
    /// AR to Segmentation integration
    public static let arToSegmentationIntegration = ModuleIntegrationTest(
        name: "AR to Segmentation Integration",
        sourceModule: .ar,
        targetModule: .segmentation,
        dataFlow: DataFlowScenario(
            input: .meshData(MeshFixtures.tshirtMesh),
            transformations: [
                .validateMeshTopology,
                .extractConnectedComponents,
                .identifySeamLines
            ],
            output: .panelData(PanelFixtures.tshirtPanelSet),
            validationRules: [
                .inputMeshIsManifold,
                .outputPanelsNonOverlapping,
                .panelCountReasonable(min: 2, max: 20),
                .allVerticesAssigned
            ]
        )
    )
    
    /// Segmentation to Flattening integration
    public static let segmentationToFlatteningIntegration = ModuleIntegrationTest(
        name: "Segmentation to Flattening Integration", 
        sourceModule: .segmentation,
        targetModule: .flattening,
        dataFlow: DataFlowScenario(
            input: .panelData(PanelFixtures.tshirtPanelSet),
            transformations: [
                .validate3DPanels,
                .unfoldPanelsTo2D,
                .optimizeLayout,
                .addSeamAllowances
            ],
            output: .flattenedPanelData(FlattenedPanelFixtures.tshirtFlattenedSet),
            validationRules: [
                .inputPanelsValid,
                .flatteningPreservesArea,
                .noSelfIntersections,
                .seamAllowancesApplied
            ]
        )
    )
    
    /// Flattening to Export integration
    public static let flatteningToExportIntegration = ModuleIntegrationTest(
        name: "Flattening to Export Integration",
        sourceModule: .flattening,
        targetModule: .export,
        dataFlow: DataFlowScenario(
            input: .flattenedPanelData(FlattenedPanelFixtures.tshirtFlattenedSet),
            transformations: [
                .layoutPanelsOnPage,
                .addPatternMarks,
                .generateCutLines,
                .renderToFormat
            ],
            output: .exportData(ExportFixtures.samplePDFData),
            validationRules: [
                .inputPanelsPositioned,
                .outputFormatValid,
                .allPanelsIncluded,
                .patternMarksPresent
            ]
        )
    )
    
    // MARK: - Performance Benchmarks
    
    /// Large mesh processing benchmark
    public static let largeMeshBenchmark = PerformanceBenchmark(
        name: "Large Mesh Processing",
        description: "Benchmark for processing complex meshes",
        testCase: .meshProcessing(MeshFixtures.largeMesh),
        expectedMetrics: PerformanceMetrics(
            maxProcessingTime: 10.0, // seconds
            maxMemoryUsage: 512 * 1024 * 1024, // 512MB
            maxCPUUsage: 0.8, // 80%
            targetFrameRate: 30.0 // fps during AR
        ),
        deviceRequirements: DeviceRequirements(
            minRAM: 4 * 1024 * 1024 * 1024, // 4GB
            minCPUCores: 4,
            requiresLiDAR: false,
            minIOSVersion: "18.0"
        )
    )
    
    /// Real-time AR processing benchmark  
    public static let realTimeARBenchmark = PerformanceBenchmark(
        name: "Real-time AR Processing",
        description: "Benchmark for AR session performance",
        testCase: .arSession(ARSessionFixtures.basicWorldTracking),
        expectedMetrics: PerformanceMetrics(
            maxProcessingTime: 0.033, // 30fps = 33ms per frame
            maxMemoryUsage: 256 * 1024 * 1024, // 256MB
            maxCPUUsage: 0.6, // 60%
            targetFrameRate: 30.0
        ),
        deviceRequirements: DeviceRequirements(
            minRAM: 3 * 1024 * 1024 * 1024, // 3GB
            minCPUCores: 6,
            requiresLiDAR: true,
            minIOSVersion: "18.0"
        )
    )
    
    // MARK: - Cross-Platform Compatibility Tests
    
    /// iPhone compatibility test
    public static let iPhoneCompatibility = CompatibilityTest(
        name: "iPhone Compatibility",
        targetDevices: [
            DeviceProfile(model: "iPhone15,2", capabilities: UIStateFixtures.iphone15ProCapabilities),
            DeviceProfile(model: "iPhone14,6", capabilities: UIStateFixtures.iphoneSECapabilities)
        ],
        testScenarios: [
            tshirtWorkflow,
            cubeWorkflow
        ],
        expectedBehaviors: [
            .gracefulDegradation,
            .appropriateErrorMessages,
            .acceptablePerformance
        ]
    )
    
    /// iPad compatibility test
    public static let iPadCompatibility = CompatibilityTest(
        name: "iPad Compatibility", 
        targetDevices: [
            DeviceProfile(model: "iPad13,8", capabilities: UIStateFixtures.iPadProCapabilities)
        ],
        testScenarios: [
            complexGarmentWorkflow
        ],
        expectedBehaviors: [
            .enhancedPerformance,
            .largerDisplayOptimization,
            .extendedMemoryUsage
        ]
    )
    
    // MARK: - Collections
    
    /// All workflow scenarios
    public static let allWorkflowScenarios: [WorkflowScenario] = [
        tshirtWorkflow,
        cubeWorkflow,
        complexGarmentWorkflow
    ]
    
    /// All error recovery scenarios
    public static let allErrorRecoveryScenarios: [ErrorRecoveryScenario] = [
        trackingLostRecovery,
        calibrationFailureRecovery,
        memoryPressureRecovery
    ]
    
    /// All module integration tests
    public static let allModuleIntegrationTests: [ModuleIntegrationTest] = [
        arToSegmentationIntegration,
        segmentationToFlatteningIntegration,
        flatteningToExportIntegration
    ]
    
    /// All performance benchmarks
    public static let allPerformanceBenchmarks: [PerformanceBenchmark] = [
        largeMeshBenchmark,
        realTimeARBenchmark
    ]
    
    /// All compatibility tests
    public static let allCompatibilityTests: [CompatibilityTest] = [
        iPhoneCompatibility,
        iPadCompatibility
    ]
    
    // MARK: - Factory Methods
    
    /// Create workflow with specific mesh
    public static func workflowWithMesh(_ mesh: MeshDTO) -> WorkflowScenario {
        WorkflowScenario(
            name: "Custom Mesh Workflow",
            description: "Workflow with custom input mesh",
            steps: [
                .arInitialization(ARSessionFixtures.basicWorldTracking),
                .meshCapture(mesh),
                .calibration(CalibrationFixtures.ruler30cm),
                .segmentation([PanelFixtures.rectangularPanel]),
                .flattening([FlattenedPanelFixtures.rectangularFlattened]),
                .export(ExportFixtures.pdfPatternConfig, expectedData: ExportFixtures.samplePDFData)
            ],
            expectedDuration: 120.0,
            requiredDeviceCapabilities: [.worldTracking],
            testData: WorkflowTestData(
                inputMesh: mesh,
                calibrationData: CalibrationFixtures.ruler30cm,
                expectedPanelCount: 1,
                expectedOutputSize: CGSize(width: 612, height: 792),
                validationChecks: [.meshIsValid, .exportGenerated]
            )
        )
    }
    
    /// Get random workflow scenario
    public static func randomWorkflowScenario() -> WorkflowScenario {
        allWorkflowScenarios.randomElement() ?? tshirtWorkflow
    }
    
    /// Create performance benchmark for specific operation
    public static func benchmarkForOperation(_ operation: BenchmarkOperation) -> PerformanceBenchmark {
        switch operation {
        case .meshProcessing:
            return largeMeshBenchmark
        case .arTracking:
            return realTimeARBenchmark
        }
    }
}

// MARK: - Supporting Data Structures

@available(iOS 18.0, *)
public struct WorkflowScenario: Sendable, Equatable {
    public let name: String
    public let description: String
    public let steps: [WorkflowStep]
    public let expectedDuration: TimeInterval
    public let requiredDeviceCapabilities: [DeviceCapability]
    public let testData: WorkflowTestData
    
    public init(
        name: String,
        description: String,
        steps: [WorkflowStep],
        expectedDuration: TimeInterval,
        requiredDeviceCapabilities: [DeviceCapability],
        testData: WorkflowTestData
    ) {
        self.name = name
        self.description = description
        self.steps = steps
        self.expectedDuration = expectedDuration
        self.requiredDeviceCapabilities = requiredDeviceCapabilities
        self.testData = testData
    }
}

@available(iOS 18.0, *)
public enum WorkflowStep: Sendable, Equatable {
    case arInitialization(ARSessionConfig)
    case meshCapture(MeshDTO)
    case calibration(CalibrationDTO)
    case segmentation([PanelDTO])
    case flattening([FlattenedPanelDTO])
    case export(ExportConfiguration, expectedData: Data)
}

@available(iOS 18.0, *)
public enum DeviceCapability: String, Sendable, CaseIterable {
    case lidar = "lidar"
    case worldTracking = "worldTracking"
    case faceTracking = "faceTracking"
    case highResolutionCamera = "highResolutionCamera"
    case extendedMemory = "extendedMemory"
}

@available(iOS 18.0, *)
public struct WorkflowTestData: Sendable, Equatable {
    public let inputMesh: MeshDTO
    public let calibrationData: CalibrationDTO
    public let expectedPanelCount: Int
    public let expectedOutputSize: CGSize
    public let validationChecks: [ValidationCheck]
    
    public init(
        inputMesh: MeshDTO,
        calibrationData: CalibrationDTO,
        expectedPanelCount: Int,
        expectedOutputSize: CGSize,
        validationChecks: [ValidationCheck]
    ) {
        self.inputMesh = inputMesh
        self.calibrationData = calibrationData
        self.expectedPanelCount = expectedPanelCount
        self.expectedOutputSize = expectedOutputSize
        self.validationChecks = validationChecks
    }
}

@available(iOS 18.0, *)
public enum ValidationCheck: String, Sendable, CaseIterable {
    case meshIsValid = "meshIsValid"
    case calibrationComplete = "calibrationComplete"
    case allPanelsSegmented = "allPanelsSegmented"
    case flatteningSuccessful = "flatteningSuccessful"
    case exportGenerated = "exportGenerated"
    case highResolutionOutput = "highResolutionOutput"
}

@available(iOS 18.0, *)
public struct ErrorRecoveryScenario: Sendable, Equatable {
    public let name: String
    public let description: String
    public let initialState: WorkflowState
    public let errorCondition: ErrorCondition
    public let expectedRecoverySteps: [RecoveryStep]
    public let recoveryTimeoutSeconds: TimeInterval
    public let fallbackAction: FallbackAction
    public let testData: ErrorRecoveryTestData
    
    public init(
        name: String,
        description: String,
        initialState: WorkflowState,
        errorCondition: ErrorCondition,
        expectedRecoverySteps: [RecoveryStep],
        recoveryTimeoutSeconds: TimeInterval,
        fallbackAction: FallbackAction,
        testData: ErrorRecoveryTestData
    ) {
        self.name = name
        self.description = description
        self.initialState = initialState
        self.errorCondition = errorCondition
        self.expectedRecoverySteps = expectedRecoverySteps
        self.recoveryTimeoutSeconds = recoveryTimeoutSeconds
        self.fallbackAction = fallbackAction
        self.testData = testData
    }
}

@available(iOS 18.0, *)
public enum WorkflowState: Sendable, Equatable {
    case initializing
    case scanning(MeshDTO, progress: Double)
    case calibrating(CalibrationDTO)
    case processing(MeshDTO, progress: Double)
    case completed([FlattenedPanelDTO])
    case failed(String)
}

@available(iOS 18.0, *)
public enum ErrorCondition: Sendable, Equatable {
    case arTrackingLost(String)
    case calibrationFailed(String)
    case insufficientMemory(String)
    case networkError(String)
    case processingTimeout(String)
}

@available(iOS 18.0, *)
public enum RecoveryStep: String, Sendable, CaseIterable {
    case pauseScanning = "pauseScanning"
    case displayTrackingGuidance = "displayTrackingGuidance"
    case waitForTrackingRecovery = "waitForTrackingRecovery"
    case resumeScanning = "resumeScanning"
    case clearCalibrationData = "clearCalibrationData"
    case showCalibrationInstructions = "showCalibrationInstructions"
    case retryCalibration = "retryCalibration"
    case reduceMeshResolution = "reduceMeshResolution"
    case clearTemporaryData = "clearTemporaryData"
    case continueProcessing = "continueProcessing"
}

@available(iOS 18.0, *)
public enum FallbackAction: String, Sendable, CaseIterable {
    case restartScan = "restartScan"
    case useDefaultScale = "useDefaultScale"
    case simplifyMesh = "simplifyMesh"
    case exitWorkflow = "exitWorkflow"
}

@available(iOS 18.0, *)
public struct ErrorRecoveryTestData: Sendable, Equatable {
    public let preErrorMeshData: MeshDTO
    public let errorMessage: String
    public let expectedUserAction: UserAction
    public let recoverySuccessRate: Double
    
    public init(
        preErrorMeshData: MeshDTO,
        errorMessage: String,
        expectedUserAction: UserAction,
        recoverySuccessRate: Double
    ) {
        self.preErrorMeshData = preErrorMeshData
        self.errorMessage = errorMessage
        self.expectedUserAction = expectedUserAction
        self.recoverySuccessRate = max(0.0, min(1.0, recoverySuccessRate))
    }
}

@available(iOS 18.0, *)
public enum UserAction: String, Sendable, CaseIterable {
    case reduceCameraMotion = "reduceCameraMotion"
    case repositionReferenceObject = "repositionReferenceObject"
    case waitForProcessing = "waitForProcessing"
    case restartApplication = "restartApplication"
}

@available(iOS 18.0, *)
public struct ModuleIntegrationTest: Sendable, Equatable {
    public let name: String
    public let sourceModule: ModuleIdentifier
    public let targetModule: ModuleIdentifier
    public let dataFlow: DataFlowScenario
    
    public init(
        name: String,
        sourceModule: ModuleIdentifier,
        targetModule: ModuleIdentifier,
        dataFlow: DataFlowScenario
    ) {
        self.name = name
        self.sourceModule = sourceModule
        self.targetModule = targetModule
        self.dataFlow = dataFlow
    }
}

@available(iOS 18.0, *)
public enum ModuleIdentifier: String, Sendable, CaseIterable {
    case ar = "ar"
    case segmentation = "segmentation"
    case flattening = "flattening"
    case export = "export"
    case ui = "ui"
}

@available(iOS 18.0, *)
public struct DataFlowScenario: Sendable, Equatable {
    public let input: DataFlowInput
    public let transformations: [DataTransformation]
    public let output: DataFlowOutput
    public let validationRules: [ValidationRule]
    
    public init(
        input: DataFlowInput,
        transformations: [DataTransformation],
        output: DataFlowOutput,
        validationRules: [ValidationRule]
    ) {
        self.input = input
        self.transformations = transformations
        self.output = output
        self.validationRules = validationRules
    }
}

@available(iOS 18.0, *)
public enum DataFlowInput: Sendable, Equatable {
    case meshData(MeshDTO)
    case panelData([PanelDTO])
    case flattenedPanelData([FlattenedPanelDTO])
    case calibrationData(CalibrationDTO)
}

@available(iOS 18.0, *)
public enum DataTransformation: String, Sendable, CaseIterable {
    case validateMeshTopology = "validateMeshTopology"
    case extractConnectedComponents = "extractConnectedComponents"
    case identifySeamLines = "identifySeamLines"
    case validate3DPanels = "validate3DPanels"
    case unfoldPanelsTo2D = "unfoldPanelsTo2D"
    case optimizeLayout = "optimizeLayout"
    case addSeamAllowances = "addSeamAllowances"
    case layoutPanelsOnPage = "layoutPanelsOnPage"
    case addPatternMarks = "addPatternMarks"
    case generateCutLines = "generateCutLines"
    case renderToFormat = "renderToFormat"
}

@available(iOS 18.0, *)
public enum DataFlowOutput: Sendable, Equatable {
    case meshData(MeshDTO)
    case panelData([PanelDTO])
    case flattenedPanelData([FlattenedPanelDTO])
    case exportData(Data)
}

@available(iOS 18.0, *)
public enum ValidationRule: Sendable, Equatable {
    case inputMeshIsManifold
    case outputPanelsNonOverlapping
    case panelCountReasonable(min: Int, max: Int)
    case allVerticesAssigned
    case inputPanelsValid
    case flatteningPreservesArea
    case noSelfIntersections
    case seamAllowancesApplied
    case inputPanelsPositioned
    case outputFormatValid
    case allPanelsIncluded
    case patternMarksPresent
}

@available(iOS 18.0, *)
public struct PerformanceBenchmark: Sendable, Equatable {
    public let name: String
    public let description: String
    public let testCase: BenchmarkTestCase
    public let expectedMetrics: PerformanceMetrics
    public let deviceRequirements: DeviceRequirements
    
    public init(
        name: String,
        description: String,
        testCase: BenchmarkTestCase,
        expectedMetrics: PerformanceMetrics,
        deviceRequirements: DeviceRequirements
    ) {
        self.name = name
        self.description = description
        self.testCase = testCase
        self.expectedMetrics = expectedMetrics
        self.deviceRequirements = deviceRequirements
    }
}

@available(iOS 18.0, *)
public enum BenchmarkTestCase: Sendable, Equatable {
    case meshProcessing(MeshDTO)
    case arSession(ARSessionConfig)
    case panelFlattening([PanelDTO])
    case exportRendering([FlattenedPanelDTO], ExportConfiguration)
}

@available(iOS 18.0, *)
public enum BenchmarkOperation: String, Sendable, CaseIterable {
    case meshProcessing = "meshProcessing"
    case arTracking = "arTracking"
    case panelFlattening = "panelFlattening"
    case exportRendering = "exportRendering"
}

@available(iOS 18.0, *)
public struct PerformanceMetrics: Sendable, Equatable {
    public let maxProcessingTime: TimeInterval
    public let maxMemoryUsage: Int64
    public let maxCPUUsage: Double
    public let targetFrameRate: Double
    
    public init(
        maxProcessingTime: TimeInterval,
        maxMemoryUsage: Int64,
        maxCPUUsage: Double,
        targetFrameRate: Double
    ) {
        self.maxProcessingTime = maxProcessingTime
        self.maxMemoryUsage = maxMemoryUsage
        self.maxCPUUsage = max(0.0, min(1.0, maxCPUUsage))
        self.targetFrameRate = targetFrameRate
    }
}

@available(iOS 18.0, *)
public struct DeviceRequirements: Sendable, Equatable {
    public let minRAM: Int64
    public let minCPUCores: Int
    public let requiresLiDAR: Bool
    public let minIOSVersion: String
    
    public init(minRAM: Int64, minCPUCores: Int, requiresLiDAR: Bool, minIOSVersion: String) {
        self.minRAM = minRAM
        self.minCPUCores = minCPUCores
        self.requiresLiDAR = requiresLiDAR
        self.minIOSVersion = minIOSVersion
    }
}

@available(iOS 18.0, *)
public struct CompatibilityTest: Sendable, Equatable {
    public let name: String
    public let targetDevices: [DeviceProfile]
    public let testScenarios: [WorkflowScenario]
    public let expectedBehaviors: [ExpectedBehavior]
    
    public init(
        name: String,
        targetDevices: [DeviceProfile],
        testScenarios: [WorkflowScenario],
        expectedBehaviors: [ExpectedBehavior]
    ) {
        self.name = name
        self.targetDevices = targetDevices
        self.testScenarios = testScenarios
        self.expectedBehaviors = expectedBehaviors
    }
}

@available(iOS 18.0, *)
public struct DeviceProfile: Sendable, Equatable {
    public let model: String
    public let capabilities: DeviceCapabilities
    
    public init(model: String, capabilities: DeviceCapabilities) {
        self.model = model
        self.capabilities = capabilities
    }
}

@available(iOS 18.0, *)
public enum ExpectedBehavior: String, Sendable, CaseIterable {
    case gracefulDegradation = "gracefulDegradation"
    case appropriateErrorMessages = "appropriateErrorMessages"
    case acceptablePerformance = "acceptablePerformance"
    case enhancedPerformance = "enhancedPerformance"
    case largerDisplayOptimization = "largerDisplayOptimization"
    case extendedMemoryUsage = "extendedMemoryUsage"
}