// Version: 1.0.0
// CoverCraft Core Module - Error Types

import Foundation

/// Base protocol for all CoverCraft errors
public protocol CoverCraftError: Error, LocalizedError, Sendable {
    var module: String { get }
    var code: String { get }
    var userMessage: String { get }
}

// MARK: - AR Module Errors

/// Errors related to AR scanning
@available(iOS 18.0, *)
public enum ARScanningError: CoverCraftError {
    case deviceNotSupported
    case cameraPermissionDenied
    case sessionFailed(Error)
    case trackingLost
    case meshGenerationFailed(String)
    case insufficientData
    case sessionNotActive
    
    public var module: String { "AR" }
    
    public var code: String {
        switch self {
        case .deviceNotSupported: return "AR001"
        case .cameraPermissionDenied: return "AR002"
        case .sessionFailed: return "AR003"
        case .trackingLost: return "AR004"
        case .meshGenerationFailed: return "AR005"
        case .insufficientData: return "AR006"
        case .sessionNotActive: return "AR007"
        }
    }
    
    public var userMessage: String {
        switch self {
        case .deviceNotSupported:
            return "This device doesn't support LiDAR scanning. Please use an iPhone 12 Pro or later."
        case .cameraPermissionDenied:
            return "Camera access is required for scanning. Please enable camera permissions in Settings."
        case .sessionFailed(let error):
            return "Scanning session failed: \(error.localizedDescription)"
        case .trackingLost:
            return "Tracking was lost. Please move slower and ensure good lighting."
        case .meshGenerationFailed(let reason):
            return "Failed to generate 3D mesh: \(reason)"
        case .insufficientData:
            return "Not enough scan data. Please scan more of the object."
        case .sessionNotActive:
            return "Scanning session is not active. Please start scanning first."
        }
    }
    
    public var errorDescription: String? { userMessage }
}

// MARK: - Segmentation Module Errors

/// Errors related to mesh segmentation
@available(iOS 18.0, *)
public enum SegmentationError: CoverCraftError {
    case invalidMesh(String)
    case segmentationFailed(String)
    case invalidPanelCount(Int)
    case algorithmsFailure(String)
    case memoryExhausted
    case timeout
    
    public var module: String { "Segmentation" }
    
    public var code: String {
        switch self {
        case .invalidMesh: return "SEG001"
        case .segmentationFailed: return "SEG002"
        case .invalidPanelCount: return "SEG003"
        case .algorithmsFailure: return "SEG004"
        case .memoryExhausted: return "SEG005"
        case .timeout: return "SEG006"
        }
    }
    
    public var userMessage: String {
        switch self {
        case .invalidMesh(let reason):
            return "Invalid mesh data: \(reason)"
        case .segmentationFailed(let reason):
            return "Failed to segment mesh into panels: \(reason)"
        case .invalidPanelCount(let count):
            return "Invalid panel count: \(count). Must be between 3 and 20."
        case .algorithmsFailure(let reason):
            return "Segmentation algorithm failed: \(reason)"
        case .memoryExhausted:
            return "Not enough memory to process this mesh. Try with a smaller scan."
        case .timeout:
            return "Segmentation took too long. Try with lower resolution setting."
        }
    }
    
    public var errorDescription: String? { userMessage }
}

// MARK: - Flattening Module Errors

/// Errors related to pattern flattening
@available(iOS 18.0, *)
public enum FlatteningError: CoverCraftError {
    case invalidPanel(String)
    case flatteningFailed(String)
    case degenerateGeometry
    case intersectingPatterns
    case optimizationFailed(String)
    case layoutFailed
    
    public var module: String { "Flattening" }
    
    public var code: String {
        switch self {
        case .invalidPanel: return "FLAT001"
        case .flatteningFailed: return "FLAT002"
        case .degenerateGeometry: return "FLAT003"
        case .intersectingPatterns: return "FLAT004"
        case .optimizationFailed: return "FLAT005"
        case .layoutFailed: return "FLAT006"
        }
    }
    
    public var userMessage: String {
        switch self {
        case .invalidPanel(let reason):
            return "Invalid panel geometry: \(reason)"
        case .flatteningFailed(let reason):
            return "Failed to flatten 3D pattern: \(reason)"
        case .degenerateGeometry:
            return "Panel geometry is degenerate and cannot be flattened."
        case .intersectingPatterns:
            return "Pattern pieces intersect. Try reducing the number of panels."
        case .optimizationFailed(let reason):
            return "Failed to optimize pattern layout: \(reason)"
        case .layoutFailed:
            return "Could not arrange patterns efficiently. Try smaller panels."
        }
    }
    
