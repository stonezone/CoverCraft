// Version: 1.0.0
// Comprehensive error handling for CoverCraft

import Foundation

/// Root error type for CoverCraft application
public enum CoverCraftError: Error {
    case ar(ARError)
    case segmentation(SegmentationError)
    case export(ExportError)
    case validation(ValidationError)
    case calibration(CalibrationError)
    case persistence(PersistenceError)
}

/// AR scanning related errors
public enum ARError: Error, LocalizedError {
    case deviceNotSupported
    case sessionInterrupted
    case insufficientFeatures
    case trackingLost
    case cameraPermissionDenied
    case worldTrackingNotAvailable
    case meshDataCorrupted
    
    public var errorDescription: String? {
        switch self {
        case .deviceNotSupported:
            return "This device does not support AR features required by CoverCraft"
        case .sessionInterrupted:
            return "AR session was interrupted. Please try scanning again"
        case .insufficientFeatures:
            return "Not enough visual features detected. Move closer to the object and ensure good lighting"
        case .trackingLost:
            return "AR tracking lost. Move device slowly and keep the object in view"
        case .cameraPermissionDenied:
            return "Camera access is required for 3D scanning. Please grant permission in Settings"
        case .worldTrackingNotAvailable:
            return "World tracking is not available on this device"
        case .meshDataCorrupted:
            return "Scanned mesh data is corrupted. Please try scanning again"
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .deviceNotSupported:
            return "CoverCraft requires a device with LiDAR sensor (iPhone 12 Pro or later, iPad Pro 2020 or later)"
        case .sessionInterrupted:
            return "Restart the scanning session"
        case .insufficientFeatures:
            return "Ensure the object has texture and is well-lit. Avoid reflective surfaces"
        case .trackingLost:
            return "Move the device slowly and keep the object centered in the camera view"
        case .cameraPermissionDenied:
            return "Go to Settings > CoverCraft > Camera and enable camera access"
        case .worldTrackingNotAvailable:
            return "Close other apps and restart CoverCraft"
        case .meshDataCorrupted:
            return "Clear the current scan and start over"
        }
    }
}

/// Mesh segmentation related errors
public enum SegmentationError: Error, LocalizedError {
    case insufficientGeometry
    case algorithmFailure
    case memoryLimitExceeded
    case invalidMeshData
    case processingTimeout
    
    public var errorDescription: String? {
        switch self {
        case .insufficientGeometry:
            return "The scanned mesh doesn't have enough geometry for segmentation"
        case .algorithmFailure:
            return "Segmentation algorithm failed to process the mesh"
        case .memoryLimitExceeded:
            return "Not enough memory to process this mesh"
        case .invalidMeshData:
            return "Mesh data is invalid or corrupted"
        case .processingTimeout:
            return "Segmentation took too long and was cancelled"
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .insufficientGeometry:
            return "Scan a larger area or get closer to capture more detail"
        case .algorithmFailure:
            return "Try using a different segmentation resolution"
        case .memoryLimitExceeded:
            return "Close other apps and try again, or use a lower resolution"
        case .invalidMeshData:
            return "Re-scan the object to generate new mesh data"
        case .processingTimeout:
            return "Try using a lower resolution or scan a smaller object"
        }
    }
}

/// Export related errors
public enum ExportError: Error, LocalizedError {
    case fileWritePermissionDenied
    case insufficientStorage
    case formatNotSupported
    case exportDataCorrupted
    case networkUnavailable
    
    public var errorDescription: String? {
        switch self {
        case .fileWritePermissionDenied:
            return "Permission denied to write files"
        case .insufficientStorage:
            return "Not enough storage space to export pattern"
        case .formatNotSupported:
            return "Export format is not supported"
        case .exportDataCorrupted:
            return "Export data is corrupted"
        case .networkUnavailable:
            return "Network connection unavailable for cloud export"
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .fileWritePermissionDenied:
            return "Grant file access permission in Settings"
        case .insufficientStorage:
            return "Free up storage space and try again"
        case .formatNotSupported:
            return "Choose a different export format"
        case .exportDataCorrupted:
            return "Regenerate the pattern and try exporting again"
        case .networkUnavailable:
            return "Check your internet connection and try again"
        }
    }
}

