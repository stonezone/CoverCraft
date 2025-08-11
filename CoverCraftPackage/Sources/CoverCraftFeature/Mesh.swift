import Foundation
import simd

/// Represents a 3D mesh captured from LiDAR scanning
public struct Mesh: Equatable, Sendable {
    /// Array of 3D vertex positions
    public var vertices: [SIMD3<Float>]
    
    /// Triangle indices (groups of 3 indices into vertices array)
    public var triangleIndices: [Int]
    
    public init(vertices: [SIMD3<Float>], triangleIndices: [Int]) {
        self.vertices = vertices
        self.triangleIndices = triangleIndices
    }
    
    /// Computed property for number of triangles
    public var triangleCount: Int {
        triangleIndices.count / 3
    }
    
    /// Apply uniform scale to all vertices
    public func scaled(by factor: Float) -> Mesh {
        Mesh(
            vertices: vertices.map { $0 * factor },
            triangleIndices: triangleIndices
        )
    }
    
    /// Compute face normals for the mesh
    public func computeFaceNormals() -> [SIMD3<Float>] {
        var normals: [SIMD3<Float>] = []
        
        for triangleIndex in stride(from: 0, to: triangleIndices.count, by: 3) {
            let vertexA = vertices[triangleIndices[triangleIndex]]
            let vertexB = vertices[triangleIndices[triangleIndex + 1]]
            let vertexC = vertices[triangleIndices[triangleIndex + 2]]
            
            let edge1 = vertexB - vertexA
            let edge2 = vertexC - vertexA
            let normal = simd_normalize(simd_cross(edge1, edge2))
            
            normals.append(normal)
        }
        
        return normals
    }
}