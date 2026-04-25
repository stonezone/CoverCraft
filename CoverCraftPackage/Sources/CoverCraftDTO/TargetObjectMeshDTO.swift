// Version: 1.0.0
// CoverCraft DTO Module - Target Object Mesh Data Transfer Object

import Foundation
import simd

/// Stable 3D point representation for Codable mesh contracts.
@available(iOS 18.0, macOS 15.0, *)
public struct MeshPoint3DTO: Sendable, Codable, Equatable {

    // MARK: - Properties

    public let x: Float
    public let y: Float
    public let z: Float

    // MARK: - Initialization

    public init(x: Float, y: Float, z: Float) {
        self.x = x
        self.y = y
        self.z = z
    }

    public init(_ point: SIMD3<Float>) {
        self.init(x: point.x, y: point.y, z: point.z)
    }
}

/// Stable axis-aligned bounds representation for mesh contracts.
@available(iOS 18.0, macOS 15.0, *)
public struct MeshBoundsDTO: Sendable, Codable, Equatable {

    // MARK: - Properties

    public let min: MeshPoint3DTO
    public let max: MeshPoint3DTO

    // MARK: - Initialization

    public init(min: MeshPoint3DTO, max: MeshPoint3DTO) {
        self.min = min
        self.max = max
    }

    public init(min: SIMD3<Float>, max: SIMD3<Float>) {
        self.init(min: MeshPoint3DTO(min), max: MeshPoint3DTO(max))
    }
}

/// Stable audit entry describing one processing step applied to a target object mesh.
@available(iOS 18.0, macOS 15.0, *)
public struct TargetObjectMeshProcessingHistoryEntry: Sendable, Codable, Equatable {

    // MARK: - Properties

    /// Stable operation name, such as "segmentation" or "crop".
    public let operation: String

    /// Timestamp when this processing step was recorded.
    public let createdAt: Date

    /// Optional human-readable processing detail.
    public let notes: String?

    // MARK: - Initialization

    public init(
        operation: String,
        createdAt: Date = Date(),
        notes: String? = nil
    ) {
        self.operation = operation
        self.createdAt = createdAt
        self.notes = notes
    }
}

/// Immutable data transfer object representing the isolated target object mesh.
///
/// This DTO stores the valid isolated mesh, its derived object bounds, optional crop bounds,
/// and an immutable processing history.
@available(iOS 18.0, macOS 15.0, *)
public struct TargetObjectMeshDTO: Sendable, Codable, Equatable, Identifiable {

    // MARK: - Properties

    /// Unique identifier for this target object mesh.
    public let id: UUID

    /// Valid isolated mesh for the target object.
    public let isolatedMesh: MeshDTO

    /// Bounds derived from the isolated mesh vertices.
    public let objectBounds: MeshBoundsDTO

    /// Optional crop bounds used during target isolation.
    public let cropBounds: MeshBoundsDTO?

    /// Ordered processing history for this isolated mesh.
    public let processingHistory: [TargetObjectMeshProcessingHistoryEntry]

    /// Timestamp when this target object mesh was created.
    public let createdAt: Date

    /// Version of the target object mesh data format.
    public let version: String

    // MARK: - Computed Properties

    /// Whether the retained isolated mesh remains valid.
    public var isValid: Bool {
        isolatedMesh.isValid
    }

    // MARK: - Initialization

    /// Creates a new target object mesh DTO.
    /// - Parameters:
    ///   - isolatedMesh: Valid isolated target object mesh.
    ///   - cropBounds: Optional crop bounds used during isolation.
    ///   - processingHistory: Ordered processing history entries.
    ///   - id: Unique identifier.
    ///   - createdAt: Creation timestamp.
    public init(
        isolatedMesh: MeshDTO,
        cropBounds: MeshBoundsDTO? = nil,
        processingHistory: [TargetObjectMeshProcessingHistoryEntry] = [],
        id: UUID = UUID(),
        createdAt: Date = Date()
    ) throws {
        guard isolatedMesh.isValid else {
            throw ValidationError.invalidIsolatedMesh
        }
        guard let bounds = isolatedMesh.boundingBox() else {
            throw ValidationError.missingObjectBounds
        }

        self.id = id
        self.isolatedMesh = isolatedMesh
        self.objectBounds = MeshBoundsDTO(min: bounds.min, max: bounds.max)
        self.cropBounds = cropBounds
        self.processingHistory = processingHistory
        self.createdAt = createdAt
        self.version = "1.0.0"
    }

    // MARK: - Validation

    public enum ValidationError: Error, Equatable, LocalizedError {
        case invalidIsolatedMesh
        case missingObjectBounds
        case objectBoundsMismatch

        public var errorDescription: String? {
            switch self {
            case .invalidIsolatedMesh:
                "TargetObjectMeshDTO requires a valid isolated MeshDTO."
            case .missingObjectBounds:
                "TargetObjectMeshDTO requires mesh bounds derived from the isolated MeshDTO."
            case .objectBoundsMismatch:
                "TargetObjectMeshDTO objectBounds must match isolatedMesh.boundingBox()."
            }
        }
    }

    // MARK: - Codable Conformance

    private enum CodingKeys: String, CodingKey {
        case id
        case isolatedMesh
        case objectBounds
        case cropBounds
        case processingHistory
        case createdAt
        case version
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let isolatedMesh = try container.decode(MeshDTO.self, forKey: .isolatedMesh)

        guard isolatedMesh.isValid else {
            throw ValidationError.invalidIsolatedMesh
        }
        guard let bounds = isolatedMesh.boundingBox() else {
            throw ValidationError.missingObjectBounds
        }

        let objectBounds = try container.decode(MeshBoundsDTO.self, forKey: .objectBounds)
        let derivedBounds = MeshBoundsDTO(min: bounds.min, max: bounds.max)

        guard objectBounds == derivedBounds else {
            throw ValidationError.objectBoundsMismatch
        }

        self.id = try container.decode(UUID.self, forKey: .id)
        self.isolatedMesh = isolatedMesh
        self.objectBounds = objectBounds
        self.cropBounds = try container.decodeIfPresent(MeshBoundsDTO.self, forKey: .cropBounds)
        self.processingHistory = try container.decodeIfPresent(
            [TargetObjectMeshProcessingHistoryEntry].self,
            forKey: .processingHistory
        ) ?? []
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.version = try container.decodeIfPresent(String.self, forKey: .version) ?? "1.0.0"
    }
}
