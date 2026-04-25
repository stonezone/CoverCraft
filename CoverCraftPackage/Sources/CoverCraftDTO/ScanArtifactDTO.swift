// Version: 1.0.0
// CoverCraft DTO Module - Scan Artifact Data Transfer Object

import Foundation

/// Stable source labels for captured or imported raw scan artifacts.
@available(iOS 18.0, macOS 15.0, *)
public enum ScanArtifactSource: String, Sendable, Codable, Equatable {
    case lidar
    case photogrammetry
    case imported
    case manual
    case unknown
}

/// Stable tracking quality labels captured with a raw scan artifact.
@available(iOS 18.0, macOS 15.0, *)
public enum ScanTrackingQuality: String, Sendable, Codable, Equatable {
    case normal
    case limited
    case unavailable
    case unknown
}

/// Immutable data transfer object representing the raw mesh captured during scanning.
///
/// This DTO retains capture provenance alongside the unmodified raw mesh.
/// Breaking changes require a version bump and migration path.
@available(iOS 18.0, macOS 15.0, *)
public struct ScanArtifactDTO: Sendable, Codable, Equatable, Identifiable {

    // MARK: - Properties

    /// Unique identifier for this scan artifact.
    public let id: UUID

    /// Valid raw mesh captured or imported for downstream processing.
    public let rawMesh: MeshDTO

    /// Capture or import source for the raw mesh.
    public let source: ScanArtifactSource

    /// Timestamp when this scan artifact was created.
    public let createdAt: Date

    /// Optional device model that produced the capture.
    public let deviceModel: String?

    /// Optional tracking quality reported during capture.
    public let trackingQuality: ScanTrackingQuality?

    /// Version of the scan artifact data format.
    public let version: String

    // MARK: - Initialization

    /// Creates a new scan artifact DTO.
    /// - Parameters:
    ///   - rawMesh: Valid raw mesh to retain.
    ///   - source: Capture or import source.
    ///   - id: Unique identifier.
    ///   - createdAt: Creation timestamp.
    ///   - deviceModel: Optional capture device model.
    ///   - trackingQuality: Optional capture tracking quality.
    public init(
        rawMesh: MeshDTO,
        source: ScanArtifactSource,
        id: UUID = UUID(),
        createdAt: Date = Date(),
        deviceModel: String? = nil,
        trackingQuality: ScanTrackingQuality? = nil
    ) throws {
        guard rawMesh.isValid else {
            throw ValidationError.invalidRawMesh
        }

        self.id = id
        self.rawMesh = rawMesh
        self.source = source
        self.createdAt = createdAt
        self.deviceModel = deviceModel
        self.trackingQuality = trackingQuality
        self.version = "1.0.0"
    }

    // MARK: - Validation

    public enum ValidationError: Error, Equatable, LocalizedError {
        case invalidRawMesh

        public var errorDescription: String? {
            switch self {
            case .invalidRawMesh:
                "ScanArtifactDTO requires a valid raw MeshDTO."
            }
        }
    }

    // MARK: - Codable Conformance

    private enum CodingKeys: String, CodingKey {
        case id
        case rawMesh
        case source
        case createdAt
        case deviceModel
        case trackingQuality
        case version
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let rawMesh = try container.decode(MeshDTO.self, forKey: .rawMesh)

        guard rawMesh.isValid else {
            throw ValidationError.invalidRawMesh
        }

        self.id = try container.decode(UUID.self, forKey: .id)
        self.rawMesh = rawMesh
        self.source = try container.decode(ScanArtifactSource.self, forKey: .source)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.deviceModel = try container.decodeIfPresent(String.self, forKey: .deviceModel)
        self.trackingQuality = try container.decodeIfPresent(ScanTrackingQuality.self, forKey: .trackingQuality)
        self.version = try container.decodeIfPresent(String.self, forKey: .version) ?? "1.0.0"
    }
}
