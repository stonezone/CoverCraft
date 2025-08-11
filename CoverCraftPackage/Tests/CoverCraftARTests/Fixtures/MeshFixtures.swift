// Version: 1.0.0
// Test Fixtures for AR Module - Mesh Data

import Foundation
import simd
import CoverCraftDTO

/// Test fixtures for MeshDTO objects covering normal scenarios and edge cases
@available(iOS 18.0, *)
public struct MeshFixtures {
    
    // MARK: - Basic Geometric Shapes
    
    /// Simple cube mesh with 8 vertices and 12 triangles
    public static let simpleCube = MeshDTO(
        vertices: [
            // Bottom face
            SIMD3<Float>(-0.5, -0.5, -0.5), // 0
            SIMD3<Float>( 0.5, -0.5, -0.5), // 1
            SIMD3<Float>( 0.5, -0.5,  0.5), // 2
            SIMD3<Float>(-0.5, -0.5,  0.5), // 3
            // Top face
            SIMD3<Float>(-0.5,  0.5, -0.5), // 4
            SIMD3<Float>( 0.5,  0.5, -0.5), // 5
            SIMD3<Float>( 0.5,  0.5,  0.5), // 6
            SIMD3<Float>(-0.5,  0.5,  0.5)  // 7
        ],
        triangleIndices: [
            // Bottom face
            0, 1, 2, 0, 2, 3,
            // Top face
            4, 7, 6, 4, 6, 5,
            // Front face
            0, 4, 5, 0, 5, 1,
            // Back face
            2, 6, 7, 2, 7, 3,
            // Left face
            0, 3, 7, 0, 7, 4,
            // Right face
            1, 5, 6, 1, 6, 2
        ],
        id: UUID(uuidString: "12345678-1234-1234-1234-123456781234")!,
        createdAt: Date(timeIntervalSince1970: 1609459200) // Fixed timestamp: 2021-01-01
    )
    
    /// Simple triangle (minimal valid mesh)
    public static let singleTriangle = MeshDTO(
        vertices: [
            SIMD3<Float>(0.0, 0.0, 0.0),
            SIMD3<Float>(1.0, 0.0, 0.0),
            SIMD3<Float>(0.5, 1.0, 0.0)
        ],
        triangleIndices: [0, 1, 2],
        id: UUID(uuidString: "12345678-1234-1234-1234-123456781235")!,
        createdAt: Date(timeIntervalSince1970: 1609459200)
    )
    
    /// Tetrahedron (4 vertices, 4 triangular faces)
    public static let tetrahedron = MeshDTO(
        vertices: [
            SIMD3<Float>(0.0, 0.0, 0.0),
            SIMD3<Float>(1.0, 0.0, 0.0),
            SIMD3<Float>(0.5, 0.866, 0.0), // sqrt(3)/2 ≈ 0.866
            SIMD3<Float>(0.5, 0.289, 0.816) // height of tetrahedron
        ],
        triangleIndices: [
            0, 1, 2,  // Bottom face
            0, 3, 1,  // Front face
            1, 3, 2,  // Right face
            2, 3, 0   // Left face
        ],
        id: UUID(uuidString: "12345678-1234-1234-1234-123456781236")!,
        createdAt: Date(timeIntervalSince1970: 1609459200)
    )
    
    // MARK: - Complex Garment-Like Meshes
    
