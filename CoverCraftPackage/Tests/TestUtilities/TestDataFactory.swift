// Version: 1.0.0
// CoverCraft Test Utilities - Test Data Factory
// 
// TDD-compliant synthetic data generator for comprehensive testing
// Provides deterministic, reusable test data objects following factory pattern

import Foundation
import CoreGraphics
import simd
import CoverCraftDTO
import CoverCraftCore

/// Factory for creating synthetic test data objects
/// 
/// Provides comprehensive test data generation for all CoverCraft DTOs
/// with deterministic, predictable results for reliable testing.
/// All generated data is valid by default unless specifically testing invalid cases.
@available(iOS 18.0, macOS 15.0, *)
public final class TestDataFactory {
    
    // MARK: - Static Configuration
    
    /// Base scale factor for generated data (units per meter)
    public static let defaultScaleUnitsPerMeter: Double = 1000.0
    
    /// Base size for generated 2D patterns
    public static let defaultPatternSize: CGFloat = 100.0
    
    /// Colors used for generating test panels
    public static let testColors: [ColorDTO] = [
        .red, .green, .blue, .yellow, .orange, .purple, .cyan, .magenta
    ]
    
    // MARK: - Mesh Data Generation
    
    /// Create a simple test mesh (unit cube)
    /// - Returns: Valid MeshDTO representing a unit cube
    public static func createTestMesh() -> MeshDTO {
        return createCubeMesh(size: 1.0)
    }
    
    /// Create a cube mesh with specified size
    /// - Parameter size: Size of the cube (default: 1.0)
    /// - Returns: Valid MeshDTO representing a cube
    public static func createCubeMesh(size: Float = 1.0) -> MeshDTO {
        let half = size * 0.5
        
        // 8 vertices of a cube centered at origin
        let vertices: [SIMD3<Float>] = [
            // Front face (z = +half)
            SIMD3<Float>(-half, -half,  half), // 0: bottom-left-front
            SIMD3<Float>( half, -half,  half), // 1: bottom-right-front
            SIMD3<Float>( half,  half,  half), // 2: top-right-front
            SIMD3<Float>(-half,  half,  half), // 3: top-left-front
            
            // Back face (z = -half)
            SIMD3<Float>(-half, -half, -half), // 4: bottom-left-back
            SIMD3<Float>( half, -half, -half), // 5: bottom-right-back
            SIMD3<Float>( half,  half, -half), // 6: top-right-back
            SIMD3<Float>(-half,  half, -half)  // 7: top-left-back
        ]
        
        // 12 triangles (2 per face, 6 faces)
        // Counter-clockwise winding when viewed from outside
        let triangles: [Int] = [
            // Front face (z = +half) - normal: (0, 0, 1)
            0, 1, 2,  0, 2, 3,
            
            // Back face (z = -half) - normal: (0, 0, -1)
            5, 4, 7,  5, 7, 6,
            
            // Right face (x = +half) - normal: (1, 0, 0)
            1, 5, 6,  1, 6, 2,
            
            // Left face (x = -half) - normal: (-1, 0, 0)
            4, 0, 3,  4, 3, 7,
            
            // Top face (y = +half) - normal: (0, 1, 0)
            3, 2, 6,  3, 6, 7,
            
            // Bottom face (y = -half) - normal: (0, -1, 0)
            4, 5, 1,  4, 1, 0
        ]
        
        return MeshDTO(vertices: vertices, triangleIndices: triangles)
    }
    
    /// Create a simple triangle mesh for minimal testing
    /// - Returns: Valid MeshDTO with single triangle
    public static func createTriangleMesh() -> MeshDTO {
        let vertices: [SIMD3<Float>] = [
            SIMD3<Float>(0, 1, 0),    // top
            SIMD3<Float>(-1, -1, 0),  // bottom-left
            SIMD3<Float>(1, -1, 0)    // bottom-right
        ]
        
        let triangles: [Int] = [0, 1, 2]
        
        return MeshDTO(vertices: vertices, triangleIndices: triangles)
    }
    
