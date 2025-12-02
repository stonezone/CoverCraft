// Version: 1.0.0
// Test Fixtures for AR Module - Calibration Data

import Foundation
import simd
import CoverCraftDTO

/// Test fixtures for CalibrationDTO objects covering various calibration scenarios
@available(iOS 18.0, macOS 15.0, *)
public struct CalibrationFixtures {
    
    // MARK: - Complete Calibrations
    
    /// Standard 30cm ruler calibration
    public static let ruler30cm = CalibrationDTO(
        firstPoint: SIMD3<Float>(0.0, 0.0, 0.0),
        secondPoint: SIMD3<Float>(0.3, 0.0, 0.0), // 30cm in mesh units
        realWorldDistance: 0.30, // 30cm = 0.30m
        id: UUID(uuidString: "CAL12345-1234-1234-1234-123456781234")!,
        metadata: CalibrationMetadata(
            description: "30cm ruler measurement",
            measurementTool: "ruler",
            units: "meters",
            confidence: 0.95
        ),
        createdAt: Date(timeIntervalSince1970: 1609459200)
    )
    
    /// Tape measure 1 meter calibration
    public static let tapeMeasure1m = CalibrationDTO(
        firstPoint: SIMD3<Float>(-0.5, 0.2, 0.1),
        secondPoint: SIMD3<Float>(0.5, 0.2, 0.1),
        realWorldDistance: 1.0, // 1 meter
        id: UUID(uuidString: "CAL12345-1234-1234-1234-123456781235")!,
        metadata: CalibrationMetadata(
            description: "1 meter tape measure",
            measurementTool: "tape_measure", 
            units: "meters",
            confidence: 0.98
        ),
        createdAt: Date(timeIntervalSince1970: 1609459200)
    )
    
    /// Credit card calibration (8.56cm x 5.398cm)
    public static let creditCard = CalibrationDTO(
        firstPoint: SIMD3<Float>(0.0, 0.0, 0.5),
        secondPoint: SIMD3<Float>(0.0856, 0.0, 0.5), // Credit card width
        realWorldDistance: 0.0856, // 85.6mm = 0.0856m
        id: UUID(uuidString: "CAL12345-1234-1234-1234-123456781236")!,
        metadata: CalibrationMetadata(
            description: "Credit card width calibration",
            measurementTool: "credit_card",
            units: "meters",
            confidence: 0.90
        ),
        createdAt: Date(timeIntervalSince1970: 1609459200)
    )
    
    /// Diagonal measurement for complex shapes
    public static let diagonalMeasure = CalibrationDTO(
        firstPoint: SIMD3<Float>(-0.3, -0.4, -0.2),
        secondPoint: SIMD3<Float>(0.3, 0.4, 0.2),
        realWorldDistance: 0.894, // sqrt(0.6² + 0.8² + 0.4²) ≈ 0.894m
        id: UUID(uuidString: "CAL12345-1234-1234-1234-123456781237")!,
        metadata: CalibrationMetadata(
            description: "3D diagonal measurement",
            measurementTool: "laser_measure",
            units: "meters",
            confidence: 0.92
        ),
        createdAt: Date(timeIntervalSince1970: 1609459200)
    )
    
    // MARK: - Partial/Incomplete Calibrations
    
    /// Empty calibration (no points set)
    public static let emptyCalibration = CalibrationDTO(
        firstPoint: nil,
        secondPoint: nil,
        realWorldDistance: 1.0,
        id: UUID(uuidString: "CAL12345-1234-1234-1234-123456781238")!,
        createdAt: Date(timeIntervalSince1970: 1609459200)
    )
    
    /// First point only
    public static let firstPointOnly = CalibrationDTO(
        firstPoint: SIMD3<Float>(0.1, 0.2, 0.3),
        secondPoint: nil,
        realWorldDistance: 0.5,
        id: UUID(uuidString: "CAL12345-1234-1234-1234-123456781239")!,
        metadata: CalibrationMetadata(
            description: "Partial calibration - first point set",
            confidence: 0.5
        ),
        createdAt: Date(timeIntervalSince1970: 1609459200)
    )
    
    /// Second point only (unusual state)
    public static let secondPointOnly = CalibrationDTO(
        firstPoint: nil,
        secondPoint: SIMD3<Float>(0.4, 0.5, 0.6),
        realWorldDistance: 0.75,
        id: UUID(uuidString: "CAL12345-1234-1234-1234-123456781240")!,
        metadata: CalibrationMetadata(
            description: "Partial calibration - second point set",
            confidence: 0.3
        ),
        createdAt: Date(timeIntervalSince1970: 1609459200)
    )
    
