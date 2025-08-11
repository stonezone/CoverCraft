// Version: 1.0.0
// Test Fixtures for Flattening Module - Flattened Panel Data

import Foundation
import CoreGraphics
import CoverCraftDTO

/// Test fixtures for FlattenedPanelDTO objects covering various flattening scenarios
@available(iOS 18.0, *)
public struct FlattenedPanelFixtures {
    
    // MARK: - Basic Flattened Shapes
    
    /// Simple rectangular flattened panel (10cm x 15cm)
    public static let rectangularFlattened = FlattenedPanelDTO(
        points2D: [
            CGPoint(x: 0.0, y: 0.0),      // Bottom-left
            CGPoint(x: 100.0, y: 0.0),    // Bottom-right (10cm at 10 units/cm)
            CGPoint(x: 100.0, y: 150.0),  // Top-right (15cm at 10 units/cm)
            CGPoint(x: 0.0, y: 150.0)     // Top-left
        ],
        edges: [
            EdgeDTO(startIndex: 0, endIndex: 1, type: .cutLine),
            EdgeDTO(startIndex: 1, endIndex: 2, type: .cutLine),
            EdgeDTO(startIndex: 2, endIndex: 3, type: .cutLine),
            EdgeDTO(startIndex: 3, endIndex: 0, type: .cutLine)
        ],
        color: ColorDTO.blue,
        scaleUnitsPerMeter: 1000.0, // 1000 units per meter (mm scale)
        id: UUID(uuidString: "FLT12345-1234-1234-1234-123456781234")!,
        originalPanelId: UUID(uuidString: "PNL12345-1234-1234-1234-123456781234")!,
        createdAt: Date(timeIntervalSince1970: 1609459200)
    )
    
    /// Triangular flattened panel
    public static let triangularFlattened = FlattenedPanelDTO(
        points2D: [
            CGPoint(x: 0.0, y: 0.0),      // Base left
            CGPoint(x: 60.0, y: 0.0),     // Base right (6cm)
            CGPoint(x: 30.0, y: 52.0)     // Apex (equilateral triangle)
        ],
        edges: [
            EdgeDTO(startIndex: 0, endIndex: 1, type: .cutLine),
            EdgeDTO(startIndex: 1, endIndex: 2, type: .cutLine),
            EdgeDTO(startIndex: 2, endIndex: 0, type: .cutLine)
        ],
        color: ColorDTO.red,
        scaleUnitsPerMeter: 1000.0,
        id: UUID(uuidString: "FLT12345-1234-1234-1234-123456781235")!,
        originalPanelId: UUID(uuidString: "PNL12345-1234-1234-1234-123456781235")!,
        createdAt: Date(timeIntervalSince1970: 1609459200)
    )
    
    /// Complex polygon (hexagon)
    public static let hexagonFlattened = FlattenedPanelDTO(
        points2D: [
            CGPoint(x: 50.0, y: 0.0),     // Bottom right
            CGPoint(x: 100.0, y: 25.0),   // Right
            CGPoint(x: 100.0, y: 75.0),   // Top right  
            CGPoint(x: 50.0, y: 100.0),   // Top left
            CGPoint(x: 0.0, y: 75.0),     // Left
            CGPoint(x: 0.0, y: 25.0)      // Bottom left
        ],
        edges: [
            EdgeDTO(startIndex: 0, endIndex: 1, type: .cutLine),
            EdgeDTO(startIndex: 1, endIndex: 2, type: .cutLine),
            EdgeDTO(startIndex: 2, endIndex: 3, type: .cutLine),
            EdgeDTO(startIndex: 3, endIndex: 4, type: .cutLine),
            EdgeDTO(startIndex: 4, endIndex: 5, type: .cutLine),
            EdgeDTO(startIndex: 5, endIndex: 0, type: .cutLine)
        ],
        color: ColorDTO.green,
        scaleUnitsPerMeter: 1000.0,
        id: UUID(uuidString: "FLT12345-1234-1234-1234-123456781236")!,
        originalPanelId: UUID(uuidString: "PNL12345-1234-1234-1234-123456781236")!,
        createdAt: Date(timeIntervalSince1970: 1609459200)
    )
    
    // MARK: - T-Shirt Flattened Panels
    
