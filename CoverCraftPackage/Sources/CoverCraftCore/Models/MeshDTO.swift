// Version: 1.0.0
// Data Transfer Object for mesh data across module boundaries

import Foundation
import simd

/// Immutable data transfer object representing mesh geometry
public struct MeshDTO: Codable, Sendable, Equatable {
    public let id: UUID
    public let vertices: [VertexDTO]
    public let triangleIndices: [UInt32]
    public let createdAt: Date
    
    public init(id: UUID, vertices: [VertexDTO], triangleIndices: [UInt32], createdAt: Date) {
        self.id = id
        self.vertices = vertices
        self.triangleIndices = triangleIndices
        self.createdAt = createdAt
    }
}

/// Immutable data transfer object for vertex data
public struct VertexDTO: Codable, Sendable, Equatable {
    public let position: SIMD3<Float>
    public let normal: SIMD3<Float>
    
    public init(position: SIMD3<Float>, normal: SIMD3<Float>) {
        self.position = position
        self.normal = normal
    }
}

/// Extension to make SIMD3<Float> Codable for DTO usage
extension SIMD3<Float>: Codable {
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let x = try container.decode(Float.self)
        let y = try container.decode(Float.self)
        let z = try container.decode(Float.self)
        self.init(x, y, z)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(x)
        try container.encode(y)
        try container.encode(z)
    }
}