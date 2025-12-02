// Version: 1.0.0
// CoverCraft DTO Module - Mesh Data Transfer Object

import Foundation
import simd

/// Immutable data transfer object representing a 3D mesh
/// 
/// This DTO is designed for stable serialization and transfer between modules.
/// Breaking changes require a version bump and migration path.
@available(iOS 18.0, macOS 15.0, *)
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

@available(iOS 18.0, macOS 15.0, *)
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

// MARK: - Boundary Detection

/// Represents an edge in the mesh (pair of vertex indices, order-independent)
public struct MeshEdge: Hashable, Sendable {
    public let v0: Int
    public let v1: Int

    public init(_ a: Int, _ b: Int) {
        // Store in canonical order for consistent hashing
        self.v0 = min(a, b)
        self.v1 = max(a, b)
    }
}

/// Information about mesh boundaries and holes
@available(iOS 18.0, macOS 15.0, *)
public struct MeshBoundaryInfo: Sendable {
    /// All boundary edges (edges with only 1 adjacent triangle)
    public let boundaryEdges: [MeshEdge]

    /// Boundary loops (chains of connected boundary edges forming holes)
    public let boundaryLoops: [[Int]]

    /// Number of holes in the mesh
    public var holeCount: Int { boundaryLoops.count }

    /// Whether the mesh is watertight (no holes)
    public var isWatertight: Bool { boundaryEdges.isEmpty }

    /// Total length of all boundary edges
    public let totalBoundaryLength: Float

    /// Average hole size (number of edges per loop)
    public var averageHoleSize: Float {
        guard !boundaryLoops.isEmpty else { return 0 }
        let total = boundaryLoops.reduce(0) { $0 + $1.count }
        return Float(total) / Float(boundaryLoops.count)
    }
}

@available(iOS 18.0, macOS 15.0, *)
public extension MeshDTO {

    /// Analyze mesh boundaries to find holes
    /// - Returns: Information about boundary edges and loops
    func analyzeBoundaries() -> MeshBoundaryInfo {
        // Step 1: Count how many triangles each edge belongs to
        var edgeTriangleCount: [MeshEdge: Int] = [:]

        for i in stride(from: 0, to: triangleIndices.count, by: 3) {
            let v0 = triangleIndices[i]
            let v1 = triangleIndices[i + 1]
            let v2 = triangleIndices[i + 2]

            let e0 = MeshEdge(v0, v1)
            let e1 = MeshEdge(v1, v2)
            let e2 = MeshEdge(v2, v0)

            edgeTriangleCount[e0, default: 0] += 1
            edgeTriangleCount[e1, default: 0] += 1
            edgeTriangleCount[e2, default: 0] += 1
        }

        // Step 2: Find boundary edges (count == 1)
        let boundaryEdges = edgeTriangleCount.compactMap { edge, count -> MeshEdge? in
            count == 1 ? edge : nil
        }

        // Step 3: Calculate total boundary length
        var totalLength: Float = 0
        for edge in boundaryEdges {
            let p0 = vertices[edge.v0]
            let p1 = vertices[edge.v1]
            totalLength += simd_length(p1 - p0)
        }

        // Step 4: Chain boundary edges into loops
        let loops = chainBoundaryEdges(boundaryEdges)

        return MeshBoundaryInfo(
            boundaryEdges: boundaryEdges,
            boundaryLoops: loops,
            totalBoundaryLength: totalLength
        )
    }

    /// Chain boundary edges into connected loops
    private func chainBoundaryEdges(_ edges: [MeshEdge]) -> [[Int]] {
        guard !edges.isEmpty else { return [] }

        // Build adjacency: vertex -> [connected boundary vertices]
        var adjacency: [Int: Set<Int>] = [:]
        for edge in edges {
            adjacency[edge.v0, default: []].insert(edge.v1)
            adjacency[edge.v1, default: []].insert(edge.v0)
        }

        var visited: Set<Int> = []
        var loops: [[Int]] = []

        // Find all loops by walking from unvisited boundary vertices
        for startVertex in adjacency.keys {
            if visited.contains(startVertex) { continue }

            var loop: [Int] = []
            var current = startVertex
            var previous: Int? = nil

            // Walk the boundary loop
            while true {
                loop.append(current)
                visited.insert(current)

                // Find next unvisited neighbor (or loop back to start)
                guard let neighbors = adjacency[current] else { break }

                var next: Int? = nil
                for neighbor in neighbors {
                    if neighbor == previous { continue }
                    if neighbor == startVertex && loop.count > 2 {
                        // Completed the loop
                        loops.append(loop)
                        next = nil
                        break
                    }
                    if !visited.contains(neighbor) {
                        next = neighbor
                        break
                    }
                }

                if let nextVertex = next {
                    previous = current
                    current = nextVertex
                } else {
                    // Either completed loop or dead end
                    if loop.count > 2 && neighbors.contains(startVertex) {
                        loops.append(loop)
                    }
                    break
                }
            }
        }

        return loops
    }

