// Version: 1.0.0
// Test Fixtures for AR Module - AR Session Configuration Data

import Foundation
import simd

/// Test fixtures for AR session configuration and camera parameters
@available(iOS 18.0, macOS 15.0, *)
public struct ARSessionFixtures {
    
    // MARK: - Camera Intrinsics
    
    /// iPhone 15 Pro camera intrinsics (realistic values)
    public static let iphone15ProIntrinsics = CameraIntrinsics(
        focalLengthX: 1012.5,
        focalLengthY: 1012.5,
        principalPointX: 375.0,
        principalPointY: 667.0,
        imageWidth: 750,
        imageHeight: 1334,
        deviceModel: "iPhone15,2"
    )
    
    /// iPad Pro 12.9" camera intrinsics
    public static let iPadProIntrinsics = CameraIntrinsics(
        focalLengthX: 1430.2,
        focalLengthY: 1430.2,
        principalPointX: 512.0,
        principalPointY: 683.5,
        imageWidth: 1024,
        imageHeight: 1367,
        deviceModel: "iPad13,8"
    )
    
    /// Generic device intrinsics for testing
    public static let genericIntrinsics = CameraIntrinsics(
        focalLengthX: 800.0,
        focalLengthY: 800.0,
        principalPointX: 320.0,
        principalPointY: 240.0,
        imageWidth: 640,
        imageHeight: 480,
        deviceModel: "Generic"
    )
    
    // MARK: - Camera Extrinsics (Camera Poses)
    
    /// Camera looking straight down at origin
    public static let topDownPose = CameraExtrinsics(
        position: SIMD3<Float>(0.0, 1.0, 0.0),
        rotation: simd_quatf(angle: Float.pi, axis: SIMD3<Float>(1, 0, 0)),
        timestamp: Date(timeIntervalSince1970: 1609459200)
    )
    
    /// Camera at 45-degree angle
    public static let angledPose = CameraExtrinsics(
        position: SIMD3<Float>(0.5, 0.7, 0.5),
        rotation: simd_quatf(angle: Float.pi/4, axis: SIMD3<Float>(1, 0, 1).normalized),
        timestamp: Date(timeIntervalSince1970: 1609459200)
    )
    
    /// Camera close to object
    public static let closeUpPose = CameraExtrinsics(
        position: SIMD3<Float>(0.0, 0.0, 0.3),
        rotation: simd_quatf(angle: 0, axis: SIMD3<Float>(0, 1, 0)),
        timestamp: Date(timeIntervalSince1970: 1609459200)
    )
    
    /// Camera far from object
    public static let distantPose = CameraExtrinsics(
        position: SIMD3<Float>(0.0, 0.0, 3.0),
        rotation: simd_quatf(angle: 0, axis: SIMD3<Float>(0, 1, 0)),
        timestamp: Date(timeIntervalSince1970: 1609459200)
    )
    
    /// Series of camera poses for motion tracking
    public static let motionSequence: [CameraExtrinsics] = [
        CameraExtrinsics(
            position: SIMD3<Float>(0.0, 0.0, 1.0),
            rotation: simd_quatf(angle: 0, axis: SIMD3<Float>(0, 1, 0)),
            timestamp: Date(timeIntervalSince1970: 1609459200)
        ),
        CameraExtrinsics(
            position: SIMD3<Float>(0.1, 0.0, 1.0),
            rotation: simd_quatf(angle: Float.pi/32, axis: SIMD3<Float>(0, 1, 0)),
            timestamp: Date(timeIntervalSince1970: 1609459200.1)
        ),
        CameraExtrinsics(
            position: SIMD3<Float>(0.2, 0.0, 1.0),
            rotation: simd_quatf(angle: Float.pi/16, axis: SIMD3<Float>(0, 1, 0)),
            timestamp: Date(timeIntervalSince1970: 1609459200.2)
        ),
        CameraExtrinsics(
            position: SIMD3<Float>(0.3, 0.05, 1.0),
            rotation: simd_quatf(angle: Float.pi/12, axis: SIMD3<Float>(0, 1, 0)),
            timestamp: Date(timeIntervalSince1970: 1609459200.3)
        )
    ]
    
    // MARK: - AR Session Configurations
    
    /// Basic world tracking configuration
    public static let basicWorldTracking = ARSessionConfig(
        trackingMode: .worldTracking,
        enableLiDAR: true,
        enableDepthData: true,
        enableMotionBlur: false,
        lightEstimationMode: .ambient,
        environmentTexturing: .none,
        planeDetection: [.horizontal, .vertical],
        maxTrackingImages: 10,
        isCollaborativeSession: false
    )
    
    /// High quality configuration for detailed scanning
    public static let highQualityScanning = ARSessionConfig(
        trackingMode: .worldTracking,
        enableLiDAR: true,
        enableDepthData: true,
        enableMotionBlur: false,
        lightEstimationMode: .directional,
        environmentTexturing: .manual,
        planeDetection: [.horizontal, .vertical],
        maxTrackingImages: 25,
        isCollaborativeSession: false
    )
    
