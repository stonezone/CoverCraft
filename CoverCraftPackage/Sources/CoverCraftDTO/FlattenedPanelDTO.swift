// Version: 1.0.0
// CoverCraft DTO Module - Flattened Panel Data Transfer Object

import Foundation
import CoreGraphics

/// Immutable data transfer object representing a flattened 2D panel
/// 
/// This DTO is designed for stable serialization and transfer between modules.
/// Breaking changes require a version bump and migration path.
@available(iOS 18.0, macOS 15.0, *)
public struct FlattenedPanelDTO: Sendable, Codable, Equatable, Identifiable {
    
    // MARK: - Properties
    
    /// Unique identifier for this flattened panel
    public let id: UUID
    
    /// 2D points representing the flattened panel boundary
    public let points2D: [CGPoint]
    
    /// Edges connecting the 2D points (pairs of indices into points2D)
    public let edges: [EdgeDTO]
    
    /// Display color for this panel
    public let color: ColorDTO
    
    /// Scale factor used for flattening (units per meter)
    public let scaleUnitsPerMeter: Double
    
    /// Version of the flattened panel data format
    public let version: String
    
    /// Timestamp when this panel was flattened
    public let createdAt: Date
    
    /// Optional reference to the original 3D panel ID
    public let originalPanelId: UUID?
    
    // MARK: - Initialization
    
    /// Creates a new flattened panel DTO
    /// - Parameters:
    ///   - points2D: 2D points representing the flattened panel
    ///   - edges: Edges connecting the points
    ///   - color: Display color for this panel
    ///   - scaleUnitsPerMeter: Scale factor (units per meter)
    ///   - id: Unique identifier (defaults to new UUID)
    ///   - originalPanelId: Optional reference to original 3D panel
    ///   - createdAt: Creation timestamp (defaults to now)
    public init(
        points2D: [CGPoint],
        edges: [EdgeDTO],
        color: ColorDTO,
        scaleUnitsPerMeter: Double,
        id: UUID = UUID(),
        originalPanelId: UUID? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.points2D = points2D
        self.edges = edges
        self.color = color
        self.scaleUnitsPerMeter = scaleUnitsPerMeter
        self.version = "1.0.0"
        self.originalPanelId = originalPanelId
        self.createdAt = createdAt
    }
    
    // MARK: - Computed Properties
    
    /// Whether this flattened panel is valid
    public var isValid: Bool {
        points2D.count >= 3 && // Minimum triangle
        !edges.isEmpty &&
        scaleUnitsPerMeter > 0 &&
        edges.allSatisfy { edge in
            edge.startIndex >= 0 && edge.startIndex < points2D.count &&
            edge.endIndex >= 0 && edge.endIndex < points2D.count
        }
    }
    
    /// Bounding box of the flattened panel
    public var boundingBox: CGRect {
        guard !points2D.isEmpty else { return .zero }
        
        let xs = points2D.map { $0.x }
        let ys = points2D.map { $0.y }
        
        let minX = xs.min() ?? 0
        let maxX = xs.max() ?? 0
        let minY = ys.min() ?? 0 
        let maxY = ys.max() ?? 0
        
        return CGRect(
            x: minX,
            y: minY,
            width: maxX - minX,
            height: maxY - minY
        )
    }
    
    /// Area of the flattened panel in square units
    public var area: Double {
        guard points2D.count >= 3 else { return 0 }
        
        // Use shoelace formula for polygon area
        var area: Double = 0
        let n = points2D.count
        
        for i in 0..<n {
            let j = (i + 1) % n
            area += points2D[i].x * points2D[j].y
            area -= points2D[j].x * points2D[i].y
        }
        
        return abs(area) / 2.0
    }
}

/// Edge data transfer object representing a connection between two points
@available(iOS 18.0, macOS 15.0, *)
public struct EdgeDTO: Sendable, Codable, Equatable {
    
    // MARK: - Properties
    
    /// Index of the start point
    public let startIndex: Int
    
    /// Index of the end point  
    public let endIndex: Int
    
    /// Type of edge (e.g., cut line, fold line, seam allowance)
    public let type: EdgeType
    
    /// Length of the edge in the original 3D space (for validation)
    public let original3DLength: Double?
    
    // MARK: - Initialization
    
    /// Creates a new edge DTO
    /// - Parameters:
    ///   - startIndex: Index of the start point
    ///   - endIndex: Index of the end point
    ///   - type: Type of edge
    ///   - original3DLength: Optional original 3D length for validation
    public init(
        startIndex: Int,
        endIndex: Int,
        type: EdgeType = .cutLine,
        original3DLength: Double? = nil
    ) {
        self.startIndex = startIndex
        self.endIndex = endIndex
        self.type = type
        self.original3DLength = original3DLength
    }
}

/// Types of edges in a flattened panel
@available(iOS 18.0, macOS 15.0, *)
public enum EdgeType: String, Sendable, Codable, CaseIterable {
    /// Edge to be cut
    case cutLine = "cut"
    
    /// Edge to be folded
    case foldLine = "fold"
    
    /// Seam allowance edge
    case seamAllowance = "seam"
    
    /// Registration/alignment mark
    case registrationMark = "registration"
}

// MARK: - Note: CGPoint conforms to Codable in iOS 18.0+