import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Represents a segmented panel of the mesh
public struct Panel: Identifiable, Sendable {
    public let id = UUID()
    
    /// Indices of vertices that belong to this panel
    public var vertexIndices: Set<Int>
    
    /// Triangle indices for this panel
    public var triangleIndices: [Int]
    
    /// Color for visualization
    public var color: UIColor
    
    public init(vertexIndices: Set<Int>, triangleIndices: [Int], color: UIColor) {
        self.vertexIndices = vertexIndices
        self.triangleIndices = triangleIndices
        self.color = color
    }
    
    /// Check if panel is valid
    public var isValid: Bool {
        !vertexIndices.isEmpty && !triangleIndices.isEmpty
    }
}

/// Represents a flattened 2D panel ready for pattern generation
public struct FlattenedPanel: Identifiable, Sendable {
    public let id = UUID()
    
    /// 2D points after flattening
    public var points2D: [CGPoint]
    
    /// Original panel reference
    public let sourcePanel: Panel
    
    /// Edge connections (pairs of point indices)
    public var edges: [(Int, Int)]
    
    public init(points2D: [CGPoint], sourcePanel: Panel, edges: [(Int, Int)]) {
        self.points2D = points2D
        self.sourcePanel = sourcePanel
        self.edges = edges
    }
    
    /// Compute bounding box
    public var boundingBox: CGRect {
        guard !points2D.isEmpty else { return .zero }
        
        let xValues = points2D.map { $0.x }
        let yValues = points2D.map { $0.y }
        
        let minX = xValues.min() ?? 0
        let maxX = xValues.max() ?? 0
        let minY = yValues.min() ?? 0
        let maxY = yValues.max() ?? 0
        
        return CGRect(x: minX, y: minY, 
                     width: maxX - minX, 
                     height: maxY - minY)
    }
}