/// Validation related errors
public enum ValidationError: Error, LocalizedError {
    case invalidCalibrationPoints
    case meshTooSmall
    case meshTooLarge
    case invalidDimensions
    case missingRequiredData
    
    public var errorDescription: String? {
        switch self {
        case .invalidCalibrationPoints:
            return "Calibration points are invalid"
        case .meshTooSmall:
            return "Scanned object is too small"
        case .meshTooLarge:
            return "Scanned object is too large"
        case .invalidDimensions:
            return "Object dimensions are invalid"
        case .missingRequiredData:
            return "Required data is missing"
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .invalidCalibrationPoints:
            return "Select two points that are farther apart for better accuracy"
        case .meshTooSmall:
            return "Scan a larger object or get closer to capture more detail"
        case .meshTooLarge:
            return "Scan a smaller section of the object"
        case .invalidDimensions:
            return "Check the real-world distance measurement"
        case .missingRequiredData:
            return "Complete the scanning and calibration process"
        }
    }
}

/// Calibration related errors
public enum CalibrationError: Error, LocalizedError {
    case pointsTooClose
    case invalidDistance
    case calibrationIncomplete
    case measurementAccuracyLow
    
    public var errorDescription: String? {
        switch self {
        case .pointsTooClose:
            return "Calibration points are too close together"
        case .invalidDistance:
            return "Real-world distance must be greater than zero"
        case .calibrationIncomplete:
            return "Calibration is not complete"
        case .measurementAccuracyLow:
            return "Calibration accuracy is too low"
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .pointsTooClose:
            return "Select points that are at least 10cm apart for better accuracy"
        case .invalidDistance:
            return "Enter a valid positive distance measurement"
        case .calibrationIncomplete:
            return "Complete both point selection and distance measurement"
        case .measurementAccuracyLow:
            return "Re-select calibration points on a more stable surface"
        }
    }
}

/// Data persistence related errors
public enum PersistenceError: Error, LocalizedError {
    case saveFailure
    case loadFailure
    case dataCorrupted
    case storageUnavailable
    case quotaExceeded
    
    public var errorDescription: String? {
        switch self {
        case .saveFailure:
            return "Failed to save data"
        case .loadFailure:
            return "Failed to load data"
        case .dataCorrupted:
            return "Saved data is corrupted"
        case .storageUnavailable:
            return "Storage is unavailable"
        case .quotaExceeded:
            return "Storage quota exceeded"
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .saveFailure:
            return "Check storage permissions and available space"
        case .loadFailure:
            return "Try restarting the app"
        case .dataCorrupted:
            return "Delete corrupted data and start over"
        case .storageUnavailable:
            return "Check device storage settings"
        case .quotaExceeded:
            return "Delete old projects to make space"
        }
    }
}

// MARK: - Error Handling Extensions

extension CoverCraftError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .ar(let error):
            return error.errorDescription
        case .segmentation(let error):
            return error.errorDescription
        case .export(let error):
            return error.errorDescription
        case .validation(let error):
            return error.errorDescription
        case .calibration(let error):
            return error.errorDescription
        case .persistence(let error):
            return error.errorDescription
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .ar(let error):
            return error.recoverySuggestion
        case .segmentation(let error):
            return error.recoverySuggestion
        case .export(let error):
            return error.recoverySuggestion
        case .validation(let error):
            return error.recoverySuggestion
        case .calibration(let error):
            return error.recoverySuggestion
        case .persistence(let error):
            return error.recoverySuggestion
        }
    }
}

// MARK: - Result Type Aliases

public typealias ARResult<T> = Result<T, ARError>
public typealias SegmentationResult<T> = Result<T, SegmentationError>
public typealias ExportResult<T> = Result<T, ExportError>
public typealias ValidationResult<T> = Result<T, ValidationError>
public typealias CalibrationResult<T> = Result<T, CalibrationError>
public typealias PersistenceResult<T> = Result<T, PersistenceError>
public typealias CoverCraftResult<T> = Result<T, CoverCraftError>