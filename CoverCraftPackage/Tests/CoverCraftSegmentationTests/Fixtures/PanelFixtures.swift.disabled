// Version: 1.0.0  
// Test Fixtures for Segmentation Module - Panel Data

import Foundation
import CoverCraftDTO

/// Test fixtures for PanelDTO objects covering various segmentation scenarios
@available(iOS 18.0, macOS 15.0, *)
public struct PanelFixtures {
    
    // MARK: - Basic Panel Shapes
    
    /// Simple rectangular panel
    public static let rectangularPanel = PanelDTO(
        vertexIndices: Set([0, 1, 2, 3]),
        triangleIndices: [0, 1, 2, 0, 2, 3], // Two triangles forming rectangle
        color: ColorDTO.blue,
        id: UUID(uuidString: "PNL12345-1234-1234-1234-123456781234")!,
        createdAt: Date(timeIntervalSince1970: 1609459200)
    )
    
    /// Triangular panel (minimal panel)
    public static let triangularPanel = PanelDTO(
        vertexIndices: Set([0, 1, 2]),
        triangleIndices: [0, 1, 2],
        color: ColorDTO.red,
        id: UUID(uuidString: "PNL12345-1234-1234-1234-123456781235")!,
        createdAt: Date(timeIntervalSince1970: 1609459200)
    )
    
    /// Complex polygon panel
    public static let complexPolygonPanel = PanelDTO(
        vertexIndices: Set([0, 1, 2, 3, 4, 5, 6]),
        triangleIndices: [
            // Fan triangulation from vertex 0
            0, 1, 2,
            0, 2, 3,
            0, 3, 4,
            0, 4, 5,
            0, 5, 6,
            0, 6, 1
        ],
        color: ColorDTO.green,
        id: UUID(uuidString: "PNL12345-1234-1234-1234-123456781236")!,
        createdAt: Date(timeIntervalSince1970: 1609459200)
    )
    
    // MARK: - T-Shirt Panel Set
    
    /// Front torso panel
    public static let frontTorso = PanelDTO(
        vertexIndices: Set([0, 1, 2, 3, 4, 5, 6, 7]),
        triangleIndices: [
            0, 1, 2, 0, 2, 3,  // Main body
            3, 2, 5, 3, 5, 4,  // Upper chest
            4, 5, 6, 4, 6, 7   // Neck area
        ],
        color: ColorDTO(red: 0.8, green: 0.9, blue: 1.0), // Light blue
        id: UUID(uuidString: "PNL12345-1234-1234-1234-123456781237")!,
        createdAt: Date(timeIntervalSince1970: 1609459200)
    )
    
    /// Back torso panel
    public static let backTorso = PanelDTO(
        vertexIndices: Set([8, 9, 10, 11, 12, 13, 14, 15]),
        triangleIndices: [
            8, 11, 10, 8, 10, 9,   // Main back (reversed winding)
            11, 12, 13, 11, 13, 10, // Upper back
            12, 15, 14, 12, 14, 13  // Neck back
        ],
        color: ColorDTO(red: 0.7, green: 0.8, blue: 0.9), // Slightly darker blue
        id: UUID(uuidString: "PNL12345-1234-1234-1234-123456781238")!,
        createdAt: Date(timeIntervalSince1970: 1609459200)
    )
    
    /// Left sleeve panel
    public static let leftSleeve = PanelDTO(
        vertexIndices: Set([16, 17, 18, 19, 20, 21, 22, 23]),
        triangleIndices: [
            16, 17, 22, 17, 18, 19,  // Upper and lower arm
            19, 20, 21, 22, 23, 17   // Wrist and back connections
        ],
        color: ColorDTO(red: 0.9, green: 0.7, blue: 0.8), // Pink
        id: UUID(uuidString: "PNL12345-1234-1234-1234-123456781239")!,
        createdAt: Date(timeIntervalSince1970: 1609459200)
    )
    
    /// Right sleeve panel
    public static let rightSleeve = PanelDTO(
        vertexIndices: Set([24, 25, 26, 27, 28, 29, 30, 31]),
        triangleIndices: [
            24, 25, 30, 25, 26, 27,  // Upper and lower arm
            27, 28, 29, 30, 31, 25   // Wrist and back connections
        ],
        color: ColorDTO(red: 0.8, green: 0.7, blue: 0.9), // Purple
        id: UUID(uuidString: "PNL12345-1234-1234-1234-123456781240")!,
        createdAt: Date(timeIntervalSince1970: 1609459200)
    )
    
    // MARK: - Edge Cases and Error Scenarios
    