    /// Get vertices forming a specific boundary loop
    func boundaryLoopVertices(loop: [Int]) -> [SIMD3<Float>] {
        loop.map { vertices[$0] }
    }
}

// MARK: - Mesh Processing

@available(iOS 18.0, macOS 15.0, *)
public extension MeshDTO {

    /// Process the mesh with the given options
    func processed(with options: MeshProcessingOptions) -> MeshProcessingResult {
        var currentMesh = self
        var holesFilled = 0
        var trianglesCropped = 0
        var componentsRemoved = 0
        let originalCount = triangleCount

        // Step 1: Connected component isolation (do first to reduce work for other steps)
        if options.enableComponentIsolation {
            let (isolatedMesh, removed) = currentMesh.isolateLargestComponent(
                minTriangles: options.minComponentTriangles
            )
            currentMesh = isolatedMesh
            componentsRemoved = removed
        }

        // Step 2: Plane-based cropping
        if options.enablePlaneCropping {
            let (croppedMesh, cropped) = currentMesh.cropByPlane(
                heightFraction: options.cropPlaneHeightFraction,
                direction: options.cropDirection
            )
            currentMesh = croppedMesh
            trianglesCropped = cropped
        }

        // Step 3: Hole filling
        if options.enableHoleFilling {
            let (filledMesh, filled) = currentMesh.fillSmallHoles(
                maxEdges: options.maxHoleEdges
            )
            currentMesh = filledMesh
            holesFilled = filled
        }

        return MeshProcessingResult(
            mesh: currentMesh,
            holesFilled: holesFilled,
            trianglesCropped: trianglesCropped,
            componentsRemoved: componentsRemoved,
            originalTriangleCount: originalCount,
            finalTriangleCount: currentMesh.triangleCount
        )
    }

    // MARK: - Connected Component Isolation

    /// Find and keep only the largest connected component
    /// - Parameter minTriangles: Minimum triangles for a component to be kept
    /// - Returns: Tuple of (processed mesh, number of components removed)
    func isolateLargestComponent(minTriangles: Int) -> (MeshDTO, Int) {
        guard triangleCount > 0 else { return (self, 0) }

        // Build triangle adjacency via shared edges
        var triangleNeighbors: [[Int]] = Array(repeating: [], count: triangleCount)
        var edgeToTriangles: [MeshEdge: [Int]] = [:]

        // Map edges to triangles
        for triIdx in 0..<triangleCount {
            let baseIdx = triIdx * 3
            let v0 = triangleIndices[baseIdx]
            let v1 = triangleIndices[baseIdx + 1]
            let v2 = triangleIndices[baseIdx + 2]

            let edges = [MeshEdge(v0, v1), MeshEdge(v1, v2), MeshEdge(v2, v0)]
            for edge in edges {
                edgeToTriangles[edge, default: []].append(triIdx)
            }
        }

        // Build adjacency from shared edges
        for (_, triangles) in edgeToTriangles {
            if triangles.count == 2 {
                triangleNeighbors[triangles[0]].append(triangles[1])
                triangleNeighbors[triangles[1]].append(triangles[0])
            }
        }

        // Find connected components using BFS
        var visited = Set<Int>()
        var components: [[Int]] = []

        for startTri in 0..<triangleCount {
            if visited.contains(startTri) { continue }

            var component: [Int] = []
            var queue: [Int] = [startTri]

            while !queue.isEmpty {
                let tri = queue.removeFirst()
                if visited.contains(tri) { continue }

                visited.insert(tri)
                component.append(tri)

                for neighbor in triangleNeighbors[tri] {
                    if !visited.contains(neighbor) {
                        queue.append(neighbor)
                    }
                }
            }

            components.append(component)
        }

        // Find largest component
        guard let largestComponent = components.max(by: { $0.count < $1.count }) else {
            return (self, 0)
        }

        // Also keep any components above minTriangles threshold
        let componentsToKeep = components.filter { $0.count >= minTriangles || $0 == largestComponent }
        let trianglesToKeep = Set(componentsToKeep.flatMap { $0 })

        // Build new mesh with only kept triangles
        let (newMesh, _) = buildMeshFromTriangles(trianglesToKeep)
        let removed = components.count - componentsToKeep.count

        return (newMesh, removed)
    }

