// Version: 1.0.0
// Test Fixtures for UI Module - UI State and Navigation Data

import Foundation
import SwiftUI

/// Test fixtures for UI state management and navigation scenarios
@available(iOS 18.0, macOS 15.0, *)
public struct UIStateFixtures {
    
    // MARK: - App State Fixtures
    
    /// Fresh app launch state (onboarding required)
    public static let freshLaunchState = AppState(
        isFirstLaunch: true,
        hasCompletedOnboarding: false,
        currentProject: nil,
        navigationPath: [],
        selectedTab: .scan,
        theme: .system,
        isLoading: false,
        error: nil,
        deviceCapabilities: DeviceCapabilities.iphone15Pro
    )
    
    /// Returning user state (has used app before)
    public static let returningUserState = AppState(
        isFirstLaunch: false,
        hasCompletedOnboarding: true,
        currentProject: ProjectFixtures.basicTshirtProject,
        navigationPath: [],
        selectedTab: .projects,
        theme: .light,
        isLoading: false,
        error: nil,
        deviceCapabilities: DeviceCapabilities.iphone15Pro
    )
    
    /// Loading state during scan
    public static let scanningState = AppState(
        isFirstLaunch: false,
        hasCompletedOnboarding: true,
        currentProject: nil,
        navigationPath: [.scan],
        selectedTab: .scan,
        theme: .system,
        isLoading: true,
        error: nil,
        deviceCapabilities: DeviceCapabilities.iphone15Pro,
        scanProgress: ScanProgress(
            phase: .scanning,
            progress: 0.65,
            message: "Capturing 3D mesh..."
        )
    )
    
    /// Error state (AR not supported)
    public static let errorState = AppState(
        isFirstLaunch: false,
        hasCompletedOnboarding: true,
        currentProject: nil,
        navigationPath: [],
        selectedTab: .scan,
        theme: .system,
        isLoading: false,
        error: .arNotSupported("This device does not support ARKit"),
        deviceCapabilities: DeviceCapabilities.iPadPro
    )
    
    /// Deep navigation state (user is deep in editing)
    public static let deepNavigationState = AppState(
        isFirstLaunch: false,
        hasCompletedOnboarding: true,
        currentProject: ProjectFixtures.complexGarmentProject,
        navigationPath: [.projects, .projectDetail("project-123"), .panelEditor("panel-456")],
        selectedTab: .projects,
        theme: .dark,
        isLoading: false,
        error: nil,
        deviceCapabilities: DeviceCapabilities.iphone15Pro
    )
    
    // MARK: - Scan State Fixtures
    
    /// Initial scan setup
    public static let initialScanState = ScanState(
        phase: .setup,
        arSessionState: .initializing,
        hasValidTracking: false,
        calibrationState: CalibrationState.notStarted,
        meshData: nil,
        segmentedPanels: [],
        capturedImages: [],
        environmentLighting: nil,
        lastUpdate: Date()
    )
    
    /// Active scanning in progress
    public static let activeScanningState = ScanState(
        phase: .scanning,
        arSessionState: .running,
        hasValidTracking: true,
        calibrationState: CalibrationState.completed(CalibrationFixtures.ruler30cm),
        meshData: MeshFixtures.tshirtMesh,
        segmentedPanels: [],
        capturedImages: [
            CapturedImage(data: Data(), timestamp: Date(), pose: ARSessionFixtures.topDownPose)
        ],
        environmentLighting: ARSessionFixtures.brightIndoorLighting,
        lastUpdate: Date(),
        scanProgress: ScanProgress(
            phase: .scanning,
            progress: 0.45,
            message: "Move around the object to capture all angles"
        )
    )
    