    /// Front torso panel flattened
    public static let frontTorsoFlattened = FlattenedPanelDTO(
        points2D: [
            // Main body outline
            CGPoint(x: 100.0, y: 0.0),     // Bottom left
            CGPoint(x: 300.0, y: 0.0),     // Bottom right
            CGPoint(x: 300.0, y: 400.0),   // Chest right
            CGPoint(x: 280.0, y: 450.0),   // Shoulder right
            CGPoint(x: 250.0, y: 480.0),   // Neck right
            CGPoint(x: 150.0, y: 480.0),   // Neck left
            CGPoint(x: 120.0, y: 450.0),   // Shoulder left
            CGPoint(x: 100.0, y: 400.0)    // Chest left
        ],
        edges: [
            EdgeDTO(startIndex: 0, endIndex: 1, type: .cutLine),    // Bottom hem
            EdgeDTO(startIndex: 1, endIndex: 2, type: .seamAllowance), // Side seam
            EdgeDTO(startIndex: 2, endIndex: 3, type: .cutLine),    // Chest to shoulder
            EdgeDTO(startIndex: 3, endIndex: 4, type: .cutLine),    // Shoulder to neck
            EdgeDTO(startIndex: 4, endIndex: 5, type: .cutLine),    // Neck opening
            EdgeDTO(startIndex: 5, endIndex: 6, type: .cutLine),    // Neck to shoulder
            EdgeDTO(startIndex: 6, endIndex: 7, type: .cutLine),    // Shoulder to chest
            EdgeDTO(startIndex: 7, endIndex: 0, type: .seamAllowance) // Side seam
        ],
        color: ColorDTO(red: 0.8, green: 0.9, blue: 1.0),
        scaleUnitsPerMeter: 1000.0,
        id: UUID(uuidString: "FLT12345-1234-1234-1234-123456781237")!,
        originalPanelId: UUID(uuidString: "PNL12345-1234-1234-1234-123456781237")!,
        createdAt: Date(timeIntervalSince1970: 1609459200)
    )
    
    /// Back torso panel flattened
    public static let backTorsoFlattened = FlattenedPanelDTO(
        points2D: [
            CGPoint(x: 100.0, y: 0.0),     // Bottom left
            CGPoint(x: 300.0, y: 0.0),     // Bottom right
            CGPoint(x: 300.0, y: 400.0),   // Back right
            CGPoint(x: 280.0, y: 450.0),   // Shoulder right
            CGPoint(x: 240.0, y: 470.0),   // Neck right (higher back neckline)
            CGPoint(x: 160.0, y: 470.0),   // Neck left
            CGPoint(x: 120.0, y: 450.0),   // Shoulder left
            CGPoint(x: 100.0, y: 400.0)    // Back left
        ],
        edges: [
            EdgeDTO(startIndex: 0, endIndex: 1, type: .cutLine),
            EdgeDTO(startIndex: 1, endIndex: 2, type: .seamAllowance),
            EdgeDTO(startIndex: 2, endIndex: 3, type: .cutLine),
            EdgeDTO(startIndex: 3, endIndex: 4, type: .cutLine),
            EdgeDTO(startIndex: 4, endIndex: 5, type: .cutLine),
            EdgeDTO(startIndex: 5, endIndex: 6, type: .cutLine),
            EdgeDTO(startIndex: 6, endIndex: 7, type: .cutLine),
            EdgeDTO(startIndex: 7, endIndex: 0, type: .seamAllowance)
        ],
        color: ColorDTO(red: 0.7, green: 0.8, blue: 0.9),
        scaleUnitsPerMeter: 1000.0,
        id: UUID(uuidString: "FLT12345-1234-1234-1234-123456781238")!,
        originalPanelId: UUID(uuidString: "PNL12345-1234-1234-1234-123456781238")!,
        createdAt: Date(timeIntervalSince1970: 1609459200)
    )
    