    /// Complex T-shirt like mesh with multiple connected surfaces
    public static let tshirtMesh = MeshDTO(
        vertices: [
            // Torso front vertices (0-7)
            SIMD3<Float>(-0.3, -0.8, 0.1),  // 0: Bottom left front
            SIMD3<Float>( 0.3, -0.8, 0.1),  // 1: Bottom right front
            SIMD3<Float>( 0.3,  0.2, 0.1),  // 2: Top right front (chest)
            SIMD3<Float>(-0.3,  0.2, 0.1),  // 3: Top left front (chest)
            SIMD3<Float>(-0.2,  0.4, 0.1),  // 4: Neck left front
            SIMD3<Float>( 0.2,  0.4, 0.1),  // 5: Neck right front
            SIMD3<Float>( 0.1,  0.5, 0.1),  // 6: Neck center right front
            SIMD3<Float>(-0.1,  0.5, 0.1),  // 7: Neck center left front
            
            // Torso back vertices (8-15)
            SIMD3<Float>(-0.3, -0.8, -0.1), // 8: Bottom left back
            SIMD3<Float>( 0.3, -0.8, -0.1), // 9: Bottom right back
            SIMD3<Float>( 0.3,  0.2, -0.1), // 10: Top right back
            SIMD3<Float>(-0.3,  0.2, -0.1), // 11: Top left back
            SIMD3<Float>(-0.2,  0.4, -0.1), // 12: Neck left back
            SIMD3<Float>( 0.2,  0.4, -0.1), // 13: Neck right back
            SIMD3<Float>( 0.1,  0.5, -0.1), // 14: Neck center right back
            SIMD3<Float>(-0.1,  0.5, -0.1), // 15: Neck center left back
            
            // Left sleeve vertices (16-23)
            SIMD3<Float>(-0.3,  0.2, 0.0),  // 16: Shoulder connection
            SIMD3<Float>(-0.6,  0.1, 0.0),  // 17: Upper arm
            SIMD3<Float>(-0.7, -0.2, 0.0),  // 18: Elbow
            SIMD3<Float>(-0.8, -0.5, 0.0),  // 19: Lower arm
            SIMD3<Float>(-0.75, -0.6, 0.05), // 20: Wrist front
            SIMD3<Float>(-0.75, -0.6, -0.05), // 21: Wrist back
            SIMD3<Float>(-0.65, -0.1, 0.05),  // 22: Upper arm front
            SIMD3<Float>(-0.65, -0.1, -0.05), // 23: Upper arm back
            
            // Right sleeve vertices (24-31)
            SIMD3<Float>( 0.3,  0.2, 0.0),  // 24: Shoulder connection
            SIMD3<Float>( 0.6,  0.1, 0.0),  // 25: Upper arm
            SIMD3<Float>( 0.7, -0.2, 0.0),  // 26: Elbow
            SIMD3<Float>( 0.8, -0.5, 0.0),  // 27: Lower arm
            SIMD3<Float>( 0.75, -0.6, 0.05), // 28: Wrist front
            SIMD3<Float>( 0.75, -0.6, -0.05), // 29: Wrist back
            SIMD3<Float>( 0.65, -0.1, 0.05),  // 30: Upper arm front
            SIMD3<Float>( 0.65, -0.1, -0.05)  // 31: Upper arm back
        ],
        triangleIndices: [
            // Front torso
            0, 1, 2, 0, 2, 3,
            3, 2, 5, 3, 5, 4,
            4, 5, 6, 4, 6, 7,
            
            // Back torso
            8, 11, 10, 8, 10, 9,
            11, 12, 13, 11, 13, 10,
            12, 15, 14, 12, 14, 13,
            
            // Left sleeve (simplified)
            16, 17, 22, 17, 18, 19,
            19, 20, 21, 22, 23, 17,
            
            // Right sleeve (simplified)
            24, 25, 30, 25, 26, 27,
            27, 28, 29, 30, 31, 25,
            
            // Side seams (connecting front/back)
            0, 8, 9, 0, 9, 1,
            3, 10, 11, 2, 10, 3
        ],
        id: UUID(uuidString: "12345678-1234-1234-1234-123456781237")!,
        createdAt: Date(timeIntervalSince1970: 1609459200)
    )
    
    // MARK: - Edge Case Meshes
    
    /// Empty mesh (invalid)
    public static let emptyMesh = MeshDTO(
        vertices: [],
        triangleIndices: [],
        id: UUID(uuidString: "12345678-1234-1234-1234-123456781238")!,
        createdAt: Date(timeIntervalSince1970: 1609459200)
    )
    
    /// Mesh with vertices but no triangles (invalid)
    public static let orphanVertices = MeshDTO(
        vertices: [
            SIMD3<Float>(0.0, 0.0, 0.0),
            SIMD3<Float>(1.0, 0.0, 0.0),
            SIMD3<Float>(0.0, 1.0, 0.0)
        ],
        triangleIndices: [],
        id: UUID(uuidString: "12345678-1234-1234-1234-123456781239")!,
        createdAt: Date(timeIntervalSince1970: 1609459200)
    )
    
    /// Mesh with invalid triangle indices (out of bounds)
    public static let invalidTriangleIndices = MeshDTO(
        vertices: [
            SIMD3<Float>(0.0, 0.0, 0.0),
            SIMD3<Float>(1.0, 0.0, 0.0)
        ],
        triangleIndices: [0, 1, 5], // Index 5 is out of bounds
        id: UUID(uuidString: "12345678-1234-1234-1234-123456781240")!,
        createdAt: Date(timeIntervalSince1970: 1609459200)
    )
    