    /// Create a plane mesh (rectangular surface)
    /// - Parameters:
    ///   - width: Width of the plane (default: 2.0)
    ///   - height: Height of the plane (default: 2.0)
    /// - Returns: Valid MeshDTO representing a plane
    public static func createPlaneMesh(width: Float = 2.0, height: Float = 2.0) -> MeshDTO {
        let halfWidth = width * 0.5
        let halfHeight = height * 0.5
        
        let vertices: [SIMD3<Float>] = [
            SIMD3<Float>(-halfWidth, -halfHeight, 0), // bottom-left
            SIMD3<Float>( halfWidth, -halfHeight, 0), // bottom-right
            SIMD3<Float>( halfWidth,  halfHeight, 0), // top-right
            SIMD3<Float>(-halfWidth,  halfHeight, 0)  // top-left
        ]
        
        let triangles: [Int] = [
            0, 1, 2,  // first triangle
            0, 2, 3   // second triangle
        ]
        
        return MeshDTO(vertices: vertices, triangleIndices: triangles)
    }
    
    /// Create a complex mesh for stress testing
    /// - Parameter complexity: Number of subdivisions (default: 2)
    /// - Returns: Valid MeshDTO with many triangles
    public static func createComplexMesh(complexity: Int = 2) -> MeshDTO {
        // Start with a cube and subdivide it
        let baseMesh = createCubeMesh()
        
        // For simplicity, we'll create a mesh with more triangles by tesselating each face
        var vertices = baseMesh.vertices
        var triangles: [Int] = []
        
        let subdivisions = max(1, complexity)
        _ = vertices.count // Track original vertex count for subdivision
        
        // Add subdivided triangles for each original triangle
        for triangleIndex in stride(from: 0, to: baseMesh.triangleIndices.count, by: 3) {
            let v0 = baseMesh.triangleIndices[triangleIndex]
            let v1 = baseMesh.triangleIndices[triangleIndex + 1]
            let v2 = baseMesh.triangleIndices[triangleIndex + 2]
            
            let p0 = baseMesh.vertices[v0]
            let p1 = baseMesh.vertices[v1]
            let p2 = baseMesh.vertices[v2]
            
            // Create subdivided triangles
            for i in 0..<subdivisions {
                for j in 0..<(subdivisions - i) {
                    let u = Float(i) / Float(subdivisions)
                    let v = Float(j) / Float(subdivisions - i)
                    let w = 1.0 - u - v
                    
                    if w >= 0 {
                        let newVertex = u * p1 + v * p2 + w * p0
                        vertices.append(newVertex)
                        
                        // Add triangle indices (simplified tessellation)
                        if i + j < subdivisions - 1 {
                            let baseIndex = vertices.count - 1
                            triangles.append(contentsOf: [baseIndex, v0, v1])
                        }
                    }
                }
            }
        }
        
        // If we didn't generate enough triangles, fall back to original
        if triangles.isEmpty {
            triangles = baseMesh.triangleIndices
        }
        
        return MeshDTO(vertices: vertices, triangleIndices: triangles)
    }
    
    /// Create an invalid mesh for error testing
    /// - Returns: Invalid MeshDTO with inconsistent data
    public static func createInvalidMesh() -> MeshDTO {
        let vertices: [SIMD3<Float>] = [
            SIMD3<Float>(0, 0, 0)
        ]
        
        // Invalid triangle indices (out of bounds)
        let triangles: [Int] = [0, 1, 2, 3, 4, 5]
        
        return MeshDTO(vertices: vertices, triangleIndices: triangles)
    }
    
    // MARK: - Panel Data Generation
    
    /// Create test panels from a mesh
    /// - Parameters:
    ///   - count: Number of panels to create (default: 5)
    ///   - mesh: Source mesh (if nil, creates test mesh)
    /// - Returns: Array of valid PanelDTO objects
    public static func createTestPanels(count: Int = 5, from mesh: MeshDTO? = nil) -> [PanelDTO] {
        let sourceMesh = mesh ?? createTestMesh()
        guard sourceMesh.isValid, count > 0 else { return [] }
        
        var panels: [PanelDTO] = []
        let actualCount = min(count, sourceMesh.triangleCount)
        let trianglesPerPanel = max(1, sourceMesh.triangleCount / actualCount)
        
        for panelIndex in 0..<actualCount {
            let startTriangle = panelIndex * trianglesPerPanel
            let endTriangle = min(startTriangle + trianglesPerPanel, sourceMesh.triangleCount)
            
            var vertexIndices: Set<Int> = []
            var triangleIndices: [Int] = []
            
            for triangleIdx in startTriangle..<endTriangle {
                let baseIdx = triangleIdx * 3
                if baseIdx + 2 < sourceMesh.triangleIndices.count {
                    let idx1 = sourceMesh.triangleIndices[baseIdx]
                    let idx2 = sourceMesh.triangleIndices[baseIdx + 1]
                    let idx3 = sourceMesh.triangleIndices[baseIdx + 2]
                    
                    vertexIndices.insert(idx1)
                    vertexIndices.insert(idx2)
                    vertexIndices.insert(idx3)
                    
                    triangleIndices.append(contentsOf: [idx1, idx2, idx3])
                }
            }
            
            let color = testColors[panelIndex % testColors.count]
            let panel = PanelDTO(
                vertexIndices: vertexIndices,
                triangleIndices: triangleIndices,
                color: color
            )
            
            panels.append(panel)
        }
        
        return panels
    }
    
