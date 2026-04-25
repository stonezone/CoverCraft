// Version: 1.0.0
// CoverCraft DTO Tests - Target Object Mesh DTO Tests

import Foundation
import Testing
import simd
@testable import CoverCraftDTO

@Suite("TargetObjectMeshDTO Tests")
struct TargetObjectMeshDTOTests {

    @Test("TargetObjectMeshDTO stores isolated mesh bounds and history")
    func storesIsolatedMeshBoundsAndHistory() throws {
        let mesh = Self.validMesh()
        let cropBounds = MeshBoundsDTO(
            min: MeshPoint3DTO(x: -1, y: -1, z: -1),
            max: MeshPoint3DTO(x: 2, y: 2, z: 2)
        )
        let history = [
            TargetObjectMeshProcessingHistoryEntry(
                operation: "segmentation",
                createdAt: Date(timeIntervalSince1970: 1_760_000_000),
                notes: "isolated target object"
            )
        ]

        let targetMesh = try TargetObjectMeshDTO(
            isolatedMesh: mesh,
            cropBounds: cropBounds,
            processingHistory: history
        )

        #expect(targetMesh.isolatedMesh == mesh)
        #expect(targetMesh.objectBounds.min == MeshPoint3DTO(x: -2, y: -3, z: -4))
        #expect(targetMesh.objectBounds.max == MeshPoint3DTO(x: 4, y: 5, z: 6))
        #expect(targetMesh.cropBounds == cropBounds)
        #expect(targetMesh.processingHistory == history)
        #expect(targetMesh.isValid)
        #expect(targetMesh.version == "1.0.0")
    }

    @Test("TargetObjectMeshDTO rejects invalid isolated mesh")
    func rejectsInvalidIsolatedMesh() {
        let invalidMesh = MeshDTO(vertices: [], triangleIndices: [])

        #expect(throws: TargetObjectMeshDTO.ValidationError.invalidIsolatedMesh) {
            _ = try TargetObjectMeshDTO(isolatedMesh: invalidMesh)
        }
    }

    @Test("TargetObjectMeshDTO codable round trip preserves contract")
    func codableRoundTripPreservesContract() throws {
        let targetMesh = try TargetObjectMeshDTO(
            isolatedMesh: Self.validMesh(),
            processingHistory: [
                TargetObjectMeshProcessingHistoryEntry(
                    operation: "crop",
                    createdAt: Date(timeIntervalSince1970: 1_760_000_010)
                )
            ]
        )

        let data = try JSONEncoder().encode(targetMesh)
        let decoded = try JSONDecoder().decode(TargetObjectMeshDTO.self, from: data)

        #expect(decoded == targetMesh)
        #expect(decoded.isValid)
    }

    private static func validMesh() -> MeshDTO {
        MeshDTO(
            vertices: [
                SIMD3<Float>(-2, -3, -4),
                SIMD3<Float>(4, 0, 1),
                SIMD3<Float>(1, 5, 6)
            ],
            triangleIndices: [0, 1, 2]
        )
    }
}
