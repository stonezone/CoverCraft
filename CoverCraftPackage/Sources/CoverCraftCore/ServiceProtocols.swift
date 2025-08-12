// Version: 1.0.0
// CoverCraft Core Module - Service Protocols

import Foundation
import CoverCraftDTO

// MARK: - AR Scanning Services

/// Service for AR-based mesh scanning
@available(iOS 18.0, macOS 15.0, *)
public protocol ARScanningService: Sendable {
    /// Start AR scanning session
    func startScanning() async throws
    
    /// Stop AR scanning session
    func stopScanning() async
    
    /// Get current scanned mesh
    func getCurrentMesh() async -> MeshDTO?
    
    /// Check if AR is available on device
    func isARAvailable() -> Bool
}

/// Service for AR session management
@available(iOS 18.0, macOS 15.0, *)
public protocol ARSessionService: Sendable {
    /// Configure AR session
    func configure() async throws
    
    /// Reset AR session
    func reset() async
    
    /// Pause AR session
    func pause() async
    
    /// Resume AR session
    func resume() async throws
}

// MARK: - Mesh Processing Services

/// Service for mesh segmentation into panels
@available(iOS 18.0, macOS 15.0, *)
public protocol MeshSegmentationService: Sendable {
    /// Segment a mesh into panels
    /// - Parameters:
    ///   - mesh: Input mesh to segment
    ///   - targetPanelCount: Desired number of panels
    /// - Returns: Array of segmented panels
    func segmentMesh(_ mesh: MeshDTO, targetPanelCount: Int) async throws -> [PanelDTO]
    
    /// Preview segmentation without full processing
    /// - Parameters:
    ///   - mesh: Input mesh
    ///   - resolution: Segmentation resolution level
    /// - Returns: Preview of panel boundaries
    func previewSegmentation(_ mesh: MeshDTO, resolution: SegmentationResolution) async throws -> [PanelDTO]
}

/// Service for pattern flattening
@available(iOS 18.0, macOS 15.0, *)
public protocol PatternFlatteningService: Sendable {
    /// Flatten 3D panels to 2D patterns
    /// - Parameters:
    ///   - panels: 3D panels to flatten
    ///   - mesh: Original mesh for reference
    /// - Returns: Flattened 2D panels
    func flattenPanels(_ panels: [PanelDTO], from mesh: MeshDTO) async throws -> [FlattenedPanelDTO]
    
    /// Optimize flattened panels for cutting
    /// - Parameter panels: Panels to optimize
    /// - Returns: Optimized panels
    func optimizeForCutting(_ panels: [FlattenedPanelDTO]) async throws -> [FlattenedPanelDTO]
}

// MARK: - Calibration Services

/// Service for real-world scale calibration
@available(iOS 18.0, macOS 15.0, *)
public protocol CalibrationService: Sendable {
    /// Create new calibration
    func createCalibration() -> CalibrationDTO
    
    /// Set first calibration point
    /// - Parameters:
    ///   - calibration: Current calibration
    ///   - point: 3D point in mesh space
    /// - Returns: Updated calibration
    func setFirstPoint(_ calibration: CalibrationDTO, point: SIMD3<Float>) -> CalibrationDTO
    
    /// Set second calibration point
    /// - Parameters:
    ///   - calibration: Current calibration  
    ///   - point: 3D point in mesh space
    /// - Returns: Updated calibration
    func setSecondPoint(_ calibration: CalibrationDTO, point: SIMD3<Float>) -> CalibrationDTO
    
    /// Set real-world distance
    /// - Parameters:
    ///   - calibration: Current calibration
    ///   - distance: Distance in meters
    /// - Returns: Updated calibration
    func setRealWorldDistance(_ calibration: CalibrationDTO, distance: Double) -> CalibrationDTO
    
    /// Validate calibration
    /// - Parameter calibration: Calibration to validate
    /// - Returns: Whether calibration is valid
    func validateCalibration(_ calibration: CalibrationDTO) -> Bool
}

// MARK: - Export Services

/// Service for pattern export
@available(iOS 18.0, macOS 15.0, *)
public protocol PatternExportService: Sendable {
    /// Export patterns to various formats
    /// - Parameters:
    ///   - panels: Flattened panels to export
    ///   - format: Export format
    ///   - options: Export options
    /// - Returns: Export result
    func exportPatterns(_ panels: [FlattenedPanelDTO], format: ExportFormat, options: ExportOptions) async throws -> ExportResult
    
    /// Get available export formats
    /// - Returns: Supported export formats
    func getSupportedFormats() -> [ExportFormat]
    