    /// Minimal configuration for performance testing
    public static let minimalConfig = ARSessionConfig(
        trackingMode: .orientationTracking,
        enableLiDAR: false,
        enableDepthData: false,
        enableMotionBlur: false,
        lightEstimationMode: .disabled,
        environmentTexturing: .none,
        planeDetection: [],
        maxTrackingImages: 0,
        isCollaborativeSession: false
    )
    
    /// Face tracking configuration
    public static let faceTracking = ARSessionConfig(
        trackingMode: .faceTracking,
        enableLiDAR: false,
        enableDepthData: true,
        enableMotionBlur: false,
        lightEstimationMode: .ambient,
        environmentTexturing: .none,
        planeDetection: [],
        maxTrackingImages: 0,
        isCollaborativeSession: false
    )
    
    // MARK: - Lighting Conditions
    
    /// Bright indoor lighting
    public static let brightIndoorLighting = LightEstimate(
        ambientIntensity: 1200.0,
        ambientColorTemperature: 4000.0,
        primaryLightDirection: SIMD3<Float>(0.0, -1.0, 0.2),
        primaryLightIntensity: 800.0
    )
    
    /// Dim indoor lighting
    public static let dimIndoorLighting = LightEstimate(
        ambientIntensity: 300.0,
        ambientColorTemperature: 2700.0,
        primaryLightDirection: SIMD3<Float>(0.3, -0.8, 0.1),
        primaryLightIntensity: 150.0
    )
    
    /// Outdoor daylight
    public static let outdoorDaylight = LightEstimate(
        ambientIntensity: 2500.0,
        ambientColorTemperature: 5500.0,
        primaryLightDirection: SIMD3<Float>(0.2, -0.9, 0.1),
        primaryLightIntensity: 2000.0
    )
    
    /// No light estimate (unknown conditions)
    public static let unknownLighting = LightEstimate(
        ambientIntensity: 1000.0,
        ambientColorTemperature: 4000.0,
        primaryLightDirection: SIMD3<Float>(0.0, -1.0, 0.0),
        primaryLightIntensity: 500.0
    )
    
    // MARK: - Edge Cases and Error Scenarios
    
    /// Invalid camera intrinsics (zero focal length)
    public static let invalidIntrinsics = CameraIntrinsics(
        focalLengthX: 0.0,
        focalLengthY: 0.0,
        principalPointX: 0.0,
        principalPointY: 0.0,
        imageWidth: 0,
        imageHeight: 0,
        deviceModel: "Invalid"
    )
    
    /// Extreme camera pose (very far)
    public static let extremePose = CameraExtrinsics(
        position: SIMD3<Float>(1000.0, 1000.0, 1000.0),
        rotation: simd_quatf(angle: Float.pi * 2, axis: SIMD3<Float>(1, 1, 1)),
        timestamp: Date.distantFuture
    )
    
    // MARK: - Collections
    
    /// All valid camera intrinsics
    public static let validIntrinsics: [CameraIntrinsics] = [
        iphone15ProIntrinsics,
        iPadProIntrinsics,
        genericIntrinsics
    ]
    
    /// All camera poses
    public static let allPoses: [CameraExtrinsics] = [
        topDownPose,
        angledPose,
        closeUpPose,
        distantPose
    ] + motionSequence
    
    /// All AR configurations
    public static let allConfigs: [ARSessionConfig] = [
        basicWorldTracking,
        highQualityScanning,
        minimalConfig,
        faceTracking
    ]
    
    /// All lighting conditions
    public static let allLightingConditions: [LightEstimate] = [
        brightIndoorLighting,
        dimIndoorLighting,
        outdoorDaylight,
        unknownLighting
    ]
}

// MARK: - Supporting Data Structures

/// Camera intrinsic parameters
@available(iOS 18.0, macOS 15.0, *)
public struct CameraIntrinsics: Sendable, Codable, Equatable {
    public let focalLengthX: Double
    public let focalLengthY: Double
    public let principalPointX: Double
    public let principalPointY: Double
    public let imageWidth: Int
    public let imageHeight: Int
    public let deviceModel: String
    
    public init(
        focalLengthX: Double,
        focalLengthY: Double,
        principalPointX: Double,
        principalPointY: Double,
        imageWidth: Int,
        imageHeight: Int,
        deviceModel: String
    ) {
        self.focalLengthX = focalLengthX
        self.focalLengthY = focalLengthY
        self.principalPointX = principalPointX
        self.principalPointY = principalPointY
        self.imageWidth = imageWidth
        self.imageHeight = imageHeight
        self.deviceModel = deviceModel
    }
    
    public var isValid: Bool {
        focalLengthX > 0 && focalLengthY > 0 && 
        imageWidth > 0 && imageHeight > 0
    }
}

/// Camera extrinsic parameters (pose)
@available(iOS 18.0, macOS 15.0, *)
public struct CameraExtrinsics: Sendable, Codable, Equatable {
    public let position: SIMD3<Float>
    public let rotation: simd_quatf
    public let timestamp: Date
    
    public init(position: SIMD3<Float>, rotation: simd_quatf, timestamp: Date) {
        self.position = position
        self.rotation = rotation
        self.timestamp = timestamp
    }
    
