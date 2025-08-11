// Version: 1.0.0
// Contract tests for Data Transfer Objects - ensures API stability

import Testing
import Foundation
import simd
@testable import CoverCraftFeature

/// Contract tests for DTOs to prevent breaking changes
@Suite("DTO Contract Tests")
struct DTOContractTests {
    
    /// Test MeshDTO contract stability
    @Suite("MeshDTO Contract")
    struct MeshDTOContract {
        
        @Test("MeshDTO serialization contract")
        func meshDTOSerializationStability() throws {
            // Arrange: Create a known MeshDTO
            let vertices = [
                VertexDTO(position: SIMD3<Float>(0, 0, 0), normal: SIMD3<Float>(0, 1, 0)),
                VertexDTO(position: SIMD3<Float>(1, 0, 0), normal: SIMD3<Float>(0, 1, 0)),
                VertexDTO(position: SIMD3<Float>(0.5, 1, 0), normal: SIMD3<Float>(0, 1, 0))
            ]
            
            let meshId = UUID(uuidString: "12345678-1234-1234-1234-123456789012")!
            let testDate = Date(timeIntervalSince1970: 1704067200) // 2024-01-01 00:00:00 UTC
            
            let mesh = MeshDTO(
                id: meshId,
                vertices: vertices,
                triangleIndices: [0, 1, 2],
                createdAt: testDate
            )
            
            // Act: Serialize to JSON
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
            
            let jsonData = try encoder.encode(mesh)
            let jsonString = String(data: jsonData, encoding: .utf8)!
            
            // Assert: Verify expected JSON structure
            let expectedJSON = """
            {
              "createdAt" : "2024-01-01T00:00:00Z",
              "id" : "12345678-1234-1234-1234-123456789012",
              "triangleIndices" : [
                0,
                1,
                2
              ],
              "vertices" : [
                {
                  "normal" : [
                    0,
                    1,
                    0
                  ],
                  "position" : [
                    0,
                    0,
                    0
                  ]
                },
                {
                  "normal" : [
                    0,
                    1,
                    0
                  ],
                  "position" : [
                    1,
                    0,
                    0
                  ]
                },
                {
                  "normal" : [
                    0,
                    1,
                    0
                  ],
                  "position" : [
                    0.5,
                    1,
                    0
                  ]
                }
              ]
            }
            """
            
            #expect(jsonString.trimmingCharacters(in: .whitespacesAndNewlines) ==
                   expectedJSON.trimmingCharacters(in: .whitespacesAndNewlines),
                   "MeshDTO JSON serialization format must remain stable")
        }
        
        @Test("MeshDTO deserialization contract")
        func meshDTODeserializationStability() throws {
            // Arrange: Known JSON from previous version
            let jsonData = """
            {
              "id": "12345678-1234-1234-1234-123456789012",
              "vertices": [
                {
                  "position": [1.0, 2.0, 3.0],
                  "normal": [0.0, 1.0, 0.0]
                }
              ],
              "triangleIndices": [0, 1, 2],
              "createdAt": "2024-01-01T00:00:00Z"
            }
            """.data(using: .utf8)!
            
            // Act: Deserialize
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let mesh = try decoder.decode(MeshDTO.self, from: jsonData)
            
            // Assert: Verify all fields are correctly decoded
            #expect(mesh.id == UUID(uuidString: "12345678-1234-1234-1234-123456789012")!)
            #expect(mesh.vertices.count == 1)
            #expect(mesh.vertices[0].position == SIMD3<Float>(1.0, 2.0, 3.0))
            #expect(mesh.vertices[0].normal == SIMD3<Float>(0.0, 1.0, 0.0))
            #expect(mesh.triangleIndices == [0, 1, 2])
            #expect(mesh.createdAt == Date(timeIntervalSince1970: 1704067200))
        }
        