    /// Scan completed, processing
    public static let processingState = ScanState(
        phase: .processing,
        arSessionState: .paused,
        hasValidTracking: true,
        calibrationState: CalibrationState.completed(CalibrationFixtures.ruler30cm),
        meshData: MeshFixtures.tshirtMesh,
        segmentedPanels: PanelFixtures.tshirtPanelSet,
        capturedImages: [
            CapturedImage(data: Data(), timestamp: Date(), pose: ARSessionFixtures.topDownPose),
            CapturedImage(data: Data(), timestamp: Date(), pose: ARSessionFixtures.angledPose)
        ],
        environmentLighting: ARSessionFixtures.brightIndoorLighting,
        lastUpdate: Date(),
        scanProgress: ScanProgress(
            phase: .processing,
            progress: 0.80,
            message: "Processing mesh data..."
        )
    )
    
    /// Scan completed successfully
    public static let completedScanState = ScanState(
        phase: .completed,
        arSessionState: .stopped,
        hasValidTracking: true,
        calibrationState: CalibrationState.completed(CalibrationFixtures.ruler30cm),
        meshData: MeshFixtures.tshirtMesh,
        segmentedPanels: PanelFixtures.tshirtPanelSet,
        capturedImages: [
            CapturedImage(data: Data(), timestamp: Date(), pose: ARSessionFixtures.topDownPose),
            CapturedImage(data: Data(), timestamp: Date(), pose: ARSessionFixtures.angledPose),
            CapturedImage(data: Data(), timestamp: Date(), pose: ARSessionFixtures.closeUpPose)
        ],
        environmentLighting: ARSessionFixtures.brightIndoorLighting,
        lastUpdate: Date()
    )
    
    /// Scan failed state
    public static let failedScanState = ScanState(
        phase: .failed,
        arSessionState: .stopped,
        hasValidTracking: false,
        calibrationState: CalibrationState.notStarted,
        meshData: nil,
        segmentedPanels: [],
        capturedImages: [],
        environmentLighting: nil,
        lastUpdate: Date(),
        error: .trackingLost("AR tracking was lost")
    )
    
    // MARK: - Project State Fixtures
    
    /// Empty projects list
    public static let emptyProjectsState = ProjectsState(
        projects: [],
        selectedProject: nil,
        isLoading: false,
        searchText: "",
        sortOption: .dateModified,
        filterOption: .all
    )
    
    /// Projects list with data
    public static let populatedProjectsState = ProjectsState(
        projects: ProjectFixtures.sampleProjects,
        selectedProject: nil,
        isLoading: false,
        searchText: "",
        sortOption: .name,
        filterOption: .all
    )
    
    /// Loading projects state
    public static let loadingProjectsState = ProjectsState(
        projects: [],
        selectedProject: nil,
        isLoading: true,
        searchText: "",
        sortOption: .dateModified,
        filterOption: .all
    )
    
    /// Searching projects state
    public static let searchingProjectsState = ProjectsState(
        projects: ProjectFixtures.sampleProjects.filter { $0.name.contains("Shirt") },
        selectedProject: nil,
        isLoading: false,
        searchText: "Shirt",
        sortOption: .name,
        filterOption: .all
    )
    
    // MARK: - Panel Editor State Fixtures
    
    /// Editing front torso panel
    public static let editingFrontPanelState = PanelEditorState(
        panel: PanelFixtures.frontTorso,
        flattenedPanel: FlattenedPanelFixtures.frontTorsoFlattened,
        isEditing: true,
        selectedTool: .select,
        selectionState: SelectionState.singlePoint(5),
        zoomLevel: 1.2,
        panOffset: CGPoint(x: -50, y: 25),
        showGrid: true,
        snapToGrid: true,
        gridSize: 10.0,
        undoStack: [],
        redoStack: []
    )
    
    /// View-only panel state
    public static let viewOnlyPanelState = PanelEditorState(
        panel: PanelFixtures.triangularPanel,
        flattenedPanel: FlattenedPanelFixtures.triangularFlattened,
        isEditing: false,
        selectedTool: .none,
        selectionState: SelectionState.none,
        zoomLevel: 1.0,
        panOffset: .zero,
        showGrid: false,
        snapToGrid: false,
        gridSize: 10.0,
        undoStack: [],
        redoStack: []
    )
    