    // MARK: - Plane-Based Cropping

    /// Crop triangles below/above a horizontal plane
    /// - Parameters:
    ///   - heightFraction: Height of cutting plane as fraction of mesh height (0-1)
    ///   - direction: Whether to remove geometry below or above the plane
    /// - Returns: Tuple of (cropped mesh, number of triangles removed)
    func cropByPlane(heightFraction: Float, direction: CropDirection) -> (MeshDTO, Int) {
        guard let bounds = boundingBox() else { return (self, 0) }

        let meshHeight = bounds.max.y - bounds.min.y
        let planeY = bounds.min.y + (meshHeight * heightFraction)

        var trianglesToKeep = Set<Int>()

        for triIdx in 0..<triangleCount {
            let baseIdx = triIdx * 3
            let v0 = vertices[triangleIndices[baseIdx]]
            let v1 = vertices[triangleIndices[baseIdx + 1]]
            let v2 = vertices[triangleIndices[baseIdx + 2]]

            // Use centroid for decision
            let centroidY = (v0.y + v1.y + v2.y) / 3.0

            let keep: Bool
            switch direction {
            case .below:
                keep = centroidY >= planeY
            case .above:
                keep = centroidY <= planeY
            }

            if keep {
                trianglesToKeep.insert(triIdx)
            }
        }

        let (newMesh, _) = buildMeshFromTriangles(trianglesToKeep)
        let removed = triangleCount - newMesh.triangleCount

        return (newMesh, removed)
    }

    // MARK: - Hole Filling

    /// Fill small holes using centroid fan triangulation
    /// - Parameter maxEdges: Maximum edges in a hole to fill
    /// - Returns: Tuple of (filled mesh, number of holes filled)
    func fillSmallHoles(maxEdges: Int) -> (MeshDTO, Int) {
        let boundaryInfo = analyzeBoundaries()

        // Filter to small holes only
        let smallHoles = boundaryInfo.boundaryLoops.filter { $0.count <= maxEdges && $0.count >= 3 }

        guard !smallHoles.isEmpty else { return (self, 0) }

        var newVertices = vertices
        var newIndices = triangleIndices

        for hole in smallHoles {
            // Compute centroid of hole
            var centroid = SIMD3<Float>(0, 0, 0)
            for vertexIdx in hole {
                centroid += vertices[vertexIdx]
            }
            centroid /= Float(hole.count)

            // Add centroid as new vertex
            let centroidIdx = newVertices.count
            newVertices.append(centroid)

            // Create fan triangles from centroid to each edge
            for i in 0..<hole.count {
                let v0 = hole[i]
                let v1 = hole[(i + 1) % hole.count]

                // Triangle: centroid -> v0 -> v1 (winding order matters)
                newIndices.append(contentsOf: [centroidIdx, v0, v1])
            }
        }

        let newMesh = MeshDTO(
            vertices: newVertices,
            triangleIndices: newIndices,
            id: UUID(),
            createdAt: Date()
        )

        return (newMesh, smallHoles.count)
    }

    // MARK: - Helper Methods

    /// Build a new mesh from a subset of triangles
    private func buildMeshFromTriangles(_ triangleSet: Set<Int>) -> (MeshDTO, [Int: Int]) {
        // Collect used vertices
        var usedVertices = Set<Int>()
        for triIdx in triangleSet {
            let baseIdx = triIdx * 3
            usedVertices.insert(triangleIndices[baseIdx])
            usedVertices.insert(triangleIndices[baseIdx + 1])
            usedVertices.insert(triangleIndices[baseIdx + 2])
        }

        // Create vertex remapping
        let sortedVertices = usedVertices.sorted()
        var oldToNew: [Int: Int] = [:]
        for (newIdx, oldIdx) in sortedVertices.enumerated() {
            oldToNew[oldIdx] = newIdx
        }

        // Build new vertex array
        let newVertices = sortedVertices.map { vertices[$0] }

        // Build new index array with remapped indices
        var newIndices: [Int] = []
        for triIdx in triangleSet.sorted() {
            let baseIdx = triIdx * 3
            let v0 = oldToNew[triangleIndices[baseIdx]]!
            let v1 = oldToNew[triangleIndices[baseIdx + 1]]!
            let v2 = oldToNew[triangleIndices[baseIdx + 2]]!
            newIndices.append(contentsOf: [v0, v1, v2])
        }

        let newMesh = MeshDTO(
            vertices: newVertices,
            triangleIndices: newIndices,
            id: UUID(),
            createdAt: Date()
        )

        return (newMesh, oldToNew)
    }
}