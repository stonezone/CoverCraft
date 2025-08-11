import Foundation
import CoreGraphics

/// Represents a 3D panel flattened to 2D for pattern creation
public struct FlattenedPanel: Identifiable, Sendable, Equatable {
    public let id = UUID()
    public let points2D: [CGPoint]
    public let edges: [(Int, Int)]
    public let sourcePanel: Panel
    public let boundingBox: CGRect
    
    public init(points2D: [CGPoint], edges: [(Int, Int)], sourcePanel: Panel, boundingBox: CGRect) {
        self.points2D = points2D
        self.edges = edges
        self.sourcePanel = sourcePanel
        self.boundingBox = boundingBox
    }
    
    public static func == (lhs: FlattenedPanel, rhs: FlattenedPanel) -> Bool {
        lhs.id == rhs.id
    }
}