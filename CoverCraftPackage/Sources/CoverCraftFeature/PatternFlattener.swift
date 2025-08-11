import Foundation
import simd
import CoreGraphics

/// Service responsible for flattening 3D panels to 2D patterns
public actor PatternFlattener: PatternFlattenerProtocol {
    
    public init() {}
    
    public func flattenPanels(_ panels: [Panel], from mesh: Mesh) async throws -> [FlattenedPanel] {
        var flattenedPanels: [FlattenedPanel] = []
        
        for panel in panels {
            let flattened = try await flattenPanel(panel, mesh: mesh)
            flattenedPanels.append(flattened)
        }
        
        return flattenedPanels
    }
    
    private func flattenPanel(_ panel: Panel, mesh: Mesh) async throws -> FlattenedPanel {
        // Get vertices for this panel
        let panelVertices = Array(panel.vertexIndices).map { mesh.vertices[$0] }
        
        guard !panelVertices.isEmpty else {
            throw FlatteningError.emptyPanel
        }
        
        // Step 1: Find best projection plane
        let projectionPlane = findBestProjectionPlane(vertices: panelVertices, panel: panel, mesh: mesh)
        
        // Step 2: Project vertices to 2D
        var points2D = projectToPlane(vertices: panelVertices, plane: projectionPlane)
        
        // Step 3: Build edge list
        let edges = buildEdgeList(panel: panel, mesh: mesh)
        
        // Step 4: Apply spring relaxation to preserve edge lengths
        points2D = applySpringRelaxation(
            points: points2D,
            edges: edges,
            originalVertices: panelVertices,
            iterations: 200
        )
        
        // Convert to CGPoint
        let cgPoints = points2D.map { CGPoint(x: CGFloat($0.x), y: CGFloat($0.y)) }
        
        // Build edge indices
        let vertexIndexMap = Dictionary(uniqueKeysWithValues: 
            panel.vertexIndices.enumerated().map { ($1, $0) })
        
        var edgeIndices: [(Int, Int)] = []
        for (v1, v2, _) in edges {
            if let i1 = vertexIndexMap[v1], let i2 = vertexIndexMap[v2] {
                edgeIndices.append((i1, i2))
            }
        }
        
        return FlattenedPanel(
            points2D: cgPoints,
            sourcePanel: panel,
            edges: edgeIndices
        )
    }
    
    private func findBestProjectionPlane(vertices: [SIMD3<Float>], panel: Panel, mesh: Mesh) -> ProjectionPlane {
        // Compute average normal from panel faces
        var averageNormal = SIMD3<Float>(0, 0, 0)
        var faceCount = 0
        
        for i in stride(from: 0, to: panel.triangleIndices.count, by: 3) {
            let v1 = mesh.vertices[panel.triangleIndices[i]]
            let v2 = mesh.vertices[panel.triangleIndices[i + 1]]
            let v3 = mesh.vertices[panel.triangleIndices[i + 2]]
            
            let edge1 = v2 - v1
            let edge2 = v3 - v1
            let normal = simd_cross(edge1, edge2)
            
            if simd_length(normal) > 0.0001 {
                averageNormal += simd_normalize(normal)
                faceCount += 1
            }
        }
        
        if faceCount > 0 {
            averageNormal = simd_normalize(averageNormal)
        } else {
            averageNormal = SIMD3<Float>(0, 0, 1)
        }
        
        // Compute center point
        let center = vertices.reduce(SIMD3<Float>(0, 0, 0), +) / Float(max(1, vertices.count))
        
        // Create orthonormal basis
        var tangent = SIMD3<Float>(1, 0, 0)
        if abs(simd_dot(tangent, averageNormal)) > 0.9 {
            tangent = SIMD3<Float>(0, 1, 0)
        }
        
        let bitangent = simd_normalize(simd_cross(averageNormal, tangent))
        tangent = simd_normalize(simd_cross(bitangent, averageNormal))
        
        return ProjectionPlane(
            origin: center,
            tangent: tangent,
            bitangent: bitangent,
            normal: averageNormal
        )
    }
    
    private func projectToPlane(vertices: [SIMD3<Float>], plane: ProjectionPlane) -> [SIMD2<Float>] {
        return vertices.map { vertex in
            let relative = vertex - plane.origin
            let x = simd_dot(relative, plane.tangent)
            let y = simd_dot(relative, plane.bitangent)
            return SIMD2<Float>(x, y)
        }
    }
    
    private func buildEdgeList(panel: Panel, mesh: Mesh) -> [(Int, Int, Float)] {
        var edges: Set<EdgeWithLength> = []
        let vertexArray = Array(panel.vertexIndices)
        let vertexIndexMap = Dictionary(uniqueKeysWithValues: vertexArray.enumerated().map { ($1, $0) })
        
        // Extract edges from triangles
        for i in stride(from: 0, to: panel.triangleIndices.count, by: 3) {
            let v1 = panel.triangleIndices[i]
            let v2 = panel.triangleIndices[i + 1]
            let v3 = panel.triangleIndices[i + 2]
            
            let length12 = simd_distance(mesh.vertices[v1], mesh.vertices[v2])
            let length23 = simd_distance(mesh.vertices[v2], mesh.vertices[v3])
            let length31 = simd_distance(mesh.vertices[v3], mesh.vertices[v1])
            
            edges.insert(EdgeWithLength(v1, v2, length12))
            edges.insert(EdgeWithLength(v2, v3, length23))
            edges.insert(EdgeWithLength(v3, v1, length31))
        }
        
        return edges.map { ($0.vertex1, $0.vertex2, $0.length) }
    }
    
    private func applySpringRelaxation(
        points: [SIMD2<Float>],
        edges: [(Int, Int, Float)],
        originalVertices: [SIMD3<Float>],
        iterations: Int
    ) -> [SIMD2<Float>] {
        var relaxedPoints = points
        let springConstant: Float = 0.5
        let damping: Float = 0.95
        
        // Fix first two points to prevent rotation/translation
        guard relaxedPoints.count >= 2 else { return relaxedPoints }
        
        for _ in 0..<iterations {
            var forces = Array(repeating: SIMD2<Float>(0, 0), count: relaxedPoints.count)
            
            // Calculate spring forces for each edge
            for (v1Index, v2Index, targetLength) in edges {
                guard v1Index < relaxedPoints.count && v2Index < relaxedPoints.count else { continue }
                
                let point1 = relaxedPoints[v1Index]
                let point2 = relaxedPoints[v2Index]
                let delta = point2 - point1
                let currentLength = simd_length(delta)
                
                guard currentLength > 0.0001 else { continue }
                
                let forceMagnitude = springConstant * (currentLength - targetLength)
                let forceDirection = delta / currentLength
                let force = forceMagnitude * forceDirection
                
                // Skip first two points (fixed)
                if v1Index > 1 {
                    forces[v1Index] += force
                }
                if v2Index > 1 {
                    forces[v2Index] -= force
                }
            }
            
            // Apply forces with damping
            for i in 2..<relaxedPoints.count {
                relaxedPoints[i] += forces[i] * damping
            }
        }
        
        return relaxedPoints
    }
    
    private struct ProjectionPlane {
        let origin: SIMD3<Float>
        let tangent: SIMD3<Float>
        let bitangent: SIMD3<Float>
        let normal: SIMD3<Float>
    }
    
    private struct EdgeWithLength: Hashable {
        let vertex1: Int
        let vertex2: Int
        let length: Float
        
        init(_ v1: Int, _ v2: Int, _ length: Float) {
            vertex1 = min(v1, v2)
            vertex2 = max(v1, v2)
            self.length = length
        }
        
        static func == (lhs: EdgeWithLength, rhs: EdgeWithLength) -> Bool {
            lhs.vertex1 == rhs.vertex1 && lhs.vertex2 == rhs.vertex2
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(vertex1)
            hasher.combine(vertex2)
        }
    }
    
    public enum FlatteningError: LocalizedError {
        case emptyPanel
        case projectionFailed
        
        public var errorDescription: String? {
            switch self {
            case .emptyPanel:
                return "Cannot flatten an empty panel"
            case .projectionFailed:
                return "Failed to project panel to 2D"
            }
        }
    }
}