    /// Left sleeve flattened
    public static let leftSleeveFlattened = FlattenedPanelDTO(
        points2D: [
            CGPoint(x: 0.0, y: 100.0),     // Shoulder attachment
            CGPoint(x: 150.0, y: 120.0),   // Upper arm outer
            CGPoint(x: 180.0, y: 200.0),   // Elbow outer
            CGPoint(x: 200.0, y: 300.0),   // Wrist outer
            CGPoint(x: 180.0, y: 320.0),   // Wrist inner
            CGPoint(x: 160.0, y: 220.0),   // Elbow inner
            CGPoint(x: 130.0, y: 140.0),   // Upper arm inner
            CGPoint(x: 20.0, y: 120.0)     // Shoulder attachment inner
        ],
        edges: [
            EdgeDTO(startIndex: 0, endIndex: 1, type: .seamAllowance), // Shoulder attachment
            EdgeDTO(startIndex: 1, endIndex: 2, type: .cutLine),       // Upper arm seam
            EdgeDTO(startIndex: 2, endIndex: 3, type: .cutLine),       // Lower arm seam
            EdgeDTO(startIndex: 3, endIndex: 4, type: .cutLine),       // Wrist hem
            EdgeDTO(startIndex: 4, endIndex: 5, type: .cutLine),       // Lower arm seam
            EdgeDTO(startIndex: 5, endIndex: 6, type: .cutLine),       // Upper arm seam
            EdgeDTO(startIndex: 6, endIndex: 7, type: .seamAllowance), // Shoulder attachment
            EdgeDTO(startIndex: 7, endIndex: 0, type: .seamAllowance)  // Shoulder attachment
        ],
        color: ColorDTO(red: 0.9, green: 0.7, blue: 0.8),
        scaleUnitsPerMeter: 1000.0,
        id: UUID(uuidString: "FLT12345-1234-1234-1234-123456781239")!,
        originalPanelId: UUID(uuidString: "PNL12345-1234-1234-1234-123456781239")!,
        createdAt: Date(timeIntervalSince1970: 1609459200)
    )
    
    /// Right sleeve flattened (mirrored)
    public static let rightSleeveFlattened = FlattenedPanelDTO(
        points2D: [
            CGPoint(x: 200.0, y: 100.0),   // Shoulder attachment (mirrored X)
            CGPoint(x: 50.0, y: 120.0),    // Upper arm outer (mirrored X)
            CGPoint(x: 20.0, y: 200.0),    // Elbow outer (mirrored X)
            CGPoint(x: 0.0, y: 300.0),     // Wrist outer (mirrored X)
            CGPoint(x: 20.0, y: 320.0),    // Wrist inner (mirrored X)
            CGPoint(x: 40.0, y: 220.0),    // Elbow inner (mirrored X)
            CGPoint(x: 70.0, y: 140.0),    // Upper arm inner (mirrored X)
            CGPoint(x: 180.0, y: 120.0)    // Shoulder attachment inner (mirrored X)
        ],
        edges: [
            EdgeDTO(startIndex: 0, endIndex: 1, type: .seamAllowance),
            EdgeDTO(startIndex: 1, endIndex: 2, type: .cutLine),
            EdgeDTO(startIndex: 2, endIndex: 3, type: .cutLine),
            EdgeDTO(startIndex: 3, endIndex: 4, type: .cutLine),
            EdgeDTO(startIndex: 4, endIndex: 5, type: .cutLine),
            EdgeDTO(startIndex: 5, endIndex: 6, type: .cutLine),
            EdgeDTO(startIndex: 6, endIndex: 7, type: .seamAllowance),
            EdgeDTO(startIndex: 7, endIndex: 0, type: .seamAllowance)
        ],
        color: ColorDTO(red: 0.8, green: 0.7, blue: 0.9),
        scaleUnitsPerMeter: 1000.0,
        id: UUID(uuidString: "FLT12345-1234-1234-1234-123456781240")!,
        originalPanelId: UUID(uuidString: "PNL12345-1234-1234-1234-123456781240")!,
        createdAt: Date(timeIntervalSince1970: 1609459200)
    )
    
    // MARK: - Edge Cases and Error Scenarios
    
    /// Empty flattened panel (no points or edges)
    public static let emptyFlattened = FlattenedPanelDTO(
        points2D: [],
        edges: [],
        color: ColorDTO.red,
        scaleUnitsPerMeter: 1000.0,
        id: UUID(uuidString: "FLT12345-1234-1234-1234-123456781241")!,
        createdAt: Date(timeIntervalSince1970: 1609459200)
    )
    
    /// Single point (degenerate)
    public static let singlePointFlattened = FlattenedPanelDTO(
        points2D: [CGPoint(x: 50.0, y: 50.0)],
        edges: [],
        color: ColorDTO.yellow,
        scaleUnitsPerMeter: 1000.0,
        id: UUID(uuidString: "FLT12345-1234-1234-1234-123456781242")!,
        createdAt: Date(timeIntervalSince1970: 1609459200)
    )
    
    /// Two points only (line segment)
    public static let lineSegmentFlattened = FlattenedPanelDTO(
        points2D: [
            CGPoint(x: 0.0, y: 0.0),
            CGPoint(x: 100.0, y: 0.0)
        ],
        edges: [
            EdgeDTO(startIndex: 0, endIndex: 1, type: .cutLine)
        ],
        color: ColorDTO.orange,
        scaleUnitsPerMeter: 1000.0,
        id: UUID(uuidString: "FLT12345-1234-1234-1234-123456781243")!,
        createdAt: Date(timeIntervalSince1970: 1609459200)
    )
    