    /// Empty panel (no vertices or triangles)
    public static let emptyPanel = PanelDTO(
        vertexIndices: Set(),
        triangleIndices: [],
        color: ColorDTO.red,
        id: UUID(uuidString: "PNL12345-1234-1234-1234-123456781241")!,
        createdAt: Date(timeIntervalSince1970: 1609459200)
    )
    
    /// Panel with vertices but no triangles
    public static let orphanVerticesPanel = PanelDTO(
        vertexIndices: Set([10, 15, 20]),
        triangleIndices: [],
        color: ColorDTO.yellow,
        id: UUID(uuidString: "PNL12345-1234-1234-1234-123456781242")!,
        createdAt: Date(timeIntervalSince1970: 1609459200)
    )
    
    /// Panel with invalid triangle count (not divisible by 3)
    public static let invalidTriangleCount = PanelDTO(
        vertexIndices: Set([0, 1, 2, 3]),
        triangleIndices: [0, 1, 2, 3, 0], // 5 indices, not divisible by 3
        color: ColorDTO.orange,
        id: UUID(uuidString: "PNL12345-1234-1234-1234-123456781243")!,
        createdAt: Date(timeIntervalSince1970: 1609459200)
    )
    
    /// Panel with mismatched vertex indices (triangles reference vertices not in set)
    public static let mismatchedVertices = PanelDTO(
        vertexIndices: Set([0, 1, 2]),
        triangleIndices: [0, 1, 5], // Vertex 5 not in vertex set
        color: ColorDTO.magenta,
        id: UUID(uuidString: "PNL12345-1234-1234-1234-123456781244")!,
        createdAt: Date(timeIntervalSince1970: 1609459200)
    )
    
    /// Single vertex panel (degenerate)
    public static let singleVertexPanel = PanelDTO(
        vertexIndices: Set([42]),
        triangleIndices: [],
        color: ColorDTO.cyan,
        id: UUID(uuidString: "PNL12345-1234-1234-1234-123456781245")!,
        createdAt: Date(timeIntervalSince1970: 1609459200)
    )
    
    // MARK: - Large Scale Panels
    
    /// Large panel with many triangles (performance testing)
    public static let largePanelWithManyTriangles: PanelDTO = {
        let vertexCount = 100
        let vertexIndices = Set(0..<vertexCount)
        
        // Create a fan triangulation from vertex 0
        var triangleIndices: [Int] = []
        for i in 1..<(vertexCount-1) {
            triangleIndices.append(contentsOf: [0, i, i+1])
        }
        
        return PanelDTO(
            vertexIndices: vertexIndices,
            triangleIndices: triangleIndices,
            color: ColorDTO(red: 0.5, green: 0.5, blue: 0.5),
            id: UUID(uuidString: "PNL12345-1234-1234-1234-123456781246")!,
            createdAt: Date(timeIntervalSince1970: 1609459200)
        )
    }()
    
    // MARK: - Segmentation Algorithm Test Cases
    
    /// Panel representing connected component #1
    public static let connectedComponent1 = PanelDTO(
        vertexIndices: Set([0, 1, 2, 5, 6, 9]),
        triangleIndices: [0, 1, 2, 5, 6, 9, 0, 5, 1],
        color: ColorDTO(red: 1.0, green: 0.2, blue: 0.2),
        id: UUID(uuidString: "PNL12345-1234-1234-1234-123456781247")!,
        createdAt: Date(timeIntervalSince1970: 1609459200)
    )
    
    /// Panel representing connected component #2
    public static let connectedComponent2 = PanelDTO(
        vertexIndices: Set([3, 4, 7, 8, 10, 11]),
        triangleIndices: [3, 4, 7, 8, 10, 11, 3, 7, 4],
        color: ColorDTO(red: 0.2, green: 1.0, blue: 0.2),
        id: UUID(uuidString: "PNL12345-1234-1234-1234-123456781248")!,
        createdAt: Date(timeIntervalSince1970: 1609459200)
    )
    
    /// Panel with holes (non-simply connected)
    public static let panelWithHoles = PanelDTO(
        vertexIndices: Set([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]),
        triangleIndices: [
            // Outer boundary
            0, 1, 2, 0, 2, 3, 0, 3, 4, 0, 4, 1,
            // Inner hole (reverse winding)
            5, 8, 7, 5, 7, 6,
            // Connection between outer and inner
            9, 10, 11
        ],
        color: ColorDTO(red: 0.9, green: 0.9, blue: 0.1),
        id: UUID(uuidString: "PNL12345-1234-1234-1234-123456781249")!,
        createdAt: Date(timeIntervalSince1970: 1609459200)
    )
    
    // MARK: - Collections
    
