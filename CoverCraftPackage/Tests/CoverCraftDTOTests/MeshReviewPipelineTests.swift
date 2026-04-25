// Version: 1.0.0
// CoverCraft DTO Tests - Mesh Review Pipeline Tests

import Testing
import simd
@testable import CoverCraftDTO

@Suite("Mesh Review Pipeline Tests")
struct MeshReviewPipelineTests {

    @Test("Empty raw scan mesh is invalid")
    func emptyRawScanMeshIsInvalid() {
        let mesh = MeshDTO(vertices: [], triangleIndices: [])

        #expect(!mesh.isValid)
    }

    @Test("Mesh with out-of-range triangle index is invalid")
    func outOfRangeTriangleIndexMeshIsInvalid() {
        let mesh = MeshDTO(
            vertices: [
                SIMD3<Float>(0, 0, 0),
                SIMD3<Float>(1, 0, 0),
                SIMD3<Float>(0, 1, 0)
            ],
            triangleIndices: [0, 1, 3]
        )

        #expect(!mesh.isValid)
    }
}