    /// Multiple points selected
    public static let multiSelectPanelState = PanelEditorState(
        panel: PanelFixtures.complexPolygonPanel,
        flattenedPanel: FlattenedPanelFixtures.hexagonFlattened,
        isEditing: true,
        selectedTool: .select,
        selectionState: SelectionState.multiplePoints([1, 3, 5]),
        zoomLevel: 0.8,
        panOffset: CGPoint(x: 100, y: -75),
        showGrid: true,
        snapToGrid: true,
        gridSize: 5.0,
        undoStack: [
            UndoableAction.movePoints([1, 3], from: [CGPoint(x: 50, y: 50), CGPoint(x: 100, y: 50)])
        ],
        redoStack: []
    )
    
    // MARK: - Settings State Fixtures
    
    /// Default settings state
    public static let defaultSettingsState = SettingsState(
        theme: .system,
        units: .metric,
        defaultExportFormat: .pdf,
        autoSaveInterval: 300, // 5 minutes
        maxUndoSteps: 50,
        enableHapticFeedback: true,
        enableSoundEffects: true,
        debugMode: false,
        privacySettings: PrivacySettings(
            allowAnalytics: false,
            allowCrashReporting: true,
            shareUsageData: false
        )
    )
    
    /// Customized settings state
    public static let customizedSettingsState = SettingsState(
        theme: .dark,
        units: .imperial,
        defaultExportFormat: .svg,
        autoSaveInterval: 600, // 10 minutes
        maxUndoSteps: 100,
        enableHapticFeedback: false,
        enableSoundEffects: false,
        debugMode: true,
        privacySettings: PrivacySettings(
            allowAnalytics: true,
            allowCrashReporting: true,
            shareUsageData: true
        )
    )
    
    // MARK: - Device Capabilities Fixtures
    
    /// iPhone 15 Pro capabilities
    public static let iphone15ProCapabilities = DeviceCapabilities(
        deviceModel: "iPhone15,2",
        hasLiDAR: true,
        supportsARWorldTracking: true,
        supportsARFaceTracking: true,
        maxCameraResolution: CGSize(width: 4032, height: 3024),
        availableStorage: 1024 * 1024 * 1024 * 256, // 256GB
        ramSize: 8 * 1024 * 1024 * 1024, // 8GB
        cpuCores: 6,
        gpuType: "A17 Pro",
        screenSize: CGSize(width: 393, height: 852),
        screenScale: 3.0,
        supportsDynamicIsland: true
    )
    
    /// iPad Pro capabilities
    public static let iPadProCapabilities = DeviceCapabilities(
        deviceModel: "iPad13,8",
        hasLiDAR: true,
        supportsARWorldTracking: true,
        supportsARFaceTracking: false,
        maxCameraResolution: CGSize(width: 4032, height: 3024),
        availableStorage: 1024 * 1024 * 1024 * 512, // 512GB
        ramSize: 16 * 1024 * 1024 * 1024, // 16GB
        cpuCores: 8,
        gpuType: "M2",
        screenSize: CGSize(width: 1024, height: 1366),
        screenScale: 2.0,
        supportsDynamicIsland: false
    )
    
    /// iPhone SE (limited capabilities)
    public static let iphoneSECapabilities = DeviceCapabilities(
        deviceModel: "iPhone14,6",
        hasLiDAR: false,
        supportsARWorldTracking: true,
        supportsARFaceTracking: false,
        maxCameraResolution: CGSize(width: 3024, height: 4032),
        availableStorage: 1024 * 1024 * 1024 * 128, // 128GB
        ramSize: 4 * 1024 * 1024 * 1024, // 4GB
        cpuCores: 6,
        gpuType: "A15 Bionic",
        screenSize: CGSize(width: 375, height: 667),
        screenScale: 2.0,
        supportsDynamicIsland: false
    )
    
    // MARK: - Collections
    
    /// All app state fixtures
    public static let allAppStates: [AppState] = [
        freshLaunchState,
        returningUserState,
        scanningState,
        errorState,
        deepNavigationState
    ]
    