    /// Validate export requirements
    /// - Parameters:
    ///   - panels: Panels to validate
    ///   - format: Target format
    /// - Returns: Validation result
    func validateForExport(_ panels: [FlattenedPanelDTO], format: ExportFormat) -> ExportValidationResult
}

// MARK: - Support Types

/// Segmentation resolution levels
@available(iOS 18.0, macOS 15.0, *)
public enum SegmentationResolution: String, CaseIterable, Sendable, Codable {
    case low = "Low (5 panels)"
    case medium = "Medium (6-10 panels)"
    case high = "High (up to 15 panels)"
    
    public var targetPanelCount: Int {
        switch self {
        case .low: return 5
        case .medium: return 8
        case .high: return 15
        }
    }
}

/// Export formats
@available(iOS 18.0, macOS 15.0, *)
public enum ExportFormat: String, CaseIterable, Sendable, Codable {
    case pdf = "PDF"
    case svg = "SVG"
    case png = "PNG"
    case gif = "GIF"
    case dxf = "DXF"
    
    public var fileExtension: String {
        rawValue.lowercased()
    }
}

/// Export options
@available(iOS 18.0, macOS 15.0, *)
public struct ExportOptions: Sendable, Codable, Equatable {
    public let includeSeamAllowance: Bool
    public let seamAllowanceWidth: Double // in millimeters
    public let includeRegistrationMarks: Bool
    public let paperSize: PaperSize
    public let scale: Double // scale factor for output
    public let includeInstructions: Bool
    
    public init(
        includeSeamAllowance: Bool = true,
        seamAllowanceWidth: Double = 15.0,
        includeRegistrationMarks: Bool = true,
        paperSize: PaperSize = .a4,
        scale: Double = 1.0,
        includeInstructions: Bool = true
    ) {
        self.includeSeamAllowance = includeSeamAllowance
        self.seamAllowanceWidth = seamAllowanceWidth
        self.includeRegistrationMarks = includeRegistrationMarks
        self.paperSize = paperSize
        self.scale = scale
        self.includeInstructions = includeInstructions
    }
}

/// Paper sizes for export
@available(iOS 18.0, macOS 15.0, *)
public enum PaperSize: String, CaseIterable, Sendable, Codable {
    case a4 = "A4"
    case a3 = "A3"
    case letter = "Letter"
    case legal = "Legal"
    case tabloid = "Tabloid"
    
    public var dimensionsInPoints: (width: Double, height: Double) {
        switch self {
        case .a4: return (595, 842)
        case .a3: return (842, 1190)
        case .letter: return (612, 792)
        case .legal: return (612, 1008)
        case .tabloid: return (792, 1224)
        }
    }
}

/// Export result
@available(iOS 18.0, macOS 15.0, *)
public struct ExportResult: Sendable {
    public let data: Data
    public let format: ExportFormat
    public let filename: String
    public let metadata: [String: String]
    
    public init(data: Data, format: ExportFormat, filename: String, metadata: [String: String] = [:]) {
        self.data = data
        self.format = format
        self.filename = filename
        self.metadata = metadata
    }
}

/// Export validation result (simplified)
@available(iOS 18.0, macOS 15.0, *)
public struct ExportValidationResult: Sendable {
    public let isValid: Bool
    public let errors: [String]
    public let warnings: [String]
    
    public init(isValid: Bool, errors: [String] = [], warnings: [String] = []) {
        self.isValid = isValid
        self.errors = errors
        self.warnings = warnings
    }
}

// MARK: - Pattern Validation Services

/// Service for comprehensive pattern validation
@available(iOS 18.0, macOS 15.0, *)
public protocol PatternValidationService: Sendable {
    /// Validate a single flattened panel
    /// - Parameter panel: Panel to validate
    /// - Returns: Detailed validation result
    func validatePanel(_ panel: FlattenedPanelDTO) async -> PatternValidationResult
    
    /// Validate multiple panels for layout compatibility
    /// - Parameter panels: Panels to validate as a set
    /// - Returns: Comprehensive validation result
    func validatePanelSet(_ panels: [FlattenedPanelDTO]) async -> PatternSetValidationResult
    
    /// Validate fabric utilization efficiency
    /// - Parameters:
    ///   - panels: Panels to analyze
    ///   - fabricWidth: Available fabric width in millimeters
    /// - Returns: Utilization analysis result
    func validateFabricUtilization(_ panels: [FlattenedPanelDTO], fabricWidth: Double) -> FabricUtilizationResult
}

/// Detailed pattern validation result
@available(iOS 18.0, macOS 15.0, *)
public struct PatternValidationResult: Sendable {
    public let isValid: Bool
    public let issues: [ValidationIssue]
    public let warnings: [ValidationWarning]
    public let panelId: UUID?
    public let validatedAt: Date
    
