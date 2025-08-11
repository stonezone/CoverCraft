// Version: 1.0.0
// CoverCraft Core - Metrics Service

import Foundation
import Logging
import Metrics

/// Service for collecting application metrics and performance data
@available(iOS 18.0, *)
public final class MetricsService: @unchecked Sendable {
    
    public static let shared = MetricsService()
    
    private let logger = Logger(label: "CoverCraft.Metrics")
    
    // Performance metrics
    private let scanDurationTimer = Timer(label: "covercraft_scan_duration", dimensions: [("component", "ar_scanning")])
    private let segmentationDurationTimer = Timer(label: "covercraft_segmentation_duration", dimensions: [("component", "mesh_processing")])
    private let flatteningDurationTimer = Timer(label: "covercraft_flattening_duration", dimensions: [("component", "pattern_flattening")])
    private let exportDurationTimer = Timer(label: "covercraft_export_duration", dimensions: [("component", "pattern_export")])
    
    // Business metrics
    private let scansCompleted = Counter(label: "covercraft_scans_completed", dimensions: [("status", "success")])
    private let scansErrors = Counter(label: "covercraft_scans_errors", dimensions: [("error_type", "unknown")])
    private let patternsGenerated = Counter(label: "covercraft_patterns_generated", dimensions: [("format", "unknown")])
    private let exportFailures = Counter(label: "covercraft_export_failures", dimensions: [("format", "unknown")])
    
    // Quality metrics
    private let meshTriangleCount = Histogram(label: "covercraft_mesh_triangle_count", buckets: [100, 500, 1000, 5000, 10000, 50000])
    private let panelCount = Histogram(label: "covercraft_panel_count", buckets: [1, 2, 5, 10, 20, 50])
    private let patternAccuracy = Histogram(label: "covercraft_pattern_accuracy", buckets: [0.5, 0.7, 0.8, 0.9, 0.95, 0.99])
    
    private init() {
        logger.info("Metrics service initialized")
    }
    
    // MARK: - Performance Metrics
    
    /// Record AR scanning duration
    public func recordScanDuration(_ duration: TimeInterval) {
        scanDurationTimer.recordSeconds(duration)
        logger.debug("Recorded scan duration: \(duration)s")
    }
    
    /// Record mesh segmentation duration  
    public func recordSegmentationDuration(_ duration: TimeInterval) {
        segmentationDurationTimer.recordSeconds(duration)
        logger.debug("Recorded segmentation duration: \(duration)s")
    }
    
    /// Record pattern flattening duration
    public func recordFlatteningDuration(_ duration: TimeInterval) {
        flatteningDurationTimer.recordSeconds(duration)
        logger.debug("Recorded flattening duration: \(duration)s")
    }
    
    /// Record pattern export duration
    public func recordExportDuration(_ duration: TimeInterval, format: String) {
        exportDurationTimer.record(duration, dimensions: [("format", format)])
        logger.debug("Recorded export duration: \(duration)s for format: \(format)")
    }
    
    // MARK: - Business Metrics
    
    /// Record successful scan completion
    public func recordScanCompleted() {
        scansCompleted.increment(dimensions: [("status", "success")])
        logger.debug("Recorded successful scan completion")
    }
    
    /// Record scan error
    public func recordScanError(type: String) {
        scansErrors.increment(dimensions: [("error_type", type)])
        logger.debug("Recorded scan error: \(type)")
    }
    
    /// Record pattern generation
    public func recordPatternGenerated(format: String) {
        patternsGenerated.increment(dimensions: [("format", format)])
        logger.debug("Recorded pattern generated: \(format)")
    }
    
    /// Record export failure
    public func recordExportFailure(format: String) {
        exportFailures.increment(dimensions: [("format", format)])
        logger.debug("Recorded export failure: \(format)")
    }
    
    // MARK: - Quality Metrics
    
    /// Record mesh quality metrics
    public func recordMeshQuality(triangleCount: Int) {
        meshTriangleCount.record(Double(triangleCount))
        logger.debug("Recorded mesh triangle count: \(triangleCount)")
    }
    
    /// Record segmentation quality
    public func recordSegmentationQuality(panelCount: Int) {
        self.panelCount.record(Double(panelCount))
        logger.debug("Recorded panel count: \(panelCount)")
    }
    
    /// Record pattern accuracy score
    public func recordPatternAccuracy(_ accuracy: Double) {
        patternAccuracy.record(accuracy)
        logger.debug("Recorded pattern accuracy: \(accuracy)")
    }
    
    // MARK: - Utility Methods
    
    /// Time a code block and record the duration
    public func time<T>(_ label: String, _ block: () throws -> T) rethrows -> T {
        let start = DispatchTime.now()
        defer {
            let end = DispatchTime.now()
            let duration = Double(end.uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000_000
            
            switch label {
            case "scan":
                recordScanDuration(duration)
            case "segmentation":
                recordSegmentationDuration(duration)
            case "flattening":
                recordFlatteningDuration(duration)
            default:
                logger.debug("Timed operation '\(label)': \(duration)s")
            }
        }
        return try block()
    }
    
    /// Time an async code block and record the duration
    public func timeAsync<T>(_ label: String, _ block: () async throws -> T) async rethrows -> T {
        let start = DispatchTime.now()
        defer {
            let end = DispatchTime.now()
            let duration = Double(end.uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000_000
            
            switch label {
            case "scan":
                recordScanDuration(duration)
            case "segmentation":
                recordSegmentationDuration(duration)
            case "flattening":
                recordFlatteningDuration(duration)
            default:
                logger.debug("Timed async operation '\(label)': \(duration)s")
            }
        }
        return try await block()
    }
    
    /// Get current metrics summary
    public func getMetricsSummary() -> [String: Any] {
        return [
            "scans_completed": "Available via metrics endpoint",
            "average_scan_duration": "Available via metrics endpoint", 
            "patterns_generated": "Available via metrics endpoint",
            "service_status": "active"
        ]
    }
}

// MARK: - MetricsService Extensions for DI

extension MetricsService {
    /// Register metrics services with dependency container
    public static func register(in container: DependencyContainer) {
        container.register(MetricsService.shared, for: MetricsService.self)
    }
}