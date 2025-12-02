import Foundation
import CoverCraftDTO
import CoverCraftCore

@available(iOS 18.0, macOS 15.0, *)
@Observable
@MainActor
public final class AppState {
    public var currentMesh: MeshDTO?
    public var processedMesh: MeshDTO?
    public var processingOptions = MeshProcessingOptions()
    public var calibrationData = CalibrationDTO()
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