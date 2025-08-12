// Version: 1.0.0
// Test Data Factory for Segmentation Tests

import Foundation
import simd
import CoverCraftDTO
@testable import CoverCraftCore

@available(iOS 18.0, macOS 15.0, *)
public struct TestDataFactory {
    
    // MARK: - Basic Mesh Creation
    
    /// Create a simple cube mesh for testing
    public static func createCubeMesh() -> MeshDTO {
        let vertices: [SIMD3<Float>] = [
            SIMD3<Float>(-1, -1, -1), // 0
            SIMD3<Float>( 1, -1, -1), // 1
            SIMD3<Float>( 1,  1, -1), // 2
            SIMD3<Float>(-1,  1, -1), // 3
            SIMD3<Float>(-1, -1,  1), // 4
            SIMD3<Float>( 1, -1,  1), // 5
            SIMD3<Float>( 1,  1,  1), // 6
            SIMD3<Float>(-1,  1,  1)  // 7
        ]
        
        let triangleIndices: [Int] = [
            // Front face
            0, 1, 2,  0, 2, 3,
            // Back face
            4, 6, 5,  4, 7, 6,
            // Left face
            0, 3, 7,  0, 7, 4,
            // Right face
            1, 5, 6,  1, 6, 2,
            // Top face
            3, 2, 6,  3, 6, 7,
            // Bottom face
            0, 4, 5,  0, 5, 1
        ]
        
        return MeshDTO(vertices: vertices, triangleIndices: triangleIndices)
    }
    
    /// Create a simple triangle mesh
    public static func createTriangleMesh() -> MeshDTO {
        let vertices: [SIMD3<Float>] = [
            SIMD3<Float>(0, 0, 0),
            SIMD3<Float>(1, 0, 0),
            SIMD3<Float>(0.5, 1, 0)
        ]
        
        let triangleIndices: [Int] = [0, 1, 2]
        
        return MeshDTO(vertices: vertices, triangleIndices: triangleIndices)
    }
    
    /// Create a plane mesh
    public static func createPlaneMesh() -> MeshDTO {
        let vertices: [SIMD3<Float>] = [
            SIMD3<Float>(0, 0, 0),
            SIMD3<Float>(1, 0, 0),
            SIMD3<Float>(1, 1, 0),
            SIMD3<Float>(0, 1, 0)
        ]
        
        let triangleIndices: [Int] = [
            0, 1, 2,
            0, 2, 3
        ]
        
        return MeshDTO(vertices: vertices, triangleIndices: triangleIndices)
    }
    
    /// Create a complex mesh with variable complexity
    public static func createComplexMesh(complexity: Int) -> MeshDTO {
        let baseSize = max(1, complexity)
        var vertices: [SIMD3<Float>] = []
        var triangleIndices: [Int] = []
        
        // Generate grid of vertices
        for x in 0...baseSize {
            for y in 0...baseSize {
                for z in 0...baseSize {
                    let vertex = SIMD3<Float>(
                        Float(x) / Float(baseSize),
                        Float(y) / Float(baseSize), 
                        Float(z) / Float(baseSize)
                    )
                    vertices.append(vertex)
                }
            }
        }
        
        // Generate triangles connecting the vertices
        let gridSize = baseSize + 1
        for x in 0..<baseSize {
            for y in 0..<baseSize {
                for z in 0..<baseSize {
                    let index = x * gridSize * gridSize + y * gridSize + z
                    
                    // Create triangles for a cube at this position
                    if index + gridSize * gridSize + gridSize + 1 < vertices.count {
                        // Front face triangles
                        triangleIndices.append(contentsOf: [
                            index, index + 1, index + gridSize + 1,
                            index, index + gridSize + 1, index + gridSize
                        ])
                    }
                }
            }
        }
        
        return MeshDTO(vertices: vertices, triangleIndices: triangleIndices)
    }
    
    /// Create an invalid mesh for error testing
    public static func createInvalidMesh() -> MeshDTO {
        // Mesh with triangle indices that reference non-existent vertices
        let vertices: [SIMD3<Float>] = [
            SIMD3<Float>(0, 0, 0),
            SIMD3<Float>(1, 0, 0)
        ]
        
        let triangleIndices: [Int] = [0, 1, 5] // Index 5 doesn't exist
        
        return MeshDTO(vertices: vertices, triangleIndices: triangleIndices)
    }
    
    // MARK: - Edge Cases
    
    public struct EdgeCases {
        
        /// Create an empty mesh
        public static func emptyMesh() -> MeshDTO {
            return MeshDTO(vertices: [], triangleIndices: [])
        }
        
        /// Create mesh with duplicate vertices
        public static func duplicateVerticesMesh() -> MeshDTO {
            let vertices: [SIMD3<Float>] = [
                SIMD3<Float>(0, 0, 0),
                SIMD3<Float>(0, 0, 0), // Duplicate
                SIMD3<Float>(1, 0, 0),
                SIMD3<Float>(0.5, 1, 0)
            ]
            
            let triangleIndices: [Int] = [0, 2, 3]
            
            return MeshDTO(vertices: vertices, triangleIndices: triangleIndices)
        }
        
        /// Create mesh with degenerate triangles
        public static func degenerateTrianglesMesh() -> MeshDTO {
            let vertices: [SIMD3<Float>] = [
                SIMD3<Float>(0, 0, 0),
                SIMD3<Float>(1, 0, 0),
                SIMD3<Float>(2, 0, 0) // Collinear points
            ]
            
            let triangleIndices: [Int] = [0, 1, 2]
            
            return MeshDTO(vertices: vertices, triangleIndices: triangleIndices)
        }
    }
}

// MARK: - Mesh Fixtures

@available(iOS 18.0, macOS 15.0, *)
public struct MeshFixtures {
    
    public static let validMeshes: [MeshDTO] = [
        TestDataFactory.createTriangleMesh(),
        TestDataFactory.createCubeMesh(),
        TestDataFactory.createPlaneMesh(),
        TestDataFactory.createComplexMesh(complexity: 2)
    ]
    
    public static let degenerateTriangles = TestDataFactory.EdgeCases.degenerateTrianglesMesh()
    
    public static let largeMesh = TestDataFactory.createComplexMesh(complexity: 10)
}