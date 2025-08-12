import Foundation
import CoverCraftDTO
import CoverCraftCore

@available(iOS 18.0, macOS 15.0, *)
@Observable
@MainActor
public final class AppState {
    public var currentMesh: MeshDTO?
    public var calibrationData = CalibrationDTO()
    public var selectedResolution = SegmentationResolution.medium
    public var currentPanels: [PanelDTO]?
    public var flattenedPanels: [FlattenedPanelDTO]?
    public var showPatternReady = false
    
    public init() {}
    
    public var canGeneratePattern: Bool {
        currentMesh != nil && calibrationData.isComplete
    }
}