    public init(isValid: Bool, issues: [ValidationIssue], warnings: [ValidationWarning], panelId: UUID?, validatedAt: Date) {
        self.isValid = isValid
        self.issues = issues
        self.warnings = warnings
        self.panelId = panelId
        self.validatedAt = validatedAt
    }
}

/// Pattern set validation result
@available(iOS 18.0, macOS 15.0, *)
public struct PatternSetValidationResult: Sendable {
    public let isValid: Bool
    public let panelResults: [PatternValidationResult]
    public let layoutIssues: [ValidationIssue]
    public let fabricCompatibility: FabricCompatibilityResult?
    public let totalArea: Double
    public let recommendedFabricWidth: Double?
    public let validatedAt: Date
    
    public init(isValid: Bool, panelResults: [PatternValidationResult], layoutIssues: [ValidationIssue], fabricCompatibility: FabricCompatibilityResult?, totalArea: Double, recommendedFabricWidth: Double?, validatedAt: Date) {
        self.isValid = isValid
        self.panelResults = panelResults
        self.layoutIssues = layoutIssues
        self.fabricCompatibility = fabricCompatibility
        self.totalArea = totalArea
        self.recommendedFabricWidth = recommendedFabricWidth
        self.validatedAt = validatedAt
    }
}

/// Validation issue detail
@available(iOS 18.0, macOS 15.0, *)
public struct ValidationIssue: Sendable {
    public let severity: ValidationSeverity
    public let type: ValidationIssueType
    public let message: String
    public let panelId: UUID?
    public let location: CGPoint?
    
    public init(severity: ValidationSeverity, type: ValidationIssueType, message: String, panelId: UUID?, location: CGPoint?) {
        self.severity = severity
        self.type = type
        self.message = message
        self.panelId = panelId
        self.location = location
    }
}

/// Validation warning detail
@available(iOS 18.0, macOS 15.0, *)
public struct ValidationWarning: Sendable {
    public let type: ValidationWarningType
    public let message: String
    public let panelId: UUID?
    public let location: CGPoint?
    
    public init(type: ValidationWarningType, message: String, panelId: UUID?, location: CGPoint?) {
        self.type = type
        self.message = message
        self.panelId = panelId
        self.location = location
    }
}

/// Fabric compatibility result
@available(iOS 18.0, macOS 15.0, *)
public struct FabricCompatibilityResult: Sendable {
    public let compatibleWidths: [Double]
    public let recommendedWidth: Double?
    public let issues: [String]
    public let requiresCustomWidth: Bool
    
    public init(compatibleWidths: [Double], recommendedWidth: Double?, issues: [String], requiresCustomWidth: Bool) {
        self.compatibleWidths = compatibleWidths
        self.recommendedWidth = recommendedWidth
        self.issues = issues
        self.requiresCustomWidth = requiresCustomWidth
    }
}

/// Fabric utilization analysis
@available(iOS 18.0, macOS 15.0, *)
public struct FabricUtilizationResult: Sendable {
    public let totalPanelArea: Double
    public let totalFabricArea: Double
    public let efficiency: Double
    public let requiredFabricLength: Double
    public let oversizedPanels: [UUID]
    public let isEfficient: Bool
    public let recommendations: [String]
    
    public init(totalPanelArea: Double, totalFabricArea: Double, efficiency: Double, requiredFabricLength: Double, oversizedPanels: [UUID], isEfficient: Bool, recommendations: [String]) {
        self.totalPanelArea = totalPanelArea
        self.totalFabricArea = totalFabricArea
        self.efficiency = efficiency
        self.requiredFabricLength = requiredFabricLength
        self.oversizedPanels = oversizedPanels
        self.isEfficient = isEfficient
        self.recommendations = recommendations
    }
}

/// Validation severity levels
@available(iOS 18.0, macOS 15.0, *)
public enum ValidationSeverity: String, Sendable, CaseIterable {
    case critical = "critical"
    case error = "error"
    case warning = "warning"
    case info = "info"
}

/// Validation issue types
@available(iOS 18.0, macOS 15.0, *)
public enum ValidationIssueType: String, Sendable, CaseIterable {
    case geometryError = "geometry"
    case seamAllowanceError = "seam_allowance"
    case sizeError = "size"
    case intersectionError = "intersection"
    case distortionError = "distortion"
    case grainLineError = "grain_line"
    case fabricCompatibilityError = "fabric_compatibility"
}

/// Validation warning types
@available(iOS 18.0, macOS 15.0, *)
public enum ValidationWarningType: String, Sendable, CaseIterable {
    case seamAllowanceWarning = "seam_allowance"
    case distortionWarning = "distortion"
    case efficiencyWarning = "efficiency"
    case optimizationWarning = "optimization"
}