    /// All valid panels for testing
    public static let validPanels: [PanelDTO] = [
        rectangularPanel,
        triangularPanel,
        complexPolygonPanel,
        frontTorso,
        backTorso,
        leftSleeve,
        rightSleeve,
        largePanelWithManyTriangles,
        connectedComponent1,
        connectedComponent2,
        panelWithHoles
    ]
    
    /// All invalid panels for error handling tests
    public static let invalidPanels: [PanelDTO] = [
        emptyPanel,
        orphanVerticesPanel,
        invalidTriangleCount,
        mismatchedVertices,
        singleVertexPanel
    ]
    
    /// All panels combined
    public static let allPanels: [PanelDTO] = validPanels + invalidPanels
    
    /// T-shirt panel set (realistic garment)
    public static let tshirtPanelSet: [PanelDTO] = [
        frontTorso,
        backTorso,
        leftSleeve,
        rightSleeve
    ]
    
    /// Simple geometric shapes
    public static let basicShapes: [PanelDTO] = [
        rectangularPanel,
        triangularPanel,
        complexPolygonPanel
    ]
    
    /// Edge case panels for robustness testing
    public static let edgeCasePanels: [PanelDTO] = [
        singleVertexPanel,
        panelWithHoles,
        largePanelWithManyTriangles
    ]
    
    // MARK: - Color Schemes
    
    /// Rainbow color scheme for multiple panels
    public static let rainbowColors: [ColorDTO] = [
        ColorDTO.red,
        ColorDTO(red: 1.0, green: 0.5, blue: 0.0), // Orange  
        ColorDTO.yellow,
        ColorDTO.green,
        ColorDTO.blue,
        ColorDTO(red: 0.5, green: 0.0, blue: 1.0), // Indigo
        ColorDTO(red: 0.8, green: 0.0, blue: 1.0)  // Violet
    ]
    
    /// Monochrome color scheme (grayscale)
    public static let monochromeColors: [ColorDTO] = [
        ColorDTO(red: 0.0, green: 0.0, blue: 0.0),   // Black
        ColorDTO(red: 0.25, green: 0.25, blue: 0.25), // Dark gray
        ColorDTO(red: 0.5, green: 0.5, blue: 0.5),   // Medium gray  
        ColorDTO(red: 0.75, green: 0.75, blue: 0.75), // Light gray
        ColorDTO(red: 1.0, green: 1.0, blue: 1.0)    // White
    ]
    
    /// Pastel color scheme
    public static let pastelColors: [ColorDTO] = [
        ColorDTO(red: 1.0, green: 0.8, blue: 0.8),   // Light pink
        ColorDTO(red: 0.8, green: 1.0, blue: 0.8),   // Light green
        ColorDTO(red: 0.8, green: 0.8, blue: 1.0),   // Light blue
        ColorDTO(red: 1.0, green: 1.0, blue: 0.8),   // Light yellow
        ColorDTO(red: 1.0, green: 0.8, blue: 1.0)    // Light magenta
    ]
    
    // MARK: - Factory Methods
    
    /// Create panel with specific color
    public static func panelWithColor(_ color: ColorDTO) -> PanelDTO {
        PanelDTO(
            vertexIndices: Set([0, 1, 2]),
            triangleIndices: [0, 1, 2],
            color: color
        )
    }
    
    /// Create panel with specific vertex count
    public static func panelWithVertexCount(_ count: Int) -> PanelDTO {
        let vertices = Set(0..<count)
        let triangleIndices: [Int]
        
        if count >= 3 {
            // Create fan triangulation from vertex 0
            triangleIndices = (1..<(count-1)).flatMap { i in
                [0, i, i+1]
            }
        } else {
            triangleIndices = []
        }
        
        return PanelDTO(
            vertexIndices: vertices,
            triangleIndices: triangleIndices,
            color: ColorDTO(
                red: Double.random(in: 0...1),
                green: Double.random(in: 0...1), 
                blue: Double.random(in: 0...1)
            )
        )
    }
    
    /// Create set of panels with specified colors
    public static func panelsWithColors(_ colors: [ColorDTO]) -> [PanelDTO] {
        colors.enumerated().map { index, color in
            PanelDTO(
                vertexIndices: Set([index * 3, index * 3 + 1, index * 3 + 2]),
                triangleIndices: [index * 3, index * 3 + 1, index * 3 + 2],
                color: color,
                id: UUID()
            )
        }
    }
    
    /// Get random valid panel
    public static func randomValidPanel() -> PanelDTO {
        validPanels.randomElement() ?? rectangularPanel
    }
    
    /// Get random color scheme
    public static func randomColorScheme() -> [ColorDTO] {
        [rainbowColors, monochromeColors, pastelColors].randomElement() ?? rainbowColors
    }
}