    /// Invalid edge indices (out of bounds)
    public static let invalidEdgeIndices = FlattenedPanelDTO(
        points2D: [
            CGPoint(x: 0.0, y: 0.0),
            CGPoint(x: 50.0, y: 0.0),
            CGPoint(x: 25.0, y: 50.0)
        ],
        edges: [
            EdgeDTO(startIndex: 0, endIndex: 5, type: .cutLine) // Index 5 out of bounds
        ],
        color: ColorDTO.magenta,
        scaleUnitsPerMeter: 1000.0,
        id: UUID(uuidString: "FLT12345-1234-1234-1234-123456781244")!,
        createdAt: Date(timeIntervalSince1970: 1609459200)
    )
    
    /// Zero scale factor (invalid)
    public static let zeroScaleFlattened = FlattenedPanelDTO(
        points2D: [
            CGPoint(x: 0.0, y: 0.0),
            CGPoint(x: 50.0, y: 0.0),
            CGPoint(x: 25.0, y: 50.0)
        ],
        edges: [
            EdgeDTO(startIndex: 0, endIndex: 1, type: .cutLine),
            EdgeDTO(startIndex: 1, endIndex: 2, type: .cutLine),
            EdgeDTO(startIndex: 2, endIndex: 0, type: .cutLine)
        ],
        color: ColorDTO.cyan,
        scaleUnitsPerMeter: 0.0, // Invalid zero scale
        id: UUID(uuidString: "FLT12345-1234-1234-1234-123456781245")!,
        createdAt: Date(timeIntervalSince1970: 1609459200)
    )
    
    /// Negative scale factor (invalid)
    public static let negativeScaleFlattened = FlattenedPanelDTO(
        points2D: [
            CGPoint(x: 0.0, y: 0.0),
            CGPoint(x: 50.0, y: 0.0),
            CGPoint(x: 25.0, y: 50.0)
        ],
        edges: [
            EdgeDTO(startIndex: 0, endIndex: 1, type: .cutLine),
            EdgeDTO(startIndex: 1, endIndex: 2, type: .cutLine),
            EdgeDTO(startIndex: 2, endIndex: 0, type: .cutLine)
        ],
        color: ColorDTO.purple,
        scaleUnitsPerMeter: -1000.0, // Invalid negative scale
        id: UUID(uuidString: "FLT12345-1234-1234-1234-123456781246")!,
        createdAt: Date(timeIntervalSince1970: 1609459200)
    )
    
    // MARK: - Different Scale Test Cases
    
    /// Millimeter scale (1000 units per meter)
    public static let millimeterScale = FlattenedPanelDTO(
        points2D: [
            CGPoint(x: 0.0, y: 0.0),
            CGPoint(x: 100.0, y: 0.0),    // 10cm
            CGPoint(x: 100.0, y: 150.0),  // 15cm
            CGPoint(x: 0.0, y: 150.0)
        ],
        edges: [
            EdgeDTO(startIndex: 0, endIndex: 1, type: .cutLine),
            EdgeDTO(startIndex: 1, endIndex: 2, type: .cutLine),
            EdgeDTO(startIndex: 2, endIndex: 3, type: .cutLine),
            EdgeDTO(startIndex: 3, endIndex: 0, type: .cutLine)
        ],
        color: ColorDTO.blue,
        scaleUnitsPerMeter: 1000.0, // mm scale
        id: UUID(uuidString: "FLT12345-1234-1234-1234-123456781247")!,
        createdAt: Date(timeIntervalSince1970: 1609459200)
    )
    
    /// Centimeter scale (100 units per meter)
    public static let centimeterScale = FlattenedPanelDTO(
        points2D: [
            CGPoint(x: 0.0, y: 0.0),
            CGPoint(x: 10.0, y: 0.0),     // 10cm
            CGPoint(x: 10.0, y: 15.0),    // 15cm
            CGPoint(x: 0.0, y: 15.0)
        ],
        edges: [
            EdgeDTO(startIndex: 0, endIndex: 1, type: .cutLine),
            EdgeDTO(startIndex: 1, endIndex: 2, type: .cutLine),
            EdgeDTO(startIndex: 2, endIndex: 3, type: .cutLine),
            EdgeDTO(startIndex: 3, endIndex: 0, type: .cutLine)
        ],
        color: ColorDTO.green,
        scaleUnitsPerMeter: 100.0, // cm scale
        id: UUID(uuidString: "FLT12345-1234-1234-1234-123456781248")!,
        createdAt: Date(timeIntervalSince1970: 1609459200)
    )
    
