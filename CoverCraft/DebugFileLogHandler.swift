// Version: 1.0.0

import Foundation
import Logging

#if DEBUG
enum DebugFileLogging {
    static let relativeLogDirectory = "Library/Application Support/CoverCraftDebugLogs"
    static let relativeLogPath = "\(relativeLogDirectory)/CoverCraft-debug.log"

    private static let maxLogBytes: UInt64 = 5 * 1024 * 1024
    private static let lock = NSLock()

    static var logFileURL: URL {
        let containerURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return containerURL
            .appendingPathComponent("CoverCraftDebugLogs", isDirectory: true)
            .appendingPathComponent("CoverCraft-debug.log", isDirectory: false)
    }

    static func prepareSession() {
        lock.lock()
        defer { lock.unlock() }

        let fileURL = logFileURL
        let directoryURL = fileURL.deletingLastPathComponent()

        do {
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)

            if let size = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize,
               UInt64(size) > maxLogBytes {
                let rotatedURL = directoryURL.appendingPathComponent("CoverCraft-debug.previous.log")
                try? FileManager.default.removeItem(at: rotatedURL)
                try? FileManager.default.moveItem(at: fileURL, to: rotatedURL)
            }

            let header = "\n--- CoverCraft debug session \(timestamp()) ---\n"
            appendUnlocked(header, to: fileURL)
        } catch {
            // File logging is diagnostic only; the app should still launch if setup fails.
        }
    }

    static func append(_ line: String) {
        lock.lock()
        defer { lock.unlock() }
        appendUnlocked(line, to: logFileURL)
    }

    private static func appendUnlocked(_ line: String, to fileURL: URL) {
        guard let data = line.data(using: .utf8) else {
            return
        }

        if FileManager.default.fileExists(atPath: fileURL.path) {
            guard let fileHandle = try? FileHandle(forWritingTo: fileURL) else {
                return
            }
            defer { try? fileHandle.close() }
            _ = try? fileHandle.seekToEnd()
            try? fileHandle.write(contentsOf: data)
        } else {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    static func timestamp() -> String {
        ISO8601DateFormatter().string(from: Date())
    }
}

struct DebugFileLogHandler: LogHandler {
    let label: String
    var metadata: Logger.Metadata = [:]
    var metadataProvider: Logger.MetadataProvider? = LoggingSystem.metadataProvider
    var logLevel: Logger.Level = .debug

    subscript(metadataKey metadataKey: String) -> Logger.Metadata.Value? {
        get { metadata[metadataKey] }
        set { metadata[metadataKey] = newValue }
    }

    func log(event: LogEvent) {
        var mergedMetadata = metadata
        mergedMetadata.merge(metadataProvider?.get() ?? [:]) { _, provided in provided }
        mergedMetadata.merge(event.metadata ?? [:]) { _, explicit in explicit }
        if let error = event.error {
            mergedMetadata["error.message"] = "\(error)"
            mergedMetadata["error.type"] = "\(String(reflecting: type(of: error)))"
        }

        let metadataDescription = mergedMetadata.isEmpty ? "" : " \(mergedMetadata)"
        let sourceDescription = event.source.isEmpty ? label : event.source
        let fileName = URL(fileURLWithPath: event.file).lastPathComponent
        let logLine = "\(DebugFileLogging.timestamp()) \(event.level) \(label) \(sourceDescription) \(fileName):\(event.line) \(event.function) - \(event.message)\(metadataDescription)\n"

        DebugFileLogging.append(logLine)
    }
}
#endif
