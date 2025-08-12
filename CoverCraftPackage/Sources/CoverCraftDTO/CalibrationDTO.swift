// Version: 1.0.0
// CoverCraft DTO Module - Calibration Data Transfer Object

import Foundation
import simd

/// Immutable data transfer object representing calibration data for real-world scaling
/// 
/// This DTO is designed for stable serialization and transfer between modules.
/// Breaking changes require a version bump and migration path.
@available(iOS 18.0, macOS 15.0, *)
public struct CalibrationDTO: Sendable, Codable, Equatable {
    
    // MARK: - Properties
    
    /// Unique identifier for this calibration
    public let id: UUID
    
    /// First calibration point in 3D mesh space
    public let firstPoint: SIMD3<Float>?
    
    /// Second calibration point in 3D mesh space
    public let secondPoint: SIMD3<Float>?
    
    /// Real-world distance between the two points (in meters)
    public let realWorldDistance: Double
    
    /// Version of the calibration data format
    public let version: String
    
    /// Timestamp when this calibration was created
    public let createdAt: Date
    
    /// Optional metadata about the calibration
    public let metadata: CalibrationMetadata?
    
    // MARK: - Computed Properties
    
    /// Whether the calibration is complete and valid
    public var isComplete: Bool {
        guard let first = firstPoint,
              let second = secondPoint else {
            return false
        }
        
        return realWorldDistance > 0 && 
               simd_distance(first, second) > 0.001 // Minimum mesh space distance
    }
    
    /// Scale factor to convert from mesh units to real-world meters
    public var scaleFactor: Float {
        guard let first = firstPoint,
              let second = secondPoint else {
            return 1.0
        }
        
        let meshDistance = simd_distance(first, second)
        guard meshDistance > 0.001 else { return 1.0 }
        
        return Float(realWorldDistance / Double(meshDistance))
    }
    
    /// Distance between calibration points in mesh space
    public var meshDistance: Float {
        guard let first = firstPoint,
              let second = secondPoint else {
            return 0.0
        }
        
        return simd_distance(first, second)
    }
    
    // MARK: - Initialization
    
    /// Creates a new calibration DTO
    /// - Parameters:
    ///   - firstPoint: First calibration point in mesh space
    ///   - secondPoint: Second calibration point in mesh space
    ///   - realWorldDistance: Real-world distance between points (meters)
    ///   - id: Unique identifier (defaults to new UUID)
    ///   - metadata: Optional calibration metadata
    ///   - createdAt: Creation timestamp (defaults to now)
    public init(
        firstPoint: SIMD3<Float>? = nil,
        secondPoint: SIMD3<Float>? = nil,
        realWorldDistance: Double = 1.0,
        id: UUID = UUID(),
        metadata: CalibrationMetadata? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.firstPoint = firstPoint
        self.secondPoint = secondPoint
        self.realWorldDistance = max(0, realWorldDistance)
        self.version = "1.0.0"
        self.metadata = metadata
        self.createdAt = createdAt
    }
    
    // MARK: - Factory Methods
    
    /// Create an empty calibration
    /// - Returns: New empty calibration DTO
    public static func empty() -> CalibrationDTO {
        CalibrationDTO()
    }
    
    /// Create a calibration with both points set
    /// - Parameters:
    ///   - firstPoint: First calibration point
    ///   - secondPoint: Second calibration point  
    ///   - realWorldDistance: Real-world distance (meters)
    /// - Returns: New calibration DTO
    public static func with(
        firstPoint: SIMD3<Float>,
        secondPoint: SIMD3<Float>, 
        realWorldDistance: Double
    ) -> CalibrationDTO {
        CalibrationDTO(
            firstPoint: firstPoint,
            secondPoint: secondPoint,
            realWorldDistance: realWorldDistance
        )
    }
    
    // MARK: - Mutation Methods (Return New Instances)
    
    /// Set the first calibration point
    /// - Parameter point: New first point
    /// - Returns: New calibration DTO with updated first point
    public func settingFirstPoint(_ point: SIMD3<Float>) -> CalibrationDTO {
        CalibrationDTO(
            firstPoint: point,
            secondPoint: secondPoint,
            realWorldDistance: realWorldDistance,
            id: id,
            metadata: metadata,
            createdAt: createdAt
        )
    }
    