    /// Inch scale (39.37 units per meter)
    public static let inchScale = FlattenedPanelDTO(
        points2D: [
            CGPoint(x: 0.0, y: 0.0),
            CGPoint(x: 3.937, y: 0.0),    // ~10cm in inches
            CGPoint(x: 3.937, y: 5.906),  // ~15cm in inches
            CGPoint(x: 0.0, y: 5.906)
        ],
        edges: [
            EdgeDTO(startIndex: 0, endIndex: 1, type: .cutLine),
            EdgeDTO(startIndex: 1, endIndex: 2, type: .cutLine),
            EdgeDTO(startIndex: 2, endIndex: 3, type: .cutLine),
            EdgeDTO(startIndex: 3, endIndex: 0, type: .cutLine)
        ],
        color: ColorDTO.red,
        scaleUnitsPerMeter: 39.37, // inch scale
        id: UUID(uuidString: "FLT12345-1234-1234-1234-123456781249")!,
        createdAt: Date(timeIntervalSince1970: 1609459200)
    )
    
    // MARK: - Edge Type Test Cases
    
    /// Panel with all edge types
    public static let allEdgeTypesPanel = FlattenedPanelDTO(
        points2D: [
            CGPoint(x: 0.0, y: 0.0),      // Corner 1
            CGPoint(x: 100.0, y: 0.0),    // Corner 2
            CGPoint(x: 100.0, y: 100.0),  // Corner 3
            CGPoint(x: 50.0, y: 120.0),   // Fold line point
            CGPoint(x: 0.0, y: 100.0),    // Corner 4
            CGPoint(x: 25.0, y: 50.0),    // Registration mark
            CGPoint(x: 75.0, y: 50.0)     // Registration mark
        ],
        edges: [
            EdgeDTO(startIndex: 0, endIndex: 1, type: .cutLine),
            EdgeDTO(startIndex: 1, endIndex: 2, type: .seamAllowance),
            EdgeDTO(startIndex: 2, endIndex: 3, type: .foldLine),
            EdgeDTO(startIndex: 3, endIndex: 4, type: .foldLine),
            EdgeDTO(startIndex: 4, endIndex: 0, type: .cutLine),
            EdgeDTO(startIndex: 5, endIndex: 6, type: .registrationMark)
        ],
        color: ColorDTO(red: 0.8, green: 0.8, blue: 0.8),
        scaleUnitsPerMeter: 1000.0,
        id: UUID(uuidString: "FLT12345-1234-1234-1234-123456781250")!,
        createdAt: Date(timeIntervalSince1970: 1609459200)
    )
    
    // MARK: - Large Scale Test Cases
    
    /// Large panel for performance testing
    public static let largeFlattened: FlattenedPanelDTO = {
        let numPoints = 100
        var points: [CGPoint] = []
        var edges: [EdgeDTO] = []
        
        // Create circular pattern
        for i in 0..<numPoints {
            let angle = Double(i) * 2.0 * Double.pi / Double(numPoints)
            let radius = 200.0
            let x = radius * cos(angle) + 250.0 // Offset to positive quadrant
            let y = radius * sin(angle) + 250.0
            points.append(CGPoint(x: x, y: y))
            
            // Connect to next point (last connects to first)
            let nextIndex = (i + 1) % numPoints
            edges.append(EdgeDTO(startIndex: i, endIndex: nextIndex, type: .cutLine))
        }
        
        return FlattenedPanelDTO(
            points2D: points,
            edges: edges,
            color: ColorDTO(red: 0.5, green: 0.5, blue: 0.5),
            scaleUnitsPerMeter: 1000.0,
            id: UUID(uuidString: "FLT12345-1234-1234-1234-123456781251")!,
            createdAt: Date(timeIntervalSince1970: 1609459200)
        )
    }()
    
    // MARK: - Collections
    
    /// All valid flattened panels
    public static let validFlattenedPanels: [FlattenedPanelDTO] = [
        rectangularFlattened,
        triangularFlattened,
        hexagonFlattened,
        frontTorsoFlattened,
        backTorsoFlattened,
        leftSleeveFlattened,
        rightSleeveFlattened,
        millimeterScale,
        centimeterScale,
        inchScale,
        allEdgeTypesPanel,
        largeFlattened
    ]
    
