import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Protocol for mesh segmentation service
public protocol MeshSegmentationServiceProtocol: Sendable {
    func segmentMesh(_ mesh: Mesh, targetPanelCount: Int) async throws -> [Panel]
}

/// Protocol for pattern flattening service
public protocol PatternFlattenerProtocol: Sendable {
    func flattenPanels(_ panels: [Panel], from mesh: Mesh) async throws -> [FlattenedPanel]
}

/// Protocol for pattern export service
public protocol PatternExporterProtocol: Sendable {
    func exportPattern(_ panels: [FlattenedPanel], format: ExportFormat) async throws -> URL
}

/// Available export formats
public enum ExportFormat: String, CaseIterable, Sendable {
    case png = "PNG"
    case gif = "GIF"
    case svg = "SVG"
    case pdfLetter = "PDF (Letter)"
    case pdfA4 = "PDF (A4)"
}

/// Resolution presets for segmentation
public enum SegmentationResolution: String, CaseIterable, Sendable {
    case low = "Low (5 panels)"
    case medium = "Medium (8 panels)"
    case high = "High (15 panels)"
    
    public var targetPanelCount: Int {
        switch self {
        case .low: return 5
        case .medium: return 8
        case .high: return 15
        }
    }
}