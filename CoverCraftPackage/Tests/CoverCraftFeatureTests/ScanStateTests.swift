// Version: 1.0.0
// CoverCraft Feature Tests - Scan State Tests

import Testing
import simd
import CoverCraftDTO
@testable import CoverCraftFeature

@Suite("ScanState Tests")
@MainActor
struct ScanStateTests {

    @Test("Effective mesh falls back to valid raw mesh when processed mesh is invalid")
    func effectiveMeshFallsBackFromInvalidProcessedMesh() {
        let state = ScanState()
        let rawMesh = Self.validMesh()
        let invalidProcessedMesh = Self.invalidMesh()

        state.currentMesh = rawMesh
        state.processedMesh = invalidProcessedMesh

        #expect(state.effectiveMesh == rawMesh)
    }

    @Test("Invalid processed mesh does not count as processed")
    func invalidProcessedMeshDoesNotCountAsProcessed() {
        let state = ScanState()

        state.processedMesh = Self.invalidMesh()

        #expect(!state.hasProcessedMesh)
    }

    @Test("Invalid raw scan is not generation-ready even when calibrated")
    func invalidRawScanIsNotGenerationReady() {
        let state = AppState()

        state.inputMode = .scan
        state.currentMesh = Self.invalidMesh()
        state.calibrationData = Self.completeCalibration()

        #expect(!state.canGeneratePattern)
    }

    @Test("Manual dimensions remain generation-ready without scan mesh")
    func manualDimensionsRemainGenerationReadyWithoutScanMesh() {
        let state = AppState()

        state.inputMode = .manual
        state.patternMode = .slipcover
        state.manualWidthMillimeters = 500
        state.manualDepthMillimeters = 600
        state.manualHeightMillimeters = 700

        #expect(state.canGeneratePattern)
    }

    private static func validMesh() -> MeshDTO {
        MeshDTO(
            vertices: [
                SIMD3<Float>(0, 0, 0),
                SIMD3<Float>(1, 0, 0),
                SIMD3<Float>(0, 1, 0)
            ],
            triangleIndices: [0, 1, 2]
        )
    }

    private static func invalidMesh() -> MeshDTO {
        MeshDTO(vertices: [], triangleIndices: [])
    }

    private static func completeCalibration() -> CalibrationDTO {
        CalibrationDTO.with(
            firstPoint: SIMD3<Float>(0, 0, 0),
            secondPoint: SIMD3<Float>(1, 0, 0),
            realWorldDistance: 1.0
        )
    }
}