    /// All invalid flattened panels
    public static let invalidFlattenedPanels: [FlattenedPanelDTO] = [
        emptyFlattened,
        singlePointFlattened,
        invalidEdgeIndices,
        zeroScaleFlattened,
        negativeScaleFlattened
    ]
    
    /// Edge case panels
    public static let edgeCaseFlattenedPanels: [FlattenedPanelDTO] = [
        lineSegmentFlattened,
        largeFlattened
    ]
    
    /// All flattened panels combined
    public static let allFlattenedPanels: [FlattenedPanelDTO] = 
        validFlattenedPanels + invalidFlattenedPanels + edgeCaseFlattenedPanels
    
    /// T-shirt flattened panel set
    public static let tshirtFlattenedSet: [FlattenedPanelDTO] = [
        frontTorsoFlattened,
        backTorsoFlattened,
        leftSleeveFlattened,
        rightSleeveFlattened
    ]
    
    /// Basic geometric shapes flattened
    public static let basicFlattenedShapes: [FlattenedPanelDTO] = [
        rectangularFlattened,
        triangularFlattened,
        hexagonFlattened
    ]
    
    /// Different scale examples
    public static let scaleExamples: [FlattenedPanelDTO] = [
        millimeterScale,
        centimeterScale,
        inchScale
    ]
    
    // MARK: - Factory Methods
    
    /// Create square flattened panel with specified size
    public static func squareFlattened(size: Double, scale: Double = 1000.0) -> FlattenedPanelDTO {
        FlattenedPanelDTO(
            points2D: [
                CGPoint(x: 0.0, y: 0.0),
                CGPoint(x: size, y: 0.0),
                CGPoint(x: size, y: size),
                CGPoint(x: 0.0, y: size)
            ],
            edges: [
                EdgeDTO(startIndex: 0, endIndex: 1, type: .cutLine),
                EdgeDTO(startIndex: 1, endIndex: 2, type: .cutLine),
                EdgeDTO(startIndex: 2, endIndex: 3, type: .cutLine),
                EdgeDTO(startIndex: 3, endIndex: 0, type: .cutLine)
            ],
            color: ColorDTO(
                red: Double.random(in: 0...1),
                green: Double.random(in: 0...1),
                blue: Double.random(in: 0...1)
            ),
            scaleUnitsPerMeter: scale
        )
    }
    
    /// Create regular polygon flattened panel
    public static func regularPolygonFlattened(
        sides: Int,
        radius: Double,
        scale: Double = 1000.0
    ) -> FlattenedPanelDTO {
        var points: [CGPoint] = []
        var edges: [EdgeDTO] = []
        
        for i in 0..<sides {
            let angle = Double(i) * 2.0 * Double.pi / Double(sides)
            let x = radius * cos(angle) + radius // Offset to positive quadrant
            let y = radius * sin(angle) + radius
            points.append(CGPoint(x: x, y: y))
            
            let nextIndex = (i + 1) % sides
            edges.append(EdgeDTO(startIndex: i, endIndex: nextIndex, type: .cutLine))
        }
        
        return FlattenedPanelDTO(
            points2D: points,
            edges: edges,
            color: ColorDTO(
                red: Double.random(in: 0...1),
                green: Double.random(in: 0...1),
                blue: Double.random(in: 0...1)
            ),
            scaleUnitsPerMeter: scale
        )
    }
    
    /// Get random valid flattened panel
    public static func randomValidFlattenedPanel() -> FlattenedPanelDTO {
        validFlattenedPanels.randomElement() ?? rectangularFlattened
    }
    
    /// Create flattened panel with specific edge type
    public static func flattenedPanelWithEdgeType(_ edgeType: EdgeType) -> FlattenedPanelDTO {
        FlattenedPanelDTO(
            points2D: [
                CGPoint(x: 0.0, y: 0.0),
                CGPoint(x: 50.0, y: 0.0),
                CGPoint(x: 25.0, y: 50.0)
            ],
            edges: [
                EdgeDTO(startIndex: 0, endIndex: 1, type: edgeType),
                EdgeDTO(startIndex: 1, endIndex: 2, type: edgeType),
                EdgeDTO(startIndex: 2, endIndex: 0, type: edgeType)
            ],
            color: ColorDTO.blue,
            scaleUnitsPerMeter: 1000.0
        )
    }
}