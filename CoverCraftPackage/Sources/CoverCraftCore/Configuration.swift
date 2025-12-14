// CoverCraft Configuration
// Centralized configuration for all tunable parameters

import Foundation

/// Centralized configuration for CoverCraft tunable parameters
/// This consolidates magic numbers from across the codebase for easier maintenance
@available(iOS 18.0, macOS 15.0, *)
public struct CoverCraftConfiguration: Sendable {

    // MARK: - AR Scanning

    /// Maximum number of mesh anchors to process during scanning
    public var maxAnchorCount: Int = 150

    /// Scan quality thresholds
    public struct ScanQuality: Sendable {
        /// Vertex count thresholds for quality scoring
        public var poorVertexThreshold: Int = 5_000
        public var fairVertexThreshold: Int = 20_000
        public var goodVertexThreshold: Int = 50_000

        /// Triangle count for full score
        public var maxTrianglesForScore: Int = 100_000

        /// Anchor count for full score
        public var maxAnchorsForScore: Int = 50

        /// Quality score weights (must sum to 1.0)
        public var vertexWeight: Float = 0.5
        public var triangleWeight: Float = 0.3
        public var anchorWeight: Float = 0.2

        public static let `default` = ScanQuality()
    }
    public var scanQuality = ScanQuality.default

    // MARK: - Mesh Segmentation

    /// Maximum iterations for k-means clustering
    public var segmentationMaxIterations: Int = 50

    /// Convergence threshold for k-means
    public var segmentationConvergenceThreshold: Float = 1e-4

    // MARK: - Pattern Flattening

    /// Maximum iterations for LSCM algorithm
    public var flatteningMaxIterations: Int = 1000

    /// Scale units per meter for pattern output
    public var scaleUnitsPerMeter: Double = 1000.0

    /// Layout margin in points
    public var flatteningLayoutMargin: Double = 20.0

    // MARK: - Pattern Validation

    /// Standard seam allowance in millimeters
    public var standardSeamAllowanceMm: Double = 5.0

    /// Minimum panel area in square millimeters
    public var minimumPanelAreaMm2: Double = 100.0

    /// Minimum edge length in millimeters
    public var minimumEdgeLengthMm: Double = 10.0

    /// Maximum acceptable distortion factor
    public var maximumDistortionFactor: Double = 1.5

    // MARK: - Export

    /// DPI settings for different export formats
    public struct ExportDPI: Sendable {
        public var pdf: CGFloat = 72.0
        public var svg: CGFloat = 72.0
        public var png: CGFloat = 300.0
        public var gif: CGFloat = 150.0

        public static let `default` = ExportDPI()
    }
    public var exportDPI = ExportDPI.default

    /// Export margin in points (at 72 DPI)
    public var exportMarginPoints: CGFloat = 36.0

    /// Scale bar length representing 10cm at 72 DPI
    public var scaleBarLengthPoints: CGFloat = 283.46

    // MARK: - Calibration

    /// Minimum mesh space distance for valid calibration points
    public var minimumCalibrationDistance: Double = 0.001

    // MARK: - Input Validation

    /// Minimum dimension in millimeters
    public var minimumDimensionMm: Double = 10.0

    /// Maximum dimension in millimeters
    public var maximumDimensionMm: Double = 10_000.0

    /// Seam allowance range in millimeters
    public var seamAllowanceMinMm: Double = 3.0
    public var seamAllowanceMaxMm: Double = 50.0

    // MARK: - Default Instance

    public static let `default` = CoverCraftConfiguration()

    public init() {}
}

// MARK: - Global Access

@available(iOS 18.0, macOS 15.0, *)
public enum Configuration {
    /// The current configuration
    public static let current = CoverCraftConfiguration.default
}