    // MARK: - Edge Cases and Error Scenarios
    
    /// Zero distance calibration (invalid)
    public static let zeroDistance = CalibrationDTO(
        firstPoint: SIMD3<Float>(1.0, 1.0, 1.0),
        secondPoint: SIMD3<Float>(1.0, 1.0, 1.0), // Same point
        realWorldDistance: 0.0,
        id: UUID(uuidString: "CAL12345-1234-1234-1234-123456781241")!,
        createdAt: Date(timeIntervalSince1970: 1609459200)
    )
    
    /// Negative distance (invalid)
    public static let negativeDistance = CalibrationDTO(
        firstPoint: SIMD3<Float>(0.0, 0.0, 0.0),
        secondPoint: SIMD3<Float>(0.5, 0.0, 0.0),
        realWorldDistance: -0.5,
        id: UUID(uuidString: "CAL12345-1234-1234-1234-123456781242")!,
        createdAt: Date(timeIntervalSince1970: 1609459200)
    )
    
    /// Very small distance (precision edge case)
    public static let tinyDistance = CalibrationDTO(
        firstPoint: SIMD3<Float>(0.0, 0.0, 0.0),
        secondPoint: SIMD3<Float>(0.0001, 0.0, 0.0), // 0.1mm mesh distance
        realWorldDistance: 0.0001, // 0.1mm real distance
        id: UUID(uuidString: "CAL12345-1234-1234-1234-123456781243")!,
        metadata: CalibrationMetadata(
            description: "Microscopic calibration test",
            measurementTool: "micrometer",
            confidence: 0.60
        ),
        createdAt: Date(timeIntervalSince1970: 1609459200)
    )
    
    /// Very large distance
    public static let hugeDistance = CalibrationDTO(
        firstPoint: SIMD3<Float>(-50.0, 0.0, 0.0),
        secondPoint: SIMD3<Float>(50.0, 0.0, 0.0),
        realWorldDistance: 100.0, // 100 meters
        id: UUID(uuidString: "CAL12345-1234-1234-1234-123456781244")!,
        metadata: CalibrationMetadata(
            description: "Large scale room measurement",
            measurementTool: "laser_rangefinder",
            confidence: 0.85
        ),
        createdAt: Date(timeIntervalSince1970: 1609459200)
    )
    
    /// Low confidence calibration
    public static let lowConfidence = CalibrationDTO(
        firstPoint: SIMD3<Float>(0.0, 0.0, 0.0),
        secondPoint: SIMD3<Float>(0.2, 0.0, 0.0),
        realWorldDistance: 0.18, // Slightly off measurement
        id: UUID(uuidString: "CAL12345-1234-1234-1234-123456781245")!,
        metadata: CalibrationMetadata(
            description: "Rough estimate calibration",
            measurementTool: "visual_estimate",
            confidence: 0.25
        ),
        createdAt: Date(timeIntervalSince1970: 1609459200)
    )
    
    // MARK: - Device Calibration Parameters
    
    /// iPhone 15 Pro camera calibration parameters
    public static let iphone15ProCalibration = CalibrationDTO(
        firstPoint: SIMD3<Float>(0.0, 0.0, 0.0),
        secondPoint: SIMD3<Float>(0.1, 0.0, 0.0), // 10cm reference
        realWorldDistance: 0.1,
        id: UUID(uuidString: "CAL12345-1234-1234-1234-123456781246")!,
        metadata: CalibrationMetadata(
            description: "iPhone 15 Pro LiDAR calibration",
            measurementTool: "lidar_scanner",
            units: "meters",
            confidence: 0.97
        ),
        createdAt: Date(timeIntervalSince1970: 1609459200)
    )
    
    /// iPad Pro calibration parameters
    public static let iPadProCalibration = CalibrationDTO(
        firstPoint: SIMD3<Float>(-0.15, -0.1, 0.0),
        secondPoint: SIMD3<Float>(0.15, 0.1, 0.0),
        realWorldDistance: 0.3606, // sqrt(0.3² + 0.2²) ≈ 0.3606m
        id: UUID(uuidString: "CAL12345-1234-1234-1234-123456781247")!,
        metadata: CalibrationMetadata(
            description: "iPad Pro 12.9 LiDAR calibration",
            measurementTool: "lidar_scanner",
            units: "meters",
            confidence: 0.96
        ),
        createdAt: Date(timeIntervalSince1970: 1609459200)
    )
    
    // MARK: - AR Session Context Calibrations
    
