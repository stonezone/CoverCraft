// Version: 1.0.0
// CoverCraft DTO Tests - Mesh DTO Tests

import Testing
import simd
@testable import CoverCraftDTO

@Suite("MeshDTO Tests")
struct MeshDTOTests {
    
    @Test("MeshDTO creation and validation") 
    func meshDTOCreation() {
        let vertices: [SIMD3<Float>] = [
            SIMD3<Float>(0, 0, 0),
            SIMD3<Float>(1, 0, 0),
            SIMD3<Float>(0, 1, 0)
        ]
        let triangleIndices = [0, 1, 2]
        
        let mesh = MeshDTO(vertices: vertices, triangleIndices: triangleIndices)
        
        #expect(mesh.isValid)
        #expect(mesh.vertices.count == 3)
        #expect(mesh.triangleIndices.count == 3)
        #expect(mesh.triangleCount == 1)
        #expect(mesh.version == "1.0.0")
    }
    
    @Test("Invalid mesh detection")
    func invalidMeshDetection() {
        // Empty mesh
        let emptyMesh = MeshDTO(vertices: [], triangleIndices: [])
        #expect(!emptyMesh.isValid)
        
        // Invalid triangle indices
        let vertices: [SIMD3<Float>] = [
            SIMD3<Float>(0, 0, 0),
            SIMD3<Float>(1, 0, 0)
        ]
        let invalidTriangleIndices = [0, 1, 5] // Index 5 doesn't exist
        let invalidMesh = MeshDTO(vertices: vertices, triangleIndices: invalidTriangleIndices)
        #expect(!invalidMesh.isValid)
    }
    
    @Test("Mesh scaling")
    func meshScaling() {
        let vertices: [SIMD3<Float>] = [
            SIMD3<Float>(1, 2, 3),
            SIMD3<Float>(4, 5, 6)
        ]
        let triangleIndices = [0, 1, 0]
        
        let originalMesh = MeshDTO(vertices: vertices, triangleIndices: triangleIndices)
        let scaledMesh = originalMesh.scaled(by: 2.0)
        
        #expect(scaledMesh.vertices[0] == SIMD3<Float>(2, 4, 6))
        #expect(scaledMesh.vertices[1] == SIMD3<Float>(8, 10, 12))
        #expect(scaledMesh.triangleIndices == originalMesh.triangleIndices)
    }
    
    @Test("Bounding box calculation")
    func boundingBoxCalculation() {
        let vertices: [SIMD3<Float>] = [
            SIMD3<Float>(-1, -2, -3),
            SIMD3<Float>(4, 5, 6),
            SIMD3<Float>(2, 1, 0)
        ]
        let triangleIndices = [0, 1, 2]
        
        let mesh = MeshDTO(vertices: vertices, triangleIndices: triangleIndices)
        let bbox = mesh.boundingBox()
        
        #expect(bbox?.min == SIMD3<Float>(-1, -2, -3))
        #expect(bbox?.max == SIMD3<Float>(4, 5, 6))
    }
}