// Version: 1.0.0
// CoverCraft DTO Module - Mesh Data Transfer Object

import Foundation
import simd

/// Immutable data transfer object representing a 3D mesh
/// 
/// This DTO is designed for stable serialization and transfer between modules.
/// Breaking changes require a version bump and migration path.
@available(iOS 18.0, *)
public struct MeshDTO: Sendable, Codable, Equatable {
    
    // MARK: - Properties
    
    /// Array of 3D vertex positions
    public let vertices: [SIMD3<Float>]
    
    /// Array of triangle indices (groups of 3 indices into vertices array)
    public let triangleIndices: [Int]
    
    /// Unique identifier for this mesh
    public let id: UUID
    
    /// Timestamp when this mesh was created
    public let createdAt: Date
    
    /// Version of the mesh data format
    public let version: String
    
    // MARK: - Computed Properties
    
    /// Number of triangles in this mesh
    public var triangleCount: Int {
        triangleIndices.count / 3
    }
    
    /// Whether this mesh is valid (has vertices and properly indexed triangles)
    public var isValid: Bool {
        !vertices.isEmpty && 
        !triangleIndices.isEmpty && 
        triangleIndices.count % 3 == 0 &&
        triangleIndices.allSatisfy { $0 >= 0 && $0 < vertices.count }
    }
    
    // MARK: - Initialization
    
    /// Creates a new mesh DTO
    /// - Parameters:
    ///   - vertices: Array of 3D vertex positions
    ///   - triangleIndices: Array of triangle indices
    ///   - id: Unique identifier (defaults to new UUID)
    ///   - createdAt: Creation timestamp (defaults to now)
    public init(
        vertices: [SIMD3<Float>],
        triangleIndices: [Int],
        id: UUID = UUID(),
        createdAt: Date = Date()
    ) {
        self.vertices = vertices
        self.triangleIndices = triangleIndices  
        self.id = id
        self.createdAt = createdAt
        self.version = "1.0.0"
    }
    
    // MARK: - Codable Conformance
    
    private enum CodingKeys: String, CodingKey {
        case vertices
        case triangleIndices
        case id
        case createdAt
        case version
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode vertices as array of [Float] and convert to SIMD3<Float>
        let vertexArrays = try container.decode([[Float]].self, forKey: .vertices)
        self.vertices = try vertexArrays.map { array in
            guard array.count == 3 else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription: "Vertex must have exactly 3 components"
                    )
                )
            }
            return SIMD3<Float>(array[0], array[1], array[2])
        }
        
        self.triangleIndices = try container.decode([Int].self, forKey: .triangleIndices)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.version = try container.decodeIfPresent(String.self, forKey: .version) ?? "1.0.0"
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // Encode SIMD3<Float> as arrays of Float
        let vertexArrays = vertices.map { [$0.x, $0.y, $0.z] }
        try container.encode(vertexArrays, forKey: .vertices)
        try container.encode(triangleIndices, forKey: .triangleIndices)
        try container.encode(id, forKey: .id)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(version, forKey: .version)
    }
}

// MARK: - Helper Methods

@available(iOS 18.0, *)
public extension MeshDTO {
    
    /// Create a scaled copy of this mesh
    /// - Parameter scaleFactor: Factor to scale all vertices by
    /// - Returns: New MeshDTO with scaled vertices
    func scaled(by scaleFactor: Float) -> MeshDTO {
        let scaledVertices = vertices.map { $0 * scaleFactor }
        return MeshDTO(
            vertices: scaledVertices,
            triangleIndices: triangleIndices,
            id: UUID(), // New ID for scaled version
            createdAt: Date()
        )
    }
    
    /// Calculate the bounding box of this mesh
    /// - Returns: Tuple of (min, max) points of bounding box
    func boundingBox() -> (min: SIMD3<Float>, max: SIMD3<Float>)? {
        guard !vertices.isEmpty else { return nil }
        
        var minPoint = vertices[0]
        var maxPoint = vertices[0]
        
        for vertex in vertices.dropFirst() {
            minPoint = simd_min(minPoint, vertex)
            maxPoint = simd_max(maxPoint, vertex)
        }
        
        return (min: minPoint, max: maxPoint)
    }
}