    /// All scan state fixtures
    public static let allScanStates: [ScanState] = [
        initialScanState,
        activeScanningState,
        processingState,
        completedScanState,
        failedScanState
    ]
    
    /// All panel editor states
    public static let allPanelEditorStates: [PanelEditorState] = [
        editingFrontPanelState,
        viewOnlyPanelState,
        multiSelectPanelState
    ]
    
    /// All device capabilities
    public static let allDeviceCapabilities: [DeviceCapabilities] = [
        iphone15ProCapabilities,
        iPadProCapabilities,
        iphoneSECapabilities
    ]
    
    // MARK: - Factory Methods
    
    /// Create app state with specific project
    public static func appStateWithProject(_ project: Project) -> AppState {
        AppState(
            isFirstLaunch: false,
            hasCompletedOnboarding: true,
            currentProject: project,
            navigationPath: [],
            selectedTab: .projects,
            theme: .system,
            isLoading: false,
            error: nil,
            deviceCapabilities: iphone15ProCapabilities
        )
    }
    
    /// Create scan state with specific phase
    public static func scanStateWithPhase(_ phase: ScanPhase) -> ScanState {
        switch phase {
        case .setup:
            return initialScanState
        case .scanning:
            return activeScanningState
        case .processing:
            return processingState
        case .completed:
            return completedScanState
        case .failed:
            return failedScanState
        }
    }
    
    /// Create panel editor state with specific tool
    public static func panelEditorStateWithTool(_ tool: EditorTool) -> PanelEditorState {
        PanelEditorState(
            panel: PanelFixtures.rectangularPanel,
            flattenedPanel: FlattenedPanelFixtures.rectangularFlattened,
            isEditing: tool != .none,
            selectedTool: tool,
            selectionState: .none,
            zoomLevel: 1.0,
            panOffset: .zero,
            showGrid: true,
            snapToGrid: true,
            gridSize: 10.0,
            undoStack: [],
            redoStack: []
        )
    }
    
    /// Get random app state for testing
    public static func randomAppState() -> AppState {
        allAppStates.randomElement() ?? freshLaunchState
    }
}

// MARK: - Sample Project Fixtures

@available(iOS 18.0, macOS 15.0, *)
public struct ProjectFixtures {
    
    /// Basic t-shirt project
    public static let basicTshirtProject = Project(
        id: UUID(uuidString: "PROJ1234-1234-1234-1234-123456781234")!,
        name: "Basic T-Shirt",
        description: "Simple cotton t-shirt pattern",
        createdAt: Date(timeIntervalSince1970: 1609459200),
        modifiedAt: Date(timeIntervalSince1970: 1609545600),
        meshData: MeshFixtures.tshirtMesh,
        panels: PanelFixtures.tshirtPanelSet,
        flattenedPanels: FlattenedPanelFixtures.tshirtFlattenedSet,
        calibration: CalibrationFixtures.ruler30cm,
        exportHistory: [],
        tags: ["apparel", "casual", "basic"],
        category: .apparel
    )
    
    /// Complex garment project
    public static let complexGarmentProject = Project(
        id: UUID(uuidString: "PROJ1234-1234-1234-1234-123456781235")!,
        name: "Wedding Dress",
        description: "Elaborate wedding dress with train",
        createdAt: Date(timeIntervalSince1970: 1609372800),
        modifiedAt: Date(timeIntervalSince1970: 1609632000),
        meshData: MeshFixtures.largeMesh,
        panels: [
            PanelFixtures.frontTorso,
            PanelFixtures.backTorso,
            PanelFixtures.complexPolygonPanel,
            PanelFixtures.largePanelWithManyTriangles
        ],
        flattenedPanels: [
            FlattenedPanelFixtures.frontTorsoFlattened,
            FlattenedPanelFixtures.backTorsoFlattened,
            FlattenedPanelFixtures.hexagonFlattened,
            FlattenedPanelFixtures.largeFlattened
        ],
        calibration: CalibrationFixtures.tapeMeasure1m,
        exportHistory: [
            ExportRecord(
                format: .pdf,
                exportedAt: Date(timeIntervalSince1970: 1609459200),
                fileSize: 2048000,
                isSuccessful: true
            )
        ],
        tags: ["formal", "wedding", "complex"],
        category: .apparel
    )
    
