// Version: 1.0.0
// CoverCraft DTO Tests - Scan Artifact DTO Tests

import Foundation
import Testing
import simd
@testable import CoverCraftDTO

@Suite("ScanArtifactDTO Tests")
struct ScanArtifactDTOTests {

    @Test("ScanArtifactDTO stores raw mesh and provenance")
    func storesRawMeshAndProvenance() throws {
        let createdAt = Date(timeIntervalSince1970: 1_750_000_000)
        let mesh = Self.validMesh(createdAt: createdAt)

        let artifact = try ScanArtifactDTO(
            rawMesh: mesh,
            source: .lidar,
            createdAt: createdAt,
            deviceModel: "iPhone17,1",
            trackingQuality: .normal
        )

        #expect(artifact.rawMesh == mesh)
        #expect(artifact.source == .lidar)
        #expect(artifact.createdAt == createdAt)
        #expect(artifact.deviceModel == "iPhone17,1")
        #expect(artifact.trackingQuality == .normal)
        #expect(artifact.version == "1.0.0")
    }

    @Test("ScanArtifactDTO rejects invalid raw mesh")
    func rejectsInvalidRawMesh() {
        let invalidMesh = MeshDTO(vertices: [], triangleIndices: [])

        #expect(throws: ScanArtifactDTO.ValidationError.invalidRawMesh) {
            _ = try ScanArtifactDTO(rawMesh: invalidMesh, source: .lidar)
        }
    }

    @Test("ScanArtifactDTO codable round trip preserves contract")
    func codableRoundTripPreservesContract() throws {
        let artifact = try ScanArtifactDTO(
            rawMesh: Self.validMesh(),
            source: .imported,
            deviceModel: nil,
            trackingQuality: .limited
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(artifact)
        let decoded = try JSONDecoder().decode(ScanArtifactDTO.self, from: data)

        #expect(decoded == artifact)
        #expect(decoded.rawMesh.isValid)
    }

    private static func validMesh(createdAt: Date = Date(timeIntervalSince1970: 1_700_000_000)) -> MeshDTO {
        MeshDTO(
            vertices: [
                SIMD3<Float>(0, 0, 0),
                SIMD3<Float>(1, 0, 0),
                SIMD3<Float>(0, 1, 0)
            ],
            triangleIndices: [0, 1, 2],
            createdAt: createdAt
        )
    }
}