    /// Non-manifold mesh (edge shared by more than 2 triangles)
    public static let nonManifoldMesh = MeshDTO(
        vertices: [
            SIMD3<Float>(0.0, 0.0, 0.0),   // 0: Center
            SIMD3<Float>(1.0, 0.0, 0.0),   // 1: Right
            SIMD3<Float>(-1.0, 0.0, 0.0),  // 2: Left
            SIMD3<Float>(0.0, 1.0, 0.0),   // 3: Top
            SIMD3<Float>(0.0, -1.0, 0.0),  // 4: Bottom
            SIMD3<Float>(0.0, 0.0, 1.0)    // 5: Front
        ],
        triangleIndices: [
            0, 1, 3,  // Triangle 1 (shares edge 0-1 with triangles 2 & 3)
            0, 1, 4,  // Triangle 2 (shares edge 0-1 with triangles 1 & 3)
            0, 1, 5   // Triangle 3 (shares edge 0-1 with triangles 1 & 2) - non-manifold!
        ],
        id: UUID(uuidString: "12345678-1234-1234-1234-123456781241")!,
        createdAt: Date(timeIntervalSince1970: 1609459200)
    )
    
    /// Degenerate triangles (all vertices on same line)
    public static let degenerateTriangles = MeshDTO(
        vertices: [
            SIMD3<Float>(0.0, 0.0, 0.0),
            SIMD3<Float>(0.5, 0.0, 0.0),
            SIMD3<Float>(1.0, 0.0, 0.0)   // All on same line - zero area
        ],
        triangleIndices: [0, 1, 2],
        id: UUID(uuidString: "12345678-1234-1234-1234-123456781242")!,
        createdAt: Date(timeIntervalSince1970: 1609459200)
    )
    
    // MARK: - Large Scale Test Meshes
    
    /// Large mesh for performance testing (100 vertices, 196 triangles)
    public static let largeMesh: MeshDTO = {
        var vertices: [SIMD3<Float>] = []
        var triangleIndices: [Int] = []
        
        // Generate 10x10 grid of vertices
        for i in 0..<10 {
            for j in 0..<10 {
                vertices.append(SIMD3<Float>(
                    Float(i) * 0.1,
                    Float(j) * 0.1,
                    sin(Float(i) * 0.5) * cos(Float(j) * 0.5) * 0.1 // Wavy surface
                ))
            }
        }
        
        // Generate triangles for grid (2 triangles per quad)
        for i in 0..<9 {
            for j in 0..<9 {
                let bottomLeft = i * 10 + j
                let bottomRight = bottomLeft + 1
                let topLeft = bottomLeft + 10
                let topRight = topLeft + 1
                
                // First triangle
                triangleIndices.append(contentsOf: [bottomLeft, topLeft, topRight])
                // Second triangle
                triangleIndices.append(contentsOf: [bottomLeft, topRight, bottomRight])
            }
        }
        
        return MeshDTO(
            vertices: vertices,
            triangleIndices: triangleIndices,
            id: UUID(uuidString: "12345678-1234-1234-1234-123456781243")!,
            createdAt: Date(timeIntervalSince1970: 1609459200)
        )
    }()
    
    // MARK: - Helper Methods
    
    /// All valid mesh fixtures for testing
    public static let validMeshes: [MeshDTO] = [
        simpleCube,
        singleTriangle,
        tetrahedron,
        tshirtMesh,
        largeMesh
    ]
    
    /// All invalid mesh fixtures for testing error handling
    public static let invalidMeshes: [MeshDTO] = [
        emptyMesh,
        orphanVertices,
        invalidTriangleIndices,
        nonManifoldMesh,
        degenerateTriangles
    ]
    
    /// All mesh fixtures combined
    public static let allMeshes: [MeshDTO] = validMeshes + invalidMeshes
    
    /// Get a random valid mesh for testing
    public static func randomValidMesh() -> MeshDTO {
        validMeshes.randomElement() ?? simpleCube
    }
    
    /// Create a scaled version of a mesh for testing
    public static func scaledMesh(_ mesh: MeshDTO, scale: Float) -> MeshDTO {
        mesh.scaled(by: scale)
    }
}