    /// Create a single test panel
    /// - Parameters:
    ///   - color: Panel color (default: red)
    ///   - triangleCount: Number of triangles (default: 2)
    /// - Returns: Valid PanelDTO
    public static func createTestPanel(color: ColorDTO = .red, triangleCount: Int = 2) -> PanelDTO {
        let actualTriangleCount = max(1, triangleCount)
        var vertexIndices: Set<Int> = []
        var triangleIndices: [Int] = []
        
        for triangleIndex in 0..<actualTriangleCount {
            let baseVertexIndex = triangleIndex * 3
            let v1 = baseVertexIndex
            let v2 = baseVertexIndex + 1  
            let v3 = baseVertexIndex + 2
            
            vertexIndices.insert(v1)
            vertexIndices.insert(v2)
            vertexIndices.insert(v3)
            
            triangleIndices.append(contentsOf: [v1, v2, v3])
        }
        
        return PanelDTO(
            vertexIndices: vertexIndices,
            triangleIndices: triangleIndices,
            color: color
        )
    }
    
    // MARK: - Flattened Panel Data Generation
    
    /// Create test flattened panels
    /// - Parameters:
    ///   - count: Number of flattened panels (default: 3)
    ///   - scaleUnitsPerMeter: Scale factor (default: 1000.0)
    /// - Returns: Array of valid FlattenedPanelDTO objects
    public static func createTestFlattenedPanels(count: Int = 3, scaleUnitsPerMeter: Double = 1000.0) -> [FlattenedPanelDTO] {
        guard count > 0 else { return [] }
        
        var flattenedPanels: [FlattenedPanelDTO] = []
        
        for index in 0..<count {
            let panel = createTestFlattenedPanel(
                index: index,
                scaleUnitsPerMeter: scaleUnitsPerMeter
            )
            flattenedPanels.append(panel)
        }
        
        return flattenedPanels
    }
    
    /// Create a single test flattened panel
    /// - Parameters:
    ///   - index: Panel index for positioning (default: 0)
    ///   - scaleUnitsPerMeter: Scale factor (default: 1000.0)
    ///   - color: Panel color (default: blue)
    /// - Returns: Valid FlattenedPanelDTO
    public static func createTestFlattenedPanel(
        index: Int = 0,
        scaleUnitsPerMeter: Double = 1000.0,
        color: ColorDTO = .blue
    ) -> FlattenedPanelDTO {
        let size = defaultPatternSize
        let offset = CGFloat(index) * (size + 20) // Spacing between panels
        
        // Create a simple rectangular panel
        let points2D = [
            CGPoint(x: offset, y: 0),
            CGPoint(x: offset + size, y: 0),
            CGPoint(x: offset + size, y: size),
            CGPoint(x: offset, y: size)
        ]
        
        let edges = [
            EdgeDTO(startIndex: 0, endIndex: 1, type: .cutLine),
            EdgeDTO(startIndex: 1, endIndex: 2, type: .cutLine),
            EdgeDTO(startIndex: 2, endIndex: 3, type: .cutLine),
            EdgeDTO(startIndex: 3, endIndex: 0, type: .cutLine)
        ]
        
        return FlattenedPanelDTO(
            points2D: points2D,
            edges: edges,
            color: color,
            scaleUnitsPerMeter: scaleUnitsPerMeter
        )
    }
    