    /// Sample projects collection
    public static let sampleProjects: [Project] = [
        basicTshirtProject,
        complexGarmentProject,
        Project(
            id: UUID(),
            name: "Tote Bag",
            description: "Canvas tote bag with pockets",
            createdAt: Date(timeIntervalSince1970: 1609286400),
            modifiedAt: Date(timeIntervalSince1970: 1609545600),
            meshData: MeshFixtures.simpleCube,
            panels: [PanelFixtures.rectangularPanel, PanelFixtures.triangularPanel],
            flattenedPanels: [FlattenedPanelFixtures.rectangularFlattened],
            calibration: CalibrationFixtures.creditCard,
            exportHistory: [],
            tags: ["accessories", "bag", "practical"],
            category: .accessories
        )
    ]
}

// MARK: - Supporting Data Structures

@available(iOS 18.0, macOS 15.0, *)
public struct AppState: Sendable, Equatable {
    public let isFirstLaunch: Bool
    public let hasCompletedOnboarding: Bool
    public let currentProject: Project?
    public let navigationPath: [NavigationDestination]
    public let selectedTab: TabSelection
    public let theme: ThemePreference
    public let isLoading: Bool
    public let error: AppError?
    public let deviceCapabilities: DeviceCapabilities
    public let scanProgress: ScanProgress?
    
    public init(
        isFirstLaunch: Bool,
        hasCompletedOnboarding: Bool,
        currentProject: Project?,
        navigationPath: [NavigationDestination],
        selectedTab: TabSelection,
        theme: ThemePreference,
        isLoading: Bool,
        error: AppError?,
        deviceCapabilities: DeviceCapabilities,
        scanProgress: ScanProgress? = nil
    ) {
        self.isFirstLaunch = isFirstLaunch
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.currentProject = currentProject
        self.navigationPath = navigationPath
        self.selectedTab = selectedTab
        self.theme = theme
        self.isLoading = isLoading
        self.error = error
        self.deviceCapabilities = deviceCapabilities
        self.scanProgress = scanProgress
    }
}

@available(iOS 18.0, macOS 15.0, *)
public enum NavigationDestination: Sendable, Equatable {
    case scan
    case projects
    case projectDetail(String)
    case panelEditor(String)
    case settings
    case help
}

@available(iOS 18.0, macOS 15.0, *)
public enum TabSelection: String, Sendable, CaseIterable {
    case scan = "scan"
    case projects = "projects" 
    case settings = "settings"
}

@available(iOS 18.0, macOS 15.0, *)
public enum ThemePreference: String, Sendable, CaseIterable {
    case light = "light"
    case dark = "dark"
    case system = "system"
}

@available(iOS 18.0, macOS 15.0, *)
public enum AppError: Error, Sendable, Equatable {
    case arNotSupported(String)
    case networkError(String)
    case storageError(String)
    case processingError(String)
}

@available(iOS 18.0, macOS 15.0, *)
public struct ScanState: Sendable, Equatable {
    public let phase: ScanPhase
    public let arSessionState: ARSessionState
    public let hasValidTracking: Bool
    public let calibrationState: CalibrationState
    public let meshData: MeshDTO?
    public let segmentedPanels: [PanelDTO]
    public let capturedImages: [CapturedImage]
    public let environmentLighting: LightEstimate?
    public let lastUpdate: Date
    public let scanProgress: ScanProgress?
    public let error: ScanError?
    
    public init(
        phase: ScanPhase,
        arSessionState: ARSessionState,
        hasValidTracking: Bool,
        calibrationState: CalibrationState,
        meshData: MeshDTO?,
        segmentedPanels: [PanelDTO],
        capturedImages: [CapturedImage],
        environmentLighting: LightEstimate?,
        lastUpdate: Date,
        scanProgress: ScanProgress? = nil,
        error: ScanError? = nil
    ) {
        self.phase = phase
        self.arSessionState = arSessionState
        self.hasValidTracking = hasValidTracking
        self.calibrationState = calibrationState
        self.meshData = meshData
        self.segmentedPanels = segmentedPanels
        self.capturedImages = capturedImages
        self.environmentLighting = environmentLighting
        self.lastUpdate = lastUpdate
        self.scanProgress = scanProgress
        self.error = error
    }
}