    /// Set the second calibration point
    /// - Parameter point: New second point
    /// - Returns: New calibration DTO with updated second point
    public func settingSecondPoint(_ point: SIMD3<Float>) -> CalibrationDTO {
        CalibrationDTO(
            firstPoint: firstPoint,
            secondPoint: point,
            realWorldDistance: realWorldDistance,
            id: id,
            metadata: metadata,
            createdAt: createdAt
        )
    }
    
    /// Set the real-world distance
    /// - Parameter distance: New real-world distance (meters)
    /// - Returns: New calibration DTO with updated distance
    public func settingRealWorldDistance(_ distance: Double) -> CalibrationDTO {
        CalibrationDTO(
            firstPoint: firstPoint,
            secondPoint: secondPoint,
            realWorldDistance: distance,
            id: id,
            metadata: metadata,
            createdAt: createdAt
        )
    }
    
    /// Reset calibration to empty state
    /// - Returns: New empty calibration DTO with new ID
    public func reset() -> CalibrationDTO {
        CalibrationDTO.empty()
    }
    
    // MARK: - Codable Conformance
    
    private enum CodingKeys: String, CodingKey {
        case id
        case firstPoint
        case secondPoint
        case realWorldDistance
        case version
        case createdAt
        case metadata
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = try container.decode(UUID.self, forKey: .id)
        self.realWorldDistance = try container.decode(Double.self, forKey: .realWorldDistance)
        self.version = try container.decodeIfPresent(String.self, forKey: .version) ?? "1.0.0"
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.metadata = try container.decodeIfPresent(CalibrationMetadata.self, forKey: .metadata)
        
        // Decode SIMD3<Float> points as arrays
        if let firstArray = try container.decodeIfPresent([Float].self, forKey: .firstPoint) {
            guard firstArray.count == 3 else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription: "Point must have exactly 3 components"
                    )
                )
            }
            self.firstPoint = SIMD3<Float>(firstArray[0], firstArray[1], firstArray[2])
        } else {
            self.firstPoint = nil
        }
        
        if let secondArray = try container.decodeIfPresent([Float].self, forKey: .secondPoint) {
            guard secondArray.count == 3 else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription: "Point must have exactly 3 components"
                    )
                )
            }
            self.secondPoint = SIMD3<Float>(secondArray[0], secondArray[1], secondArray[2])
        } else {
            self.secondPoint = nil
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(realWorldDistance, forKey: .realWorldDistance)
        try container.encode(version, forKey: .version)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(metadata, forKey: .metadata)
        
        // Encode SIMD3<Float> points as arrays
        if let first = firstPoint {
            try container.encode([first.x, first.y, first.z], forKey: .firstPoint)
        }
        
        if let second = secondPoint {
            try container.encode([second.x, second.y, second.z], forKey: .secondPoint)
        }
    }
}

/// Metadata for calibration data
@available(iOS 18.0, macOS 15.0, *)
public struct CalibrationMetadata: Sendable, Codable, Equatable {
    
    /// User-provided description of what was measured
    public let description: String?
    
    /// Measurement tool used (e.g., "ruler", "tape measure")
    public let measurementTool: String?
    
    /// Units of the real-world measurement
    public let units: String
    
    /// Confidence in the measurement (0.0 to 1.0)
    public let confidence: Double
    
    /// Creates new calibration metadata
    /// - Parameters:
    ///   - description: Description of what was measured
    ///   - measurementTool: Tool used for measurement
    ///   - units: Units of measurement (defaults to "meters")
    ///   - confidence: Confidence in measurement (defaults to 1.0)
    public init(
        description: String? = nil,
        measurementTool: String? = nil,
        units: String = "meters",
        confidence: Double = 1.0
    ) {
        self.description = description
        self.measurementTool = measurementTool
        self.units = units
        self.confidence = max(0.0, min(1.0, confidence))
    }
}