    public var errorDescription: String? { userMessage }
}

// MARK: - Export Module Errors

/// Errors related to pattern export
@available(iOS 18.0, *)
public enum ExportError: CoverCraftError {
    case invalidFormat(String)
    case exportFailed(String)
    case fileTooLarge(Int64)
    case permissionDenied
    case diskSpaceExhausted
    case corruptedData
    case unsupportedFeature(String)
    
    public var module: String { "Export" }
    
    public var code: String {
        switch self {
        case .invalidFormat: return "EXP001"
        case .exportFailed: return "EXP002"
        case .fileTooLarge: return "EXP003"
        case .permissionDenied: return "EXP004"
        case .diskSpaceExhausted: return "EXP005"
        case .corruptedData: return "EXP006"
        case .unsupportedFeature: return "EXP007"
        }
    }
    
    public var userMessage: String {
        switch self {
        case .invalidFormat(let format):
            return "Unsupported export format: \(format)"
        case .exportFailed(let reason):
            return "Export failed: \(reason)"
        case .fileTooLarge(let size):
            return "Generated file is too large (\(size) bytes). Try reducing complexity."
        case .permissionDenied:
            return "Permission denied. Check file access permissions."
        case .diskSpaceExhausted:
            return "Not enough disk space to save the exported file."
        case .corruptedData:
            return "Pattern data is corrupted and cannot be exported."
        case .unsupportedFeature(let feature):
            return "Feature '\(feature)' is not supported in this export format."
        }
    }
    
    public var errorDescription: String? { userMessage }
}

// MARK: - Calibration Module Errors

/// Errors related to calibration
@available(iOS 18.0, *)
public enum CalibrationError: CoverCraftError {
    case invalidPoint(String)
    case pointsTooClose
    case invalidDistance(Double)
    case calibrationIncomplete
    case measurementFailed(String)
    
    public var module: String { "Calibration" }
    
    public var code: String {
        switch self {
        case .invalidPoint: return "CAL001"
        case .pointsTooClose: return "CAL002"
        case .invalidDistance: return "CAL003"
        case .calibrationIncomplete: return "CAL004"
        case .measurementFailed: return "CAL005"
        }
    }
    
    public var userMessage: String {
        switch self {
        case .invalidPoint(let reason):
            return "Invalid calibration point: \(reason)"
        case .pointsTooClose:
            return "Calibration points are too close together. Select points further apart."
        case .invalidDistance(let distance):
            return "Invalid real-world distance: \(distance)m. Must be positive."
        case .calibrationIncomplete:
            return "Calibration is incomplete. Set both points and real-world distance."
        case .measurementFailed(let reason):
            return "Measurement failed: \(reason)"
        }
    }
    
    public var errorDescription: String? { userMessage }
}

// MARK: - Core Module Errors

/// Errors related to core functionality
@available(iOS 18.0, *)
public enum CoreError: CoverCraftError {
    case dependencyNotFound(String)
    case invalidConfiguration(String)
    case initializationFailed(String)
    case operationCancelled
    case unknownError(Error)
    
    public var module: String { "Core" }
    
    public var code: String {
        switch self {
        case .dependencyNotFound: return "CORE001"
        case .invalidConfiguration: return "CORE002"
        case .initializationFailed: return "CORE003"
        case .operationCancelled: return "CORE004"
        case .unknownError: return "CORE005"
        }
    }
    
    public var userMessage: String {
        switch self {
        case .dependencyNotFound(let dependency):
            return "Required service not found: \(dependency)"
        case .invalidConfiguration(let reason):
            return "Invalid configuration: \(reason)"
        case .initializationFailed(let reason):
            return "Failed to initialize: \(reason)"
        case .operationCancelled:
            return "Operation was cancelled."
        case .unknownError(let error):
            return "An unexpected error occurred: \(error.localizedDescription)"
        }
    }
    
    public var errorDescription: String? { userMessage }
}

// MARK: - Error Utilities

@available(iOS 18.0, *)
public extension CoverCraftError {
    /// Full error identifier with module and code
    var fullCode: String {
        "\(module):\(code)"
    }
    
    /// Error for logging with technical details
    var logMessage: String {
        "[\(fullCode)] \(userMessage)"
    }
}