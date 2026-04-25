// Version: 1.0.0
// CoverCraft AR Tests - Final Mesh Selection

import Testing
import simd
@testable import CoverCraftAR
import CoverCraftDTO

@Suite("Final Mesh Selection Tests")
struct FinalMeshSelectionTests {

    @Test("Prefers valid raw captured mesh over valid filtered subset")
    func prefersRawCapturedMesh() {
        let filtered = MeshDTO(
            vertices: [
                SIMD3<Float>(0, 0, 0),
                SIMD3<Float>(1, 0, 0),
                SIMD3<Float>(0, 1, 0)
            ],
            triangleIndices: [0, 1, 2]
        )
        let raw = MeshDTO(
            vertices: [
                SIMD3<Float>(0, 0, 0),
                SIMD3<Float>(1, 0, 0),
                SIMD3<Float>(0, 1, 0),
                SIMD3<Float>(1, 1, 0)
            ],
            triangleIndices: [0, 1, 2, 1, 3, 2]
        )

        let selected = FinalMeshSelection.preferredFinalMesh(filtered: filtered, raw: raw)

        #expect(selected.id == raw.id)
        #expect(selected.vertices.count == 4)
        #expect(selected.triangleCount == 2)
    }

    @Test("Uses filtered mesh only when raw mesh is invalid")
    func usesFilteredWhenRawInvalid() {
        let filtered = MeshDTO(
            vertices: [
                SIMD3<Float>(0, 0, 0),
                SIMD3<Float>(1, 0, 0),
                SIMD3<Float>(0, 1, 0)
            ],
            triangleIndices: [0, 1, 2]
        )
        let raw = MeshDTO(vertices: [], triangleIndices: [])

        let selected = FinalMeshSelection.preferredFinalMesh(filtered: filtered, raw: raw)

        #expect(selected.id == filtered.id)
        #expect(selected.isValid)
    }

    @Test("Returns invalid filtered mesh when both candidates are invalid")
    func returnsFilteredWhenBothInvalid() {
        let filtered = MeshDTO(vertices: [], triangleIndices: [])
        let raw = MeshDTO(vertices: [SIMD3<Float>(0, 0, 0)], triangleIndices: [])

        let selected = FinalMeshSelection.preferredFinalMesh(filtered: filtered, raw: raw)

        #expect(selected.id == filtered.id)
        #expect(!selected.isValid)
    }
}
