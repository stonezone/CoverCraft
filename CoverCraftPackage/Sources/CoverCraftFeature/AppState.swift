import Foundation
import CoverCraftDTO
import CoverCraftCore

// MARK: - Enums

@available(iOS 18.0, macOS 15.0, *)
public enum PatternMode: String, CaseIterable, Sendable, Codable {
    case slipcover = "Slipcover (Bottom-Open)"
    case fitted = "Fitted (Experimental)"
}

@available(iOS 18.0, macOS 15.0, *)
public enum PatternInputMode: String, CaseIterable, Sendable, Codable {
    case scan = "LiDAR Scan"
    case manual = "Manual Dimensions"
}

// MARK: - ScanState

/// Manages LiDAR scan data and mesh processing state
@available(iOS 18.0, macOS 15.0, *)
@Observable
@MainActor
public final class ScanState {
    public var currentMesh: MeshDTO?
    public var processedMesh: MeshDTO?
    public var processingOptions = MeshProcessingOptions()
    public var calibrationData = CalibrationDTO()

    public init() {}

    /// The mesh to use for pattern generation (processed if available, otherwise raw)
    public var effectiveMesh: MeshDTO? {
        processedMesh ?? currentMesh
    }

    /// Whether mesh processing has been applied
    public var hasProcessedMesh: Bool {
        processedMesh != nil
    }

    /// Whether calibration is complete for the current scan
    public var isCalibrated: Bool {
        calibrationData.isComplete
    }
}

// MARK: - PatternState

/// Manages pattern configuration and generation options
@available(iOS 18.0, macOS 15.0, *)
@Observable
@MainActor
public final class PatternState {
    public var patternMode: PatternMode = .slipcover
    public var inputMode: PatternInputMode = .scan

    // Manual dimensions (millimeters)
    public var manualWidthMillimeters: Double = 400
    public var manualDepthMillimeters: Double = 400
    public var manualHeightMillimeters: Double = 400

    // Slipcover options
    public var slipcoverTopStyle: SlipcoverTopStyle = .closed
    public var slipcoverEaseMillimeters: Double = 20
    public var slipcoverSeamAllowanceMillimeters: Double = 15
    public var slipcoverSegmentsPerSide: Int = 1
    public var slipcoverVerticalSegments: Int = 1
    public var slipcoverPanelization: SlipcoverPanelization = .quads

    // Fitted mode options
    public var selectedResolution = SegmentationResolution.medium

    public init() {}

    /// Whether manual dimensions are valid
    public var hasValidManualDimensions: Bool {
        manualWidthMillimeters > 1 && manualDepthMillimeters > 1 && manualHeightMillimeters > 1
    }
}

// MARK: - OutputState

/// Manages generated pattern output and export state
@available(iOS 18.0, macOS 15.0, *)
@Observable
@MainActor
public final class OutputState {
    public var currentPanels: [PanelDTO]?
    public var flattenedPanels: [FlattenedPanelDTO]?
    public var showPatternReady = false

    public init() {}

    /// Whether a pattern is ready for export
    public var hasPattern: Bool {
        flattenedPanels != nil
    }

    /// Clear generated output
    public func clearOutput() {
        currentPanels = nil
        flattenedPanels = nil
        showPatternReady = false
    }
}

// MARK: - AppState (Coordinator)

/// Central application state coordinator that composes scan, pattern, and output states
@available(iOS 18.0, macOS 15.0, *)
@Observable
@MainActor
public final class AppState {
    public let scan = ScanState()
    public let pattern = PatternState()
    public let output = OutputState()

    public init() {}

    // MARK: - Convenience Accessors (Backward Compatibility)

    // These provide a flat API matching the original AppState for easier migration

    public var currentMesh: MeshDTO? {
        get { scan.currentMesh }
        set { scan.currentMesh = newValue }
    }

    public var processedMesh: MeshDTO? {
        get { scan.processedMesh }
        set { scan.processedMesh = newValue }
    }

    public var processingOptions: MeshProcessingOptions {
        get { scan.processingOptions }
        set { scan.processingOptions = newValue }
    }

    public var calibrationData: CalibrationDTO {
        get { scan.calibrationData }
        set { scan.calibrationData = newValue }
    }

    public var effectiveMesh: MeshDTO? { scan.effectiveMesh }
    public var hasProcessedMesh: Bool { scan.hasProcessedMesh }

    public var patternMode: PatternMode {
        get { pattern.patternMode }
        set { pattern.patternMode = newValue }
    }

    public var inputMode: PatternInputMode {
        get { pattern.inputMode }
        set { pattern.inputMode = newValue }
    }

    public var manualWidthMillimeters: Double {
        get { pattern.manualWidthMillimeters }
        set { pattern.manualWidthMillimeters = newValue }
    }

    public var manualDepthMillimeters: Double {
        get { pattern.manualDepthMillimeters }
        set { pattern.manualDepthMillimeters = newValue }
    }

    public var manualHeightMillimeters: Double {
        get { pattern.manualHeightMillimeters }
        set { pattern.manualHeightMillimeters = newValue }
    }

    public var slipcoverTopStyle: SlipcoverTopStyle {
        get { pattern.slipcoverTopStyle }
        set { pattern.slipcoverTopStyle = newValue }
    }

    public var slipcoverEaseMillimeters: Double {
        get { pattern.slipcoverEaseMillimeters }
        set { pattern.slipcoverEaseMillimeters = newValue }
    }

    public var slipcoverSeamAllowanceMillimeters: Double {
        get { pattern.slipcoverSeamAllowanceMillimeters }
        set { pattern.slipcoverSeamAllowanceMillimeters = newValue }
    }

    public var slipcoverSegmentsPerSide: Int {
        get { pattern.slipcoverSegmentsPerSide }
        set { pattern.slipcoverSegmentsPerSide = newValue }
    }

    public var slipcoverVerticalSegments: Int {
        get { pattern.slipcoverVerticalSegments }
        set { pattern.slipcoverVerticalSegments = newValue }
    }

    public var slipcoverPanelization: SlipcoverPanelization {
        get { pattern.slipcoverPanelization }
        set { pattern.slipcoverPanelization = newValue }
    }

    public var selectedResolution: SegmentationResolution {
        get { pattern.selectedResolution }
        set { pattern.selectedResolution = newValue }
    }

    public var currentPanels: [PanelDTO]? {
        get { output.currentPanels }
        set { output.currentPanels = newValue }
    }

    public var flattenedPanels: [FlattenedPanelDTO]? {
        get { output.flattenedPanels }
        set { output.flattenedPanels = newValue }
    }

    public var showPatternReady: Bool {
        get { output.showPatternReady }
        set { output.showPatternReady = newValue }
    }

    // MARK: - Computed Properties

    public var canGeneratePattern: Bool {
        switch pattern.inputMode {
        case .scan:
            return scan.effectiveMesh != nil && scan.calibrationData.isComplete
        case .manual:
            guard pattern.patternMode == .slipcover else { return false }
            return pattern.hasValidManualDimensions
        }
    }
}