@available(iOS 18.0, macOS 15.0, *)
public enum ScanPhase: String, Sendable, CaseIterable {
    case setup = "setup"
    case scanning = "scanning"
    case processing = "processing"
    case completed = "completed"
    case failed = "failed"
}

@available(iOS 18.0, macOS 15.0, *)
public enum ARSessionState: String, Sendable, CaseIterable {
    case initializing = "initializing"
    case running = "running"
    case paused = "paused"
    case stopped = "stopped"
    case limited = "limited"
}

@available(iOS 18.0, macOS 15.0, *)
public enum CalibrationState: Sendable, Equatable {
    case notStarted
    case inProgress(CalibrationDTO)
    case completed(CalibrationDTO)
    case failed(String)
}

@available(iOS 18.0, macOS 15.0, *)
public struct CapturedImage: Sendable, Equatable {
    public let data: Data
    public let timestamp: Date
    public let pose: CameraExtrinsics
    
    public init(data: Data, timestamp: Date, pose: CameraExtrinsics) {
        self.data = data
        self.timestamp = timestamp
        self.pose = pose
    }
}

@available(iOS 18.0, macOS 15.0, *)
public struct ScanProgress: Sendable, Equatable {
    public let phase: ScanPhase
    public let progress: Double // 0.0 to 1.0
    public let message: String
    
    public init(phase: ScanPhase, progress: Double, message: String) {
        self.phase = phase
        self.progress = max(0.0, min(1.0, progress))
        self.message = message
    }
}

@available(iOS 18.0, macOS 15.0, *)
public enum ScanError: Error, Sendable, Equatable {
    case trackingLost(String)
    case insufficientLighting(String)
    case processingFailed(String)
    case calibrationFailed(String)
}

@available(iOS 18.0, macOS 15.0, *)
public struct ProjectsState: Sendable, Equatable {
    public let projects: [Project]
    public let selectedProject: Project?
    public let isLoading: Bool
    public let searchText: String
    public let sortOption: ProjectSortOption
    public let filterOption: ProjectFilterOption
    
    public init(
        projects: [Project],
        selectedProject: Project?,
        isLoading: Bool,
        searchText: String,
        sortOption: ProjectSortOption,
        filterOption: ProjectFilterOption
    ) {
        self.projects = projects
        self.selectedProject = selectedProject
        self.isLoading = isLoading
        self.searchText = searchText
        self.sortOption = sortOption
        self.filterOption = filterOption
    }
}

@available(iOS 18.0, macOS 15.0, *)
public enum ProjectSortOption: String, Sendable, CaseIterable {
    case name = "name"
    case dateCreated = "dateCreated"
    case dateModified = "dateModified"
    case size = "size"
}

@available(iOS 18.0, macOS 15.0, *)
public enum ProjectFilterOption: String, Sendable, CaseIterable {
    case all = "all"
    case apparel = "apparel"
    case accessories = "accessories"
    case recent = "recent"
}

@available(iOS 18.0, macOS 15.0, *)
public struct PanelEditorState: Sendable, Equatable {
    public let panel: PanelDTO
    public let flattenedPanel: FlattenedPanelDTO
    public let isEditing: Bool
    public let selectedTool: EditorTool
    public let selectionState: SelectionState
    public let zoomLevel: Double
    public let panOffset: CGPoint
    public let showGrid: Bool
    public let snapToGrid: Bool
    public let gridSize: Double
    public let undoStack: [UndoableAction]
    public let redoStack: [UndoableAction]
    