    /// Room scale calibration
    public static let roomScale = CalibrationDTO(
        firstPoint: SIMD3<Float>(-2.5, 0.0, -2.0),
        secondPoint: SIMD3<Float>(2.5, 0.0, 2.0),
        realWorldDistance: 6.403, // sqrt(5² + 4²) ≈ 6.403m
        id: UUID(uuidString: "CAL12345-1234-1234-1234-123456781248")!,
        metadata: CalibrationMetadata(
            description: "Living room diagonal measurement",
            measurementTool: "laser_measure",
            units: "meters",
            confidence: 0.94
        ),
        createdAt: Date(timeIntervalSince1970: 1609459200)
    )
    
    /// Table-top scale calibration
    public static let tableTop = CalibrationDTO(
        firstPoint: SIMD3<Float>(-0.4, 0.8, -0.3),
        secondPoint: SIMD3<Float>(0.4, 0.8, 0.3),
        realWorldDistance: 1.0, // 1 meter diagonal on table
        id: UUID(uuidString: "CAL12345-1234-1234-1234-123456781249")!,
        metadata: CalibrationMetadata(
            description: "Table surface calibration",
            measurementTool: "tape_measure",
            units: "meters", 
            confidence: 0.93
        ),
        createdAt: Date(timeIntervalSince1970: 1609459200)
    )
    
    // MARK: - Helper Collections
    
    /// All complete/valid calibrations
    public static let validCalibrations: [CalibrationDTO] = [
        ruler30cm,
        tapeMeasure1m,
        creditCard,
        diagonalMeasure,
        iphone15ProCalibration,
        iPadProCalibration,
        roomScale,
        tableTop,
        tinyDistance, // Valid but edge case
        hugeDistance  // Valid but edge case
    ]
    
    /// All incomplete calibrations
    public static let incompleteCalibrations: [CalibrationDTO] = [
        emptyCalibration,
        firstPointOnly,
        secondPointOnly
    ]
    
    /// All invalid calibrations  
    public static let invalidCalibrations: [CalibrationDTO] = [
        zeroDistance,
        negativeDistance
    ]
    
    /// All calibrations combined
    public static let allCalibrations: [CalibrationDTO] = validCalibrations + incompleteCalibrations + invalidCalibrations
    
    /// Calibrations by confidence level
    public static let highConfidenceCalibrations = validCalibrations.filter { 
        ($0.metadata?.confidence ?? 0.0) >= 0.9 
    }
    
    public static let lowConfidenceCalibrations = validCalibrations.filter { 
        ($0.metadata?.confidence ?? 0.0) < 0.5 
    } + [lowConfidence]
    
    // MARK: - Factory Methods
    
    /// Create a calibration with specific scale factor
    public static func calibrationWithScaleFactor(_ scaleFactor: Float) -> CalibrationDTO {
        let meshDistance: Float = 1.0 // 1 unit in mesh space
        let realDistance = Double(meshDistance / scaleFactor)
        
        return CalibrationDTO(
            firstPoint: SIMD3<Float>(0.0, 0.0, 0.0),
            secondPoint: SIMD3<Float>(meshDistance, 0.0, 0.0),
            realWorldDistance: realDistance,
            metadata: CalibrationMetadata(
                description: "Generated calibration with scale factor \(scaleFactor)",
                confidence: 1.0
            )
        )
    }
    
    /// Create calibration between two arbitrary points
    public static func calibrationBetween(
        _ point1: SIMD3<Float>, 
        _ point2: SIMD3<Float>, 
        realDistance: Double
    ) -> CalibrationDTO {
        CalibrationDTO(
            firstPoint: point1,
            secondPoint: point2,
            realWorldDistance: realDistance,
            metadata: CalibrationMetadata(
                description: "Custom point calibration",
                confidence: 0.8
            )
        )
    }
    
    /// Get random valid calibration
    public static func randomValidCalibration() -> CalibrationDTO {
        validCalibrations.randomElement() ?? ruler30cm
    }
    
    /// Common measurement tools for testing
    public static let commonMeasurementTools = [
        "ruler", "tape_measure", "credit_card", "laser_measure",
        "lidar_scanner", "visual_estimate", "micrometer", "laser_rangefinder"
    ]
    
    /// Create calibration with random measurement tool
    public static func calibrationWithRandomTool() -> CalibrationDTO {
        let tool = commonMeasurementTools.randomElement() ?? "ruler"
        return CalibrationDTO(
            firstPoint: SIMD3<Float>(0.0, 0.0, 0.0),
            secondPoint: SIMD3<Float>(0.25, 0.0, 0.0),
            realWorldDistance: 0.25,
            metadata: CalibrationMetadata(
                description: "Calibration using \(tool)",
                measurementTool: tool,
                confidence: Double.random(in: 0.7...0.99)
            )
        )
    }
}