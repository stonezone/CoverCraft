// Version: 1.0.0
// CoverCraft Core - Metrics Service

import Foundation
import Logging

/// Service for collecting application metrics and performance data
@available(iOS 18.0, macOS 15.0, *)
public final class MetricsService: @unchecked Sendable {
    
    public static let shared = MetricsService()
    
    private let logger = Logger(label: "CoverCraft.Metrics")
    
    // Performance metrics storage
    private var scanDurations: [TimeInterval] = []
    private var segmentationDurations: [TimeInterval] = []
    private var flatteningDurations: [TimeInterval] = []
    private var exportDurations: [String: [TimeInterval]] = [:]
    
    // Business metrics storage
    private var scansCompleted: Int = 0
    private var scanErrors: [String: Int] = [:]
    private var patternsGenerated: [String: Int] = [:]
    private var exportFailures: [String: Int] = [:]
    
    // Quality metrics storage
    private var meshTriangleCounts: [Int] = []
    private var panelCounts: [Int] = []
    private var patternAccuracies: [Double] = []
    
    private let queue = DispatchQueue(label: "com.covercraft.metrics", attributes: .concurrent)
    
    private init() {
        logger.info("Metrics service initialized")
    }
    
    // MARK: - Performance Metrics
    
    /// Record AR scanning duration
    public func recordScanDuration(_ duration: TimeInterval) {
        queue.async(flags: .barrier) {
            self.scanDurations.append(duration)
        }
        logger.debug("Recorded scan duration: \(duration)s")
    }
    
    /// Record mesh segmentation duration  
    public func recordSegmentationDuration(_ duration: TimeInterval) {
        queue.async(flags: .barrier) {
            self.segmentationDurations.append(duration)
        }
        logger.debug("Recorded segmentation duration: \(duration)s")
    }
    
    /// Record pattern flattening duration
    public func recordFlatteningDuration(_ duration: TimeInterval) {
        queue.async(flags: .barrier) {
            self.flatteningDurations.append(duration)
        }
        logger.debug("Recorded flattening duration: \(duration)s")
    }
    
    /// Record pattern export duration
    public func recordExportDuration(_ duration: TimeInterval, format: String) {
        queue.async(flags: .barrier) {
            if self.exportDurations[format] == nil {
                self.exportDurations[format] = []
            }
            self.exportDurations[format]?.append(duration)
        }
        logger.debug("Recorded export duration: \(duration)s for format: \(format)")
    }
    
    // MARK: - Business Metrics
    
    /// Record successful scan completion
    public func recordScanCompleted() {
        queue.async(flags: .barrier) {
            self.scansCompleted += 1
        }
        logger.debug("Recorded successful scan completion")
    }
    
    /// Record scan error
    public func recordScanError(type: String) {
        queue.async(flags: .barrier) {
            self.scanErrors[type, default: 0] += 1
        }
        logger.debug("Recorded scan error: \(type)")
    }
    
    /// Record pattern generation
    public func recordPatternGenerated(format: String) {
        queue.async(flags: .barrier) {
            self.patternsGenerated[format, default: 0] += 1
        }
        logger.debug("Recorded pattern generated: \(format)")
    }
    
    /// Record export failure
    public func recordExportFailure(format: String) {
        queue.async(flags: .barrier) {
            self.exportFailures[format, default: 0] += 1
        }
        logger.debug("Recorded export failure: \(format)")
    }
    
    // MARK: - Quality Metrics
    
    /// Record mesh quality metrics
    public func recordMeshQuality(triangleCount: Int) {
        queue.async(flags: .barrier) {
            self.meshTriangleCounts.append(triangleCount)
        }
        logger.debug("Recorded mesh triangle count: \(triangleCount)")
    }
    
    /// Record segmentation quality
    public func recordSegmentationQuality(panelCount: Int) {
        queue.async(flags: .barrier) {
            self.panelCounts.append(panelCount)
        }
        logger.debug("Recorded panel count: \(panelCount)")
    }
    
    /// Record pattern accuracy score
    public func recordPatternAccuracy(_ accuracy: Double) {
        queue.async(flags: .barrier) {
            self.patternAccuracies.append(accuracy)
        }
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
        return queue.sync {
            var summary: [String: Any] = [:]
            
            summary["scans_completed"] = scansCompleted
            summary["scan_errors"] = scanErrors
            summary["patterns_generated"] = patternsGenerated
            summary["export_failures"] = exportFailures
            
            if !scanDurations.isEmpty {
                summary["average_scan_duration"] = scanDurations.reduce(0, +) / Double(scanDurations.count)
            }
            
            if !meshTriangleCounts.isEmpty {
                summary["average_triangle_count"] = Double(meshTriangleCounts.reduce(0, +)) / Double(meshTriangleCounts.count)
            }
            
            if !patternAccuracies.isEmpty {
                summary["average_pattern_accuracy"] = patternAccuracies.reduce(0, +) / Double(patternAccuracies.count)
            }
            
            summary["service_status"] = "active"
            return summary
        }
    }
    
    // MARK: - Test Support
    
    /// Reset all metrics (for testing)
    internal func reset() {
        queue.async(flags: .barrier) {
            self.scanDurations.removeAll()
            self.segmentationDurations.removeAll()
            self.flatteningDurations.removeAll()
            self.exportDurations.removeAll()
            self.scansCompleted = 0
            self.scanErrors.removeAll()
            self.patternsGenerated.removeAll()
            self.exportFailures.removeAll()
            self.meshTriangleCounts.removeAll()
            self.panelCounts.removeAll()
            self.patternAccuracies.removeAll()
        }
    }
}

// MARK: - MetricsService Extensions for DI

@available(iOS 18.0, macOS 15.0, *)
extension MetricsService {
    /// Register metrics services with dependency container
    public static func register(in container: DependencyContainer) {
        container.register(MetricsService.shared, for: MetricsService.self)
    }
}