    // Codable conformance for simd_quatf
    private enum CodingKeys: String, CodingKey {
        case position, rotation, timestamp
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let posArray = try container.decode([Float].self, forKey: .position)
        guard posArray.count == 3 else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Position must have 3 components")
            )
        }
        position = SIMD3<Float>(posArray[0], posArray[1], posArray[2])
        
        let rotArray = try container.decode([Float].self, forKey: .rotation)
        guard rotArray.count == 4 else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Rotation must have 4 components")
            )
        }
        rotation = simd_quatf(ix: rotArray[0], iy: rotArray[1], iz: rotArray[2], r: rotArray[3])
        
        timestamp = try container.decode(Date.self, forKey: .timestamp)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode([position.x, position.y, position.z], forKey: .position)
        try container.encode([rotation.imag.x, rotation.imag.y, rotation.imag.z, rotation.real], forKey: .rotation)
        try container.encode(timestamp, forKey: .timestamp)
    }
}

/// AR Session configuration
@available(iOS 18.0, macOS 15.0, *)
public struct ARSessionConfig: Sendable, Codable, Equatable {
    public let trackingMode: TrackingMode
    public let enableLiDAR: Bool
    public let enableDepthData: Bool
    public let enableMotionBlur: Bool
    public let lightEstimationMode: LightEstimationMode
    public let environmentTexturing: EnvironmentTexturing
    public let planeDetection: Set<PlaneDetectionMode>
    public let maxTrackingImages: Int
    public let isCollaborativeSession: Bool
    
    public init(
        trackingMode: TrackingMode,
        enableLiDAR: Bool,
        enableDepthData: Bool,
        enableMotionBlur: Bool,
        lightEstimationMode: LightEstimationMode,
        environmentTexturing: EnvironmentTexturing,
        planeDetection: Set<PlaneDetectionMode>,
        maxTrackingImages: Int,
        isCollaborativeSession: Bool
    ) {
        self.trackingMode = trackingMode
        self.enableLiDAR = enableLiDAR
        self.enableDepthData = enableDepthData
        self.enableMotionBlur = enableMotionBlur
        self.lightEstimationMode = lightEstimationMode
        self.environmentTexturing = environmentTexturing
        self.planeDetection = planeDetection
        self.maxTrackingImages = maxTrackingImages
        self.isCollaborativeSession = isCollaborativeSession
    }
}

// MARK: - Enums

@available(iOS 18.0, macOS 15.0, *)
public enum TrackingMode: String, Sendable, Codable, CaseIterable {
    case worldTracking = "world"
    case orientationTracking = "orientation"
    case faceTracking = "face"
    case bodyTracking = "body"
}

@available(iOS 18.0, macOS 15.0, *)
public enum LightEstimationMode: String, Sendable, Codable, CaseIterable {
    case disabled = "disabled"
    case ambient = "ambient"
    case directional = "directional"
}

@available(iOS 18.0, macOS 15.0, *)
public enum EnvironmentTexturing: String, Sendable, Codable, CaseIterable {
    case none = "none"
    case manual = "manual"
    case automatic = "automatic"
}

@available(iOS 18.0, macOS 15.0, *)
public enum PlaneDetectionMode: String, Sendable, Codable, CaseIterable {
    case horizontal = "horizontal"
    case vertical = "vertical"
}

/// Light estimation data
@available(iOS 18.0, macOS 15.0, *)
public struct LightEstimate: Sendable, Codable, Equatable {
    public let ambientIntensity: Double
    public let ambientColorTemperature: Double
    public let primaryLightDirection: SIMD3<Float>
    public let primaryLightIntensity: Double
    
    public init(
        ambientIntensity: Double,
        ambientColorTemperature: Double,
        primaryLightDirection: SIMD3<Float>,
        primaryLightIntensity: Double
    ) {
        self.ambientIntensity = ambientIntensity
        self.ambientColorTemperature = ambientColorTemperature
        self.primaryLightDirection = primaryLightDirection
        self.primaryLightIntensity = primaryLightIntensity
    }
    
    // Codable conformance for SIMD3<Float>
    private enum CodingKeys: String, CodingKey {
        case ambientIntensity, ambientColorTemperature, primaryLightDirection, primaryLightIntensity
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        ambientIntensity = try container.decode(Double.self, forKey: .ambientIntensity)
        ambientColorTemperature = try container.decode(Double.self, forKey: .ambientColorTemperature)
        primaryLightIntensity = try container.decode(Double.self, forKey: .primaryLightIntensity)
        
        let dirArray = try container.decode([Float].self, forKey: .primaryLightDirection)
        guard dirArray.count == 3 else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Direction must have 3 components")
            )
        }
        primaryLightDirection = SIMD3<Float>(dirArray[0], dirArray[1], dirArray[2])
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(ambientIntensity, forKey: .ambientIntensity)
        try container.encode(ambientColorTemperature, forKey: .ambientColorTemperature)
        try container.encode(primaryLightIntensity, forKey: .primaryLightIntensity)
        try container.encode([primaryLightDirection.x, primaryLightDirection.y, primaryLightDirection.z], forKey: .primaryLightDirection)
    }
}