    /// Create a complex flattened panel with multiple edge types
    /// - Parameter scaleUnitsPerMeter: Scale factor (default: 1000.0)
    /// - Returns: Valid FlattenedPanelDTO with mixed edge types
    public static func createComplexFlattenedPanel(scaleUnitsPerMeter: Double = 1000.0) -> FlattenedPanelDTO {
        // Create an L-shaped panel with different edge types
        let points2D = [
            CGPoint(x: 0, y: 0),     // 0: origin
            CGPoint(x: 100, y: 0),   // 1: right
            CGPoint(x: 100, y: 60),  // 2: right-up
            CGPoint(x: 60, y: 60),   // 3: inner corner
            CGPoint(x: 60, y: 100),  // 4: inner up
            CGPoint(x: 0, y: 100)    // 5: left-top
        ]
        
        let edges = [
            EdgeDTO(startIndex: 0, endIndex: 1, type: .cutLine),
            EdgeDTO(startIndex: 1, endIndex: 2, type: .cutLine),
            EdgeDTO(startIndex: 2, endIndex: 3, type: .foldLine),
            EdgeDTO(startIndex: 3, endIndex: 4, type: .cutLine),
            EdgeDTO(startIndex: 4, endIndex: 5, type: .cutLine),
            EdgeDTO(startIndex: 5, endIndex: 0, type: .seamAllowance)
        ]
        
        return FlattenedPanelDTO(
            points2D: points2D,
            edges: edges,
            color: .orange,
            scaleUnitsPerMeter: scaleUnitsPerMeter
        )
    }
    
    // MARK: - Calibration Data Generation
    
    /// Create a test calibration
    /// - Parameters:
    ///   - isComplete: Whether calibration should be complete (default: true)
    ///   - realWorldDistance: Real-world distance in meters (default: 1.0)
    /// - Returns: CalibrationDTO for testing
    public static func createTestCalibration(isComplete: Bool = true, realWorldDistance: Double = 1.0) -> CalibrationDTO {
        if isComplete {
            return CalibrationDTO(
                firstPoint: SIMD3<Float>(0, 0, 0),
                secondPoint: SIMD3<Float>(1, 0, 0),
                realWorldDistance: realWorldDistance,
                metadata: createTestCalibrationMetadata()
            )
        } else {
            return CalibrationDTO.empty()
        }
    }
    
    /// Create test calibration metadata
    /// - Returns: CalibrationMetadata for testing
    public static func createTestCalibrationMetadata() -> CalibrationMetadata {
        return CalibrationMetadata(
            description: "Test measurement using ruler",
            measurementTool: "ruler",
            units: "meters",
            confidence: 0.95
        )
    }
    
    // MARK: - Export Data Generation
    
    /// Create test export options
    /// - Parameters:
    ///   - format: Target format (affects options)
    ///   - paperSize: Paper size (default: .a4)
    /// - Returns: ExportOptions configured for testing
    public static func createTestExportOptions(format: ExportFormat? = nil, paperSize: PaperSize = .a4) -> ExportOptions {
        let includeSeamAllowance = format != .dxf // DXF typically doesn't include seam allowance
        
        return ExportOptions(
            includeSeamAllowance: includeSeamAllowance,
            seamAllowanceWidth: 15.0,
            includeRegistrationMarks: true,
            paperSize: paperSize,
            scale: 1.0,
            includeInstructions: format == .pdf
        )
    }
    
    /// Create test export result
    /// - Parameters:
    ///   - format: Export format (default: .pdf)
    ///   - panelCount: Number of panels exported (default: 3)
    /// - Returns: ExportResult for testing
    public static func createTestExportResult(format: ExportFormat = .pdf, panelCount: Int = 3) -> ExportResult {
        let filename = "test_export_\(panelCount)_panels.\(format.fileExtension)"
        let mockData = createMockExportData(for: format, panelCount: panelCount)
        
        let metadata = [
            "panelCount": "\(panelCount)",
            "format": format.rawValue,
            "testData": "true",
            "generatedAt": ISO8601DateFormatter().string(from: Date())
        ]
        
        return ExportResult(
            data: mockData,
            format: format,
            filename: filename,
            metadata: metadata
        )
    }
    
