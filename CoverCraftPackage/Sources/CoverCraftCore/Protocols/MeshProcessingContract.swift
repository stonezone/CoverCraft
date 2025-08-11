// Version: 1.0.0
// Protocol contracts for mesh processing operations

import Foundation
import CoverCraftDTO

/// Contract for mesh segmentation operations
@available(iOS 18.0, macOS 10.15, *)
public protocol MeshSegmentationContract: Actor {
    /// Segment mesh into panels using clustering algorithms
    /// - Parameters:
    ///   - meshData: The mesh to segment
    ///   - targetPanelCount: Desired number of panels
    /// - Returns: Array of segmented panels
    /// - Throws: SegmentationError for processing failures
    func segmentMesh(_ meshData: MeshDTO, targetPanelCount: Int) async throws -> [PanelDTO]
}

/// Contract for mesh data operations
public protocol MeshDataContract: Sendable {
    /// Convert internal mesh representation to DTO
    func toDTO() -> MeshDTO
    
    /// Create mesh from DTO representation
    static func fromDTO(_ dto: MeshDTO) -> Self
    
    /// Validate mesh integrity
    var isValid: Bool { get }
    
    /// Calculate mesh properties
    var triangleCount: Int { get }
    var vertexCount: Int { get }
}

/// Contract for pattern flattening operations
@available(iOS 18.0, macOS 10.15, *)
public protocol PatternFlattenerContract: Actor {
    /// Flatten 3D panels into 2D patterns
    /// - Parameter panels: 3D panels to flatten
    /// - Returns: Flattened 2D patterns
    /// - Throws: FlattenerError for processing failures
    func flattenPanels(_ panels: [PanelDTO]) async throws -> [FlattenedPatternDTO]
}

// SegmentationError is defined in CoverCraftErrors.swift

/// Errors that can occur during pattern flattening
public enum FlattenerError: LocalizedError, Sendable {
    case invalidGeometry
    case unflattenableShape
    case processingFailed
    
    public var errorDescription: String? {
        switch self {
        case .invalidGeometry:
            return "Invalid geometry for flattening"
        case .unflattenableShape:
            return "Shape cannot be flattened to 2D"
        case .processingFailed:
            return "Pattern flattening process failed"
        }
    }
}

/// Data transfer object for flattened patterns
public struct FlattenedPatternDTO: Codable, Sendable, Equatable {
    public let id: UUID
    public let panelId: UUID
    public let vertices2D: [SIMD2<Float>]
    public let bounds: BoundsDTO
    public let area: Float
    public let createdAt: Date
    
    public init(
        id: UUID,
        panelId: UUID,
        vertices2D: [SIMD2<Float>],
        bounds: BoundsDTO,
        area: Float,
        createdAt: Date
    ) {
        self.id = id
        self.panelId = panelId
        self.vertices2D = vertices2D
        self.bounds = bounds
        self.area = area
        self.createdAt = createdAt
    }
}

/// Bounds information for 2D patterns
public struct BoundsDTO: Codable, Sendable, Equatable {
    public let minX: Float
    public let minY: Float
    public let maxX: Float
    public let maxY: Float
    
    public init(minX: Float, minY: Float, maxX: Float, maxY: Float) {
        self.minX = minX
        self.minY = minY
        self.maxX = maxX
        self.maxY = maxY
    }
    
    public var width: Float { maxX - minX }
    public var height: Float { maxY - minY }
    public var center: SIMD2<Float> {
        SIMD2<Float>((minX + maxX) / 2, (minY + maxY) / 2)
    }
}

// SIMD2<Float> already conforms to Codable in Swift 5.3+