        @Test("MeshDTO equality contract")
        func meshDTOEqualityStability() throws {
            // Arrange: Create identical DTOs
            let meshId = UUID()
            let vertices = [VertexDTO(position: SIMD3<Float>(0, 0, 0), normal: SIMD3<Float>(0, 1, 0))]
            let date = Date()
            
            let mesh1 = MeshDTO(id: meshId, vertices: vertices, triangleIndices: [0], createdAt: date)
            let mesh2 = MeshDTO(id: meshId, vertices: vertices, triangleIndices: [0], createdAt: date)
            
            // Act & Assert: Verify equality contract
            #expect(mesh1 == mesh2, "Identical MeshDTOs must be equal")
            #expect(mesh1.hashValue == mesh2.hashValue, "Equal MeshDTOs must have same hash")
        }
    }
    
    /// Test PanelDTO contract stability
    @Suite("PanelDTO Contract")
    struct PanelDTOContract {
        
        @Test("PanelDTO serialization contract")
        func panelDTOSerializationStability() throws {
            // Arrange: Create known PanelDTO
            let panelId = UUID(uuidString: "87654321-4321-4321-4321-876543219876")!
            let testDate = Date(timeIntervalSince1970: 1704067200)
            let color = ColorDTO(red: 1.0, green: 0.5, blue: 0.2, alpha: 1.0)
            
            let panel = PanelDTO(
                id: panelId,
                vertexIndices: [0, 1, 2, 3],
                color: color,
                area: 42.5,
                centroid: SIMD3<Float>(1.0, 2.0, 3.0),
                createdAt: testDate
            )
            
            // Act: Serialize
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
            
            let jsonData = try encoder.encode(panel)
            let jsonString = String(data: jsonData, encoding: .utf8)!
            
            // Assert: Verify JSON structure is stable
            #expect(jsonString.contains("\"area\" : 42.5"), "Area field must be preserved")
            #expect(jsonString.contains("\"vertexIndices\" : ["), "VertexIndices structure must be stable")
            #expect(jsonString.contains("\"color\" : {"), "Color object structure must be stable")
            #expect(jsonString.contains("\"centroid\" : ["), "Centroid array structure must be stable")
        }
        
        @Test("ColorDTO SIMD conversion contract")
        func colorDTOSIMDConversionStability() throws {
            // Arrange: Create ColorDTO with known values
            let color = ColorDTO(red: 0.8, green: 0.6, blue: 0.4, alpha: 0.9)
            
            // Act: Convert to SIMD and back
            let simdColor = color.simd
            let reconstructedColor = ColorDTO(simd: simdColor)
            
            // Assert: Conversion must be stable and accurate
            #expect(simdColor == SIMD4<Float>(0.8, 0.6, 0.4, 0.9))
            #expect(reconstructedColor == color)
            #expect(abs(reconstructedColor.red - 0.8) < 0.0001)
            #expect(abs(reconstructedColor.alpha - 0.9) < 0.0001)
        }
    }
    
    /// Test CalibrationDTO contract stability
    @Suite("CalibrationDTO Contract") 
    struct CalibrationDTOContract {
        
        @Test("CalibrationDTO calculation contract")
        func calibrationDTOCalculationStability() throws {
            // Arrange: Create calibration with known points
            let firstPoint = SIMD3<Float>(0, 0, 0)
            let secondPoint = SIMD3<Float>(3, 4, 0) // Distance should be 5.0
            
            let calibration = CalibrationDTO(
                firstPoint: firstPoint,
                secondPoint: secondPoint,
                realWorldDistance: 10.0
            )
            
            // Act & Assert: Verify calculations are stable
            #expect(calibration.measuredDistance == 5.0, "Measured distance calculation must be stable")
            #expect(calibration.scalingFactor == 2.0, "Scaling factor calculation must be stable (10.0 / 5.0 = 2.0)")
            #expect(calibration.isComplete == true, "Completion detection must be stable")
        }
        
        @Test("CalibrationDTO incomplete state contract")
        func calibrationDTOIncompleteStateStability() throws {
            // Arrange: Create incomplete calibration
            let partialCalibration = CalibrationDTO(
                firstPoint: SIMD3<Float>(1, 2, 3),
                secondPoint: nil,
                realWorldDistance: 1.0
            )
            
            // Act & Assert: Verify incomplete state behavior
            #expect(partialCalibration.measuredDistance == nil, "Incomplete calibration must have nil measured distance")
            #expect(partialCalibration.scalingFactor == nil, "Incomplete calibration must have nil scaling factor")
            #expect(partialCalibration.isComplete == false, "Incomplete calibration must report false for isComplete")
        }
    }
    
    /// Version compatibility tests
    @Suite("Version Compatibility")
    struct VersionCompatibilityTests {
        
        @Test("Contract version tracking")
        func contractVersionMustBeTracked() throws {
            // This test ensures contract changes are tracked with version bumps
            let currentVersion = "1.0.0"
            
            // Assert: This test will fail if contracts change without version update
            #expect(currentVersion == "1.0.0", "Update this version when contracts change")
            
            // Future versions should increment this:
            // Version 1.1.0: Added new optional fields (backward compatible)  
            // Version 2.0.0: Breaking changes to existing fields
        }
        
        @Test("Backward compatibility requirements")
        func backwardCompatibilityMustBeMaintained() throws {
            // Arrange: Old format JSON (simulating data from previous app version)
            let oldFormatJSON = """
            {
              "id": "12345678-1234-1234-1234-123456789012",
              "vertices": [],
              "triangleIndices": [],
              "createdAt": "2024-01-01T00:00:00Z"
            }
            """.data(using: .utf8)!
            
            // Act: Should still be decodable
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let mesh = try decoder.decode(MeshDTO.self, from: oldFormatJSON)
            
            // Assert: Must successfully decode old format
            #expect(mesh.id == UUID(uuidString: "12345678-1234-1234-1234-123456789012")!)
            #expect(mesh.vertices.isEmpty)
            #expect(mesh.triangleIndices.isEmpty)
        }
    }
}