    /// Create mock export data for testing
    /// - Parameters:
    ///   - format: Export format
    ///   - panelCount: Number of panels
    /// - Returns: Mock Data representing exported content
    public static func createMockExportData(for format: ExportFormat, panelCount: Int) -> Data {
        let content: String
        
        switch format {
        case .pdf:
            content = """
            %PDF-1.4
            % Test PDF with \(panelCount) panels
            1 0 obj
            <<
            /Type /Catalog
            /Pages 2 0 R
            >>
            endobj
            """
        case .svg:
            content = """
            <?xml version="1.0" encoding="UTF-8"?>
            <svg xmlns="http://www.w3.org/2000/svg" width="210" height="297">
              <title>Test SVG Export - \(panelCount) panels</title>
              <!-- Test SVG content -->
            </svg>
            """
        case .png:
            // PNG file signature
            return Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
        case .gif:
            // GIF file signature  
            return Data("GIF89a".utf8)
        case .dxf:
            content = """
            0
            SECTION
            2
            HEADER
            9
            $ACADVER
            1
            AC1015
            0
            ENDSEC
            0
            SECTION
            2
            ENTITIES
            999
            Test DXF with \(panelCount) panels
            0
            ENDSEC
            0
            EOF
            """
        }
        
        return content.data(using: .utf8) ?? Data()
    }
    
    /// Create test validation result
    /// - Parameters:
    ///   - isValid: Whether validation should pass (default: true)
    ///   - errorCount: Number of errors to include (default: 0)
    ///   - warningCount: Number of warnings to include (default: 0)
    /// - Returns: ExportValidationResult for testing
    public static func createTestValidationResult(
        isValid: Bool = true,
        errorCount: Int = 0,
        warningCount: Int = 0
    ) -> ExportValidationResult {
        let errors = (0..<errorCount).map { "Test error \($0 + 1)" }
        let warnings = (0..<warningCount).map { "Test warning \($0 + 1)" }

        return ExportValidationResult(
            isValid: isValid && errors.isEmpty,
            errors: errors,
            warnings: warnings
        )
    }
    
    // MARK: - Batch Data Generation
    
    /// Create a complete test dataset for integration testing
    /// - Parameters:
    ///   - meshComplexity: Complexity level for mesh (1-5)
    ///   - panelCount: Number of panels to generate
    /// - Returns: Dictionary containing all test data types
    public static func createCompleteTestDataset(meshComplexity: Int = 2, panelCount: Int = 5) -> [String: Any] {
        let mesh = createComplexMesh(complexity: meshComplexity)
        let panels = createTestPanels(count: panelCount, from: mesh)
        let flattenedPanels = createTestFlattenedPanels(count: panelCount)
        let calibration = createTestCalibration()
        let exportOptions = createTestExportOptions()
        let exportResult = createTestExportResult(panelCount: panelCount)
        let validationResult = createTestValidationResult()
        
        return [
            "mesh": mesh,
            "panels": panels,
            "flattenedPanels": flattenedPanels,
            "calibration": calibration,
            "exportOptions": exportOptions,
            "exportResult": exportResult,
            "validationResult": validationResult
        ]
    }
}

// MARK: - Edge Case Data Generation

@available(iOS 18.0, macOS 15.0, *)
public extension TestDataFactory {

    /// Create data for edge case testing
    struct EdgeCases {

        /// Create empty mesh for boundary testing
        public static func emptyMesh() -> MeshDTO {
            return MeshDTO(vertices: [], triangleIndices: [])
        }

        /// Create minimal valid mesh
        public static func minimalMesh() -> MeshDTO {
            return TestDataFactory.createTriangleMesh()
        }

        /// Create mesh with maximum reasonable size
        public static func largeMesh() -> MeshDTO {
            return TestDataFactory.createComplexMesh(complexity: 5)
        }

        /// Create panel with no triangles
        public static func emptyPanel() -> PanelDTO {
            return PanelDTO(
                vertexIndices: [],
                triangleIndices: [],
                color: .red
            )
        }

        /// Create flattened panel with minimal area
        public static func tinyFlattenedPanel() -> FlattenedPanelDTO {
            let points = [
                CGPoint(x: 0, y: 0),
                CGPoint(x: 0.1, y: 0),
                CGPoint(x: 0, y: 0.1)
            ]
            
            let edges = [
                EdgeDTO(startIndex: 0, endIndex: 1, type: .cutLine),
                EdgeDTO(startIndex: 1, endIndex: 2, type: .cutLine),
                EdgeDTO(startIndex: 2, endIndex: 0, type: .cutLine)
            ]
            
            return FlattenedPanelDTO(
                points2D: points,
                edges: edges,
                color: .red,
                scaleUnitsPerMeter: 1000.0
            )
        }

        /// Create incomplete calibration
        public static func incompleteCalibration() -> CalibrationDTO {
            return CalibrationDTO(
                firstPoint: SIMD3<Float>(0, 0, 0),
                secondPoint: nil,
                realWorldDistance: 1.0
            )
        }
    }
}