import Foundation
import CoverCraftDTO
import CoverCraftCore

@available(iOS 18.0, macOS 15.0, *)
public enum PatternMode: String, CaseIterable, Sendable, Codable {
    case slipcover = "Slipcover (Bottom-Open)"
    case fitted = "Fitted (Experimental)"
}

@available(iOS 18.0, macOS 15.0, *)
@Observable
@MainActor
public final class AppState {
    public var currentMesh: MeshDTO?
    public var processedMesh: MeshDTO?
    public var processingOptions = MeshProcessingOptions()
    public var calibrationData = CalibrationDTO()

    public var patternMode: PatternMode = .slipcover

    // Slipcover options
    public var slipcoverTopStyle: SlipcoverTopStyle = .closed
    public var slipcoverEaseMillimeters: Double = 20
    public var slipcoverSegmentsPerSide: Int = 1
    public var slipcoverVerticalSegments: Int = 1
    public var slipcoverPanelization: SlipcoverPanelization = .quads

    public var selectedResolution = SegmentationResolution.medium
    public var currentPanels: [PanelDTO]?
    public var flattenedPanels: [FlattenedPanelDTO]?
    public var showPatternReady = false

    public init() {}

    /// The mesh to use for pattern generation (processed if available, otherwise raw)
    public var effectiveMesh: MeshDTO? {
        processedMesh ?? currentMesh
    }

    public var canGeneratePattern: Bool {
        effectiveMesh != nil && calibrationData.isComplete
    }

    /// Whether mesh processing has been applied
    public var hasProcessedMesh: Bool {
        processedMesh != nil
    }
}