    public init(
        panel: PanelDTO,
        flattenedPanel: FlattenedPanelDTO,
        isEditing: Bool,
        selectedTool: EditorTool,
        selectionState: SelectionState,
        zoomLevel: Double,
        panOffset: CGPoint,
        showGrid: Bool,
        snapToGrid: Bool,
        gridSize: Double,
        undoStack: [UndoableAction],
        redoStack: [UndoableAction]
    ) {
        self.panel = panel
        self.flattenedPanel = flattenedPanel
        self.isEditing = isEditing
        self.selectedTool = selectedTool
        self.selectionState = selectionState
        self.zoomLevel = zoomLevel
        self.panOffset = panOffset
        self.showGrid = showGrid
        self.snapToGrid = snapToGrid
        self.gridSize = gridSize
        self.undoStack = undoStack
        self.redoStack = redoStack
    }
}

@available(iOS 18.0, macOS 15.0, *)
public enum EditorTool: String, Sendable, CaseIterable {
    case none = "none"
    case select = "select"
    case move = "move"
    case rotate = "rotate"
    case scale = "scale"
    case addPoint = "addPoint"
    case deletePoint = "deletePoint"
}

@available(iOS 18.0, macOS 15.0, *)
public enum SelectionState: Sendable, Equatable {
    case none
    case singlePoint(Int)
    case multiplePoints([Int])
    case edge(Int, Int)
    case panel
}

@available(iOS 18.0, macOS 15.0, *)
public enum UndoableAction: Sendable, Equatable {
    case movePoints([Int], from: [CGPoint])
    case addPoint(Int, at: CGPoint)
    case deletePoint(Int, point: CGPoint)
    case scalePanel(factor: Double, center: CGPoint)
    case rotatePanel(angle: Double, center: CGPoint)
}

@available(iOS 18.0, macOS 15.0, *)
public struct SettingsState: Sendable, Equatable {
    public let theme: ThemePreference
    public let units: UnitPreference
    public let defaultExportFormat: ExportFormat
    public let autoSaveInterval: TimeInterval
    public let maxUndoSteps: Int
    public let enableHapticFeedback: Bool
    public let enableSoundEffects: Bool
    public let debugMode: Bool
    public let privacySettings: PrivacySettings
    
    public init(
        theme: ThemePreference,
        units: UnitPreference,
        defaultExportFormat: ExportFormat,
        autoSaveInterval: TimeInterval,
        maxUndoSteps: Int,
        enableHapticFeedback: Bool,
        enableSoundEffects: Bool,
        debugMode: Bool,
        privacySettings: PrivacySettings
    ) {
        self.theme = theme
        self.units = units
        self.defaultExportFormat = defaultExportFormat
        self.autoSaveInterval = autoSaveInterval
        self.maxUndoSteps = maxUndoSteps
        self.enableHapticFeedback = enableHapticFeedback
        self.enableSoundEffects = enableSoundEffects
        self.debugMode = debugMode
        self.privacySettings = privacySettings
    }
}

@available(iOS 18.0, macOS 15.0, *)
public enum UnitPreference: String, Sendable, CaseIterable {
    case metric = "metric"
    case imperial = "imperial"
}

@available(iOS 18.0, macOS 15.0, *)
public struct PrivacySettings: Sendable, Equatable {
    public let allowAnalytics: Bool
    public let allowCrashReporting: Bool
    public let shareUsageData: Bool
    
    public init(allowAnalytics: Bool, allowCrashReporting: Bool, shareUsageData: Bool) {
        self.allowAnalytics = allowAnalytics
        self.allowCrashReporting = allowCrashReporting
        self.shareUsageData = shareUsageData
    }
}

@available(iOS 18.0, macOS 15.0, *)
public struct DeviceCapabilities: Sendable, Equatable {
    public let deviceModel: String
    public let hasLiDAR: Bool
    public let supportsARWorldTracking: Bool
    public let supportsARFaceTracking: Bool
    public let maxCameraResolution: CGSize
    public let availableStorage: Int64
    public let ramSize: Int64
    public let cpuCores: Int
    public let gpuType: String
    public let screenSize: CGSize
    public let screenScale: Double
    public let supportsDynamicIsland: Bool
    
