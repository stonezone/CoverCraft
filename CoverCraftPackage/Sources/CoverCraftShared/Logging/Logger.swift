import Foundation
import os

/// Centralized logging for CoverCraft subsystems
public enum Log {
    /// AR scanning and mesh capture
    public static let ar = Logger(subsystem: "com.covercraft", category: "ar.scan")
    
    /// Mesh segmentation operations
    public static let segmentation = Logger(subsystem: "com.covercraft", category: "mesh.segmentation")
    
    /// Pattern flattening operations
    public static let flattening = Logger(subsystem: "com.covercraft", category: "pattern.flattening")
    
    /// Export operations
    public static let export = Logger(subsystem: "com.covercraft", category: "export")
    
    /// Calibration operations
    public static let calibration = Logger(subsystem: "com.covercraft", category: "calibration")
    
    /// UI interactions
    public static let ui = Logger(subsystem: "com.covercraft", category: "ui")
}

/// Performance monitoring helpers
public extension Logger {
    func measureTime<T>(
        operation: String,
        _ block: () async throws -> T
    ) async rethrows -> T {
        let start = CFAbsoluteTimeGetCurrent()
        defer {
            let elapsed = CFAbsoluteTimeGetCurrent() - start
            self.info("\(operation) completed in \(elapsed, format: .fixed(precision: 3))s")
        }
        return try await block()
    }
}