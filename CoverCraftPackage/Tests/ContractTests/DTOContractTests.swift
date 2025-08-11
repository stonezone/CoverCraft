// Version: 1.0.0
// CoverCraft Contract Tests - DTO Contract Tests

import Testing
import SnapshotTesting
import Foundation
import simd
@testable import CoverCraftDTO

/// Contract tests to ensure DTO serialization remains stable across versions
/// These tests protect against breaking changes in the API
@Suite("DTO Contract Tests")
struct DTOContractTests {
    
    // MARK: - MeshDTO Contract Tests
    
    @Test("MeshDTO serialization contract")
    func meshDTOSerializationContract() throws {
        let vertices: [SIMD3<Float>] = [
            SIMD3<Float>(0.0, 0.0, 0.0),
            SIMD3<Float>(1.0, 0.0, 0.0),
            SIMD3<Float>(0.5, 1.0, 0.0),
            SIMD3<Float>(0.0, 0.0, 1.0)
        ]
        
        let triangleIndices = [0, 1, 2, 0, 2, 3, 1, 3, 2]
        
        let fixedDate = Date(timeIntervalSince1970: 1640995200) // 2022-01-01 00:00:00 UTC
        let fixedUUID = UUID(uuidString: "12345678-1234-1234-1234-123456789012")!
        
        let mesh = MeshDTO(
            vertices: vertices,
            triangleIndices: triangleIndices,
            id: fixedUUID,
            createdAt: fixedDate
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        let jsonData = try encoder.encode(mesh)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        
        // Snapshot test to detect any serialization changes
        assertSnapshot(
            of: jsonString,
            as: .lines,
            named: "MeshDTO_v1.0.0_Contract"
        )
        
        // Ensure we can deserialize back
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let deserializedMesh = try decoder.decode(MeshDTO.self, from: jsonData)
        
        #expect(deserializedMesh == mesh)
        #expect(deserializedMesh.version == "1.0.0")
    }
    
    @Test("MeshDTO backward compatibility")
    func meshDTOBackwardCompatibility() throws {
        // Test JSON from a previous version to ensure we can still deserialize
        let legacyJSON = """
        {
          "createdAt" : "2022-01-01T00:00:00Z",
          "id" : "12345678-1234-1234-1234-123456789012",
          "triangleIndices" : [ 0, 1, 2 ],
          "version" : "1.0.0",
          "vertices" : [
            [ 0.0, 0.0, 0.0 ],
            [ 1.0, 0.0, 0.0 ],
            [ 0.5, 1.0, 0.0 ]
          ]
        }
        """
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let mesh = try decoder.decode(MeshDTO.self, from: legacyJSON.data(using: .utf8)!)
        
        #expect(mesh.vertices.count == 3)
        #expect(mesh.triangleIndices == [0, 1, 2])
        #expect(mesh.version == "1.0.0")
        #expect(mesh.isValid)
    }
    
    // MARK: - PanelDTO Contract Tests
    
    @Test("PanelDTO serialization contract")
    func panelDTOSerializationContract() throws {
        let fixedDate = Date(timeIntervalSince1970: 1640995200)
        let fixedUUID = UUID(uuidString: "87654321-4321-4321-4321-210987654321")!
        
        let panel = PanelDTO(
            vertexIndices: Set([0, 1, 2, 5, 8]),
            triangleIndices: [0, 1, 2, 2, 5, 8],
            color: ColorDTO.red,
            id: fixedUUID,
            createdAt: fixedDate
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        let jsonData = try encoder.encode(panel)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        
        assertSnapshot(
            of: jsonString,
            as: .lines,
            named: "PanelDTO_v1.0.0_Contract"
        )
        
        // Verify round-trip serialization
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let deserializedPanel = try decoder.decode(PanelDTO.self, from: jsonData)
        
        #expect(deserializedPanel == panel)
        #expect(deserializedPanel.version == "1.0.0")
    }
    
    @Test("ColorDTO serialization contract")
    func colorDTOSerializationContract() throws {
        let color = ColorDTO(red: 0.8, green: 0.4, blue: 0.2, alpha: 0.9)
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let jsonData = try encoder.encode(color)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        
        assertSnapshot(
            of: jsonString,
            as: .lines,
            named: "ColorDTO_v1.0.0_Contract"
        )
        
        // Verify color value clamping
        let extremeColor = ColorDTO(red: 2.0, green: -1.0, blue: 1.5, alpha: 3.0)
        #expect(extremeColor.red == 1.0)
        #expect(extremeColor.green == 0.0)
        #expect(extremeColor.blue == 1.0)
        #expect(extremeColor.alpha == 1.0)
    }
    
    // MARK: - FlattenedPanelDTO Contract Tests
    
    @Test("FlattenedPanelDTO serialization contract")
    func flattenedPanelDTOSerializationContract() throws {
        let points2D = [
            CGPoint(x: 0.0, y: 0.0),
            CGPoint(x: 10.0, y: 0.0),
            CGPoint(x: 10.0, y: 15.0),
            CGPoint(x: 0.0, y: 15.0)
        ]
        
        let edges = [
            EdgeDTO(startIndex: 0, endIndex: 1, type: .cutLine),
            EdgeDTO(startIndex: 1, endIndex: 2, type: .cutLine),
            EdgeDTO(startIndex: 2, endIndex: 3, type: .cutLine),
            EdgeDTO(startIndex: 3, endIndex: 0, type: .cutLine)
        ]
        
        let fixedDate = Date(timeIntervalSince1970: 1640995200)
        let fixedUUID = UUID(uuidString: "11111111-2222-3333-4444-555555555555")!
        let originalPanelUUID = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!
        
        let flattenedPanel = FlattenedPanelDTO(
            points2D: points2D,
            edges: edges,
            color: ColorDTO.blue,
            scaleUnitsPerMeter: 100.0,
            id: fixedUUID,
            originalPanelId: originalPanelUUID,
            createdAt: fixedDate
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        let jsonData = try encoder.encode(flattenedPanel)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        
        assertSnapshot(
            of: jsonString,
            as: .lines,
            named: "FlattenedPanelDTO_v1.0.0_Contract"
        )
        
        // Verify computed properties
        #expect(flattenedPanel.isValid)
        #expect(flattenedPanel.boundingBox == CGRect(x: 0, y: 0, width: 10, height: 15))
        #expect(flattenedPanel.area == 150.0) // 10 * 15
    }
    
    @Test("EdgeDTO and EdgeType contract")
    func edgeDTOContract() throws {
        let edge = EdgeDTO(
            startIndex: 5,
            endIndex: 10,
            type: .seamAllowance,
            original3DLength: 2.5
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let jsonData = try encoder.encode(edge)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        
        assertSnapshot(
            of: jsonString,
            as: .lines,
            named: "EdgeDTO_v1.0.0_Contract"
        )
        
        // Test all EdgeType cases for stability
        let allEdgeTypes = EdgeType.allCases
        #expect(allEdgeTypes.count == 4)
        #expect(allEdgeTypes.contains(.cutLine))
        #expect(allEdgeTypes.contains(.foldLine))
        #expect(allEdgeTypes.contains(.seamAllowance))
        #expect(allEdgeTypes.contains(.registrationMark))
        
        // Test EdgeType raw values (contract stability)
        #expect(EdgeType.cutLine.rawValue == "cut")
        #expect(EdgeType.foldLine.rawValue == "fold")
        #expect(EdgeType.seamAllowance.rawValue == "seam")
        #expect(EdgeType.registrationMark.rawValue == "registration")
    }
    
    // MARK: - CalibrationDTO Contract Tests
    
    @Test("CalibrationDTO serialization contract")
    func calibrationDTOSerializationContract() throws {
        let fixedDate = Date(timeIntervalSince1970: 1640995200)
        let fixedUUID = UUID(uuidString: "CALIBRAT-ION1-2345-6789-ABCDEFGHIJKL")!
        
        let calibration = CalibrationDTO(
            cameraIntrinsics: matrix_float3x3(
                SIMD3<Float>(525.0, 0.0, 320.0),
                SIMD3<Float>(0.0, 525.0, 240.0),
                SIMD3<Float>(0.0, 0.0, 1.0)
            ),
            pixelsPerMeter: 1000.0,
            confidence: 0.95,
            id: fixedUUID,
            createdAt: fixedDate
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        let jsonData = try encoder.encode(calibration)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        
        assertSnapshot(
            of: jsonString,
            as: .lines,
            named: "CalibrationDTO_v1.0.0_Contract"
        )
        
        // Verify validation
        #expect(calibration.isValid)
        
        // Test invalid calibration
        let invalidCalibration = CalibrationDTO(
            cameraIntrinsics: matrix_float3x3(),
            pixelsPerMeter: -100.0,
            confidence: 1.5
        )
        #expect(!invalidCalibration.isValid)
    }
    
    // MARK: - Cross-DTO Integration Tests
    
    @Test("DTO version consistency")
    func dtoVersionConsistency() {
        let mesh = MeshDTO(vertices: [], triangleIndices: [])
        let panel = PanelDTO(vertexIndices: [], triangleIndices: [], color: ColorDTO.red)
        let flattenedPanel = FlattenedPanelDTO(
            points2D: [],
            edges: [],
            color: ColorDTO.blue,
            scaleUnitsPerMeter: 1.0
        )
        let calibration = CalibrationDTO(
            cameraIntrinsics: matrix_float3x3(),
            pixelsPerMeter: 1.0,
            confidence: 1.0
        )
        
        // All DTOs should have the same version
        let expectedVersion = "1.0.0"
        #expect(mesh.version == expectedVersion)
        #expect(panel.version == expectedVersion)
        #expect(flattenedPanel.version == expectedVersion)
        #expect(calibration.version == expectedVersion)
    }
    
    @Test("DTO ID and timestamp contracts")
    func dtoIDAndTimestampContracts() {
        let beforeCreation = Date()
        
        let mesh = MeshDTO(vertices: [], triangleIndices: [])
        let panel = PanelDTO(vertexIndices: [], triangleIndices: [], color: ColorDTO.green)
        let calibration = CalibrationDTO(
            cameraIntrinsics: matrix_float3x3(),
            pixelsPerMeter: 1.0,
            confidence: 1.0
        )
        
        let afterCreation = Date()
        
        // All DTOs should have unique IDs
        let ids = [mesh.id, panel.id, calibration.id]
        let uniqueIds = Set(ids)
        #expect(uniqueIds.count == ids.count)
        
        // All creation timestamps should be within the test timeframe
        for dto in [mesh, panel, calibration] {
            #expect(dto.createdAt >= beforeCreation)
            #expect(dto.createdAt <= afterCreation)
        }
    }
}