    public init(
        deviceModel: String,
        hasLiDAR: Bool,
        supportsARWorldTracking: Bool,
        supportsARFaceTracking: Bool,
        maxCameraResolution: CGSize,
        availableStorage: Int64,
        ramSize: Int64,
        cpuCores: Int,
        gpuType: String,
        screenSize: CGSize,
        screenScale: Double,
        supportsDynamicIsland: Bool
    ) {
        self.deviceModel = deviceModel
        self.hasLiDAR = hasLiDAR
        self.supportsARWorldTracking = supportsARWorldTracking
        self.supportsARFaceTracking = supportsARFaceTracking
        self.maxCameraResolution = maxCameraResolution
        self.availableStorage = availableStorage
        self.ramSize = ramSize
        self.cpuCores = cpuCores
        self.gpuType = gpuType
        self.screenSize = screenSize
        self.screenScale = screenScale
        self.supportsDynamicIsland = supportsDynamicIsland
    }
    
    public static let iphone15Pro = DeviceCapabilities(
        deviceModel: "iPhone15,2",
        hasLiDAR: true,
        supportsARWorldTracking: true,
        supportsARFaceTracking: true,
        maxCameraResolution: CGSize(width: 4032, height: 3024),
        availableStorage: 256 * 1024 * 1024 * 1024,
        ramSize: 8 * 1024 * 1024 * 1024,
        cpuCores: 6,
        gpuType: "A17 Pro",
        screenSize: CGSize(width: 393, height: 852),
        screenScale: 3.0,
        supportsDynamicIsland: true
    )
    
    public static let iPadPro = DeviceCapabilities(
        deviceModel: "iPad13,8",
        hasLiDAR: true,
        supportsARWorldTracking: true,
        supportsARFaceTracking: false,
        maxCameraResolution: CGSize(width: 4032, height: 3024),
        availableStorage: 512 * 1024 * 1024 * 1024,
        ramSize: 16 * 1024 * 1024 * 1024,
        cpuCores: 8,
        gpuType: "M2",
        screenSize: CGSize(width: 1024, height: 1366),
        screenScale: 2.0,
        supportsDynamicIsland: false
    )
}

@available(iOS 18.0, macOS 15.0, *)
public struct Project: Sendable, Equatable, Identifiable {
    public let id: UUID
    public let name: String
    public let description: String
    public let createdAt: Date
    public let modifiedAt: Date
    public let meshData: MeshDTO
    public let panels: [PanelDTO]
    public let flattenedPanels: [FlattenedPanelDTO]
    public let calibration: CalibrationDTO
    public let exportHistory: [ExportRecord]
    public let tags: [String]
    public let category: ProjectCategory
    
    public init(
        id: UUID,
        name: String,
        description: String,
        createdAt: Date,
        modifiedAt: Date,
        meshData: MeshDTO,
        panels: [PanelDTO],
        flattenedPanels: [FlattenedPanelDTO],
        calibration: CalibrationDTO,
        exportHistory: [ExportRecord],
        tags: [String],
        category: ProjectCategory
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.meshData = meshData
        self.panels = panels
        self.flattenedPanels = flattenedPanels
        self.calibration = calibration
        self.exportHistory = exportHistory
        self.tags = tags
        self.category = category
    }
}

@available(iOS 18.0, macOS 15.0, *)
public enum ProjectCategory: String, Sendable, CaseIterable {
    case apparel = "apparel"
    case accessories = "accessories"
    case home = "home"
    case craft = "craft"
}

@available(iOS 18.0, macOS 15.0, *)
public struct ExportRecord: Sendable, Equatable {
    public let format: ExportFormat
    public let exportedAt: Date
    public let fileSize: Int
    public let isSuccessful: Bool
    
    public init(format: ExportFormat, exportedAt: Date, fileSize: Int, isSuccessful: Bool) {
        self.format = format
        self.exportedAt = exportedAt
        self.fileSize = fileSize
        self.isSuccessful = isSuccessful
    }
}