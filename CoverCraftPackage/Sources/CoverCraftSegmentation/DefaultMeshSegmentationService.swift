// Version: 1.0.0
// CoverCraft Segmentation Module - Default Mesh Segmentation Implementation

import Foundation
import simd
import Logging
import CoverCraftCore
import CoverCraftDTO

/// Default implementation of mesh segmentation service using K-means clustering
/// Enhanced implementation of mesh segmentation service using sophisticated K-means clustering
@available(iOS 18.0, macOS 15.0, *)
public final class DefaultMeshSegmentationService: MeshSegmentationService {
    
    private let logger = Logger(label: "com.covercraft.segmentation.enhanced")
    
    // MARK: - Configuration Constants
    
    private struct Config {
        static let maxIterations = 50
        static let convergenceThreshold: Float = 1e-4
        static let minTriangleArea: Float = 1e-6
        static let curvatureWeight: Float = 0.3
        static let normalWeight: Float = 0.4
        static let positionWeight: Float = 0.3
        static let smoothingIterations = 3
        static let smoothingFactor: Float = 0.5
        static let maxMemoryTriangles = 100_000
        static let timeoutSeconds = 2.0
    }
    
    // MARK: - Vertex Feature Structure
    
    private struct VertexFeatures: Sendable {
        let position: SIMD3<Float>
        let normal: SIMD3<Float>
        let curvature: Float
        let edgeLength: Float
        
        /// Compute distance between two vertex features using weighted metrics
        func distance(to other: VertexFeatures) -> Float {
            let positionDist = simd_distance(position, other.position)
            let normalDist = 1.0 - simd_dot(normal, other.normal) // 0 to 2, lower is better
            let curvatureDist = abs(curvature - other.curvature)
            let edgeDist = abs(edgeLength - other.edgeLength)
            
            return Config.positionWeight * positionDist +
                   Config.normalWeight * normalDist +
                   Config.curvatureWeight * curvatureDist +
                   0.1 * edgeDist
        }
    }
    
    public init() {
        logger.info("Enhanced Mesh Segmentation Service initialized with sophisticated algorithms")
    }
    
    public func segmentMesh(_ mesh: MeshDTO, targetPanelCount: Int) async throws -> [PanelDTO] {
        let startTime = CFAbsoluteTimeGetCurrent()
        logger.info("Starting enhanced K-means segmentation with \(targetPanelCount) target panels")
        
        // Validation
        try validateInputs(mesh: mesh, targetPanelCount: targetPanelCount)
        
        // Memory check for large meshes
        if mesh.triangleCount > Config.maxMemoryTriangles {
            logger.warning("Large mesh detected (\(mesh.triangleCount) triangles), may require significant memory")
        }
        
        let panels = try await performEnhancedSegmentation(
            mesh: mesh, 
            targetCount: targetPanelCount,
            startTime: startTime
        )
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        logger.info("Enhanced segmentation completed in \(String(format: "%.3f", duration))s with \(panels.count) panels")
        
        return panels
    }
    
    public func previewSegmentation(_ mesh: MeshDTO, resolution: SegmentationResolution) async throws -> [PanelDTO] {
        return try await segmentMesh(mesh, targetPanelCount: resolution.targetPanelCount)
    }
    
    // MARK: - Input Validation
    
    private func validateInputs(mesh: MeshDTO, targetPanelCount: Int) throws {
        guard mesh.isValid else {
            throw SegmentationError.invalidMesh("Mesh validation failed")
        }
        
        guard targetPanelCount > 0 && targetPanelCount <= 20 else {
            throw SegmentationError.invalidPanelCount(targetPanelCount)
        }
        
        guard mesh.triangleCount > 0 else {
            throw SegmentationError.invalidMesh("No triangles found")
        }
        
        // Check for degenerate mesh
        if mesh.vertices.count < 3 {
            throw SegmentationError.invalidMesh("Insufficient vertices")
        }
    }
    
    // MARK: - Enhanced Segmentation Pipeline
    
    private func performEnhancedSegmentation(
        mesh: MeshDTO, 
        targetCount: Int,
        startTime: Double
    ) async throws -> [PanelDTO] {
        
        let triangleCount = mesh.triangleCount
        let actualK = min(targetCount, triangleCount)
        
        logger.info("Phase 1: Computing enhanced vertex features for \(triangleCount) triangles")
        
        // Step 1: Extract enhanced vertex features
        let vertexFeatures = try await extractVertexFeatures(mesh: mesh)
        try checkTimeout(startTime: startTime)
        
        logger.info("Phase 2: Computing triangle features from \(vertexFeatures.count) vertices")
        
        // Step 2: Compute triangle features from vertex features
        let triangleFeatures = try computeTriangleFeatures(
            mesh: mesh, 
            vertexFeatures: vertexFeatures
        )
        try checkTimeout(startTime: startTime)
        
        logger.info("Phase 3: K-means++ initialization for \(actualK) clusters")
        
        // Step 3: K-means++ initialization
        let initialCenters = try kMeansPlusPlusInitialization(
            features: triangleFeatures, 
            k: actualK
        )
        try checkTimeout(startTime: startTime)
        
        logger.info("Phase 4: Running Lloyd's algorithm with convergence detection")
        
        // Step 4: Enhanced Lloyd's algorithm
        let assignments = try await runEnhancedLloydsAlgorithm(
            features: triangleFeatures,
            initialCenters: initialCenters,
            startTime: startTime
        )
        try checkTimeout(startTime: startTime)
        
        logger.info("Phase 5: Connected component post-processing")
        
        // Step 5: Connected component post-processing
        let connectedAssignments = try await enforceConnectedComponents(
            mesh: mesh,
            assignments: assignments,
            k: actualK,
            startTime: startTime
        )
        try checkTimeout(startTime: startTime)
        
        logger.info("Phase 6: Boundary smoothing")
        
        // Step 6: Smooth panel boundaries
        let smoothedAssignments = try await smoothPanelBoundaries(
            mesh: mesh,
            assignments: connectedAssignments,
            startTime: startTime
        )
        try checkTimeout(startTime: startTime)
        
        logger.info("Phase 7: Generating final panel DTOs")
        
        // Step 7: Generate final panels
        let panels = try generateOptimizedPanels(
            mesh: mesh,
            assignments: smoothedAssignments,
            k: actualK
        )
        
        return panels
    }
    
    private func checkTimeout(startTime: Double) throws {
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime
        if elapsed > Config.timeoutSeconds {
            throw SegmentationError.timeout
        }
    }
    
    // MARK: - Phase 1: Enhanced Vertex Feature Extraction
    
    private func extractVertexFeatures(mesh: MeshDTO) async throws -> [VertexFeatures] {
        let vertexCount = mesh.vertices.count
        var features: [VertexFeatures] = []
        features.reserveCapacity(vertexCount)
        
        // Build vertex-to-triangles adjacency for efficient normal and curvature computation
        let vertexTriangles = buildVertexTriangleAdjacency(mesh: mesh)
        
        for vertexIndex in 0..<vertexCount {
            let position = mesh.vertices[vertexIndex]
            
            // Compute vertex normal (area-weighted average of adjacent triangle normals)
            let normal = try computeVertexNormal(
                vertexIndex: vertexIndex,
                mesh: mesh,
                vertexTriangles: vertexTriangles
            )
            
            // Estimate Gaussian curvature using adjacent triangles
            let curvature = try computeGaussianCurvature(
                vertexIndex: vertexIndex,
                mesh: mesh,
                vertexTriangles: vertexTriangles
            )
            
            // Compute average edge length from this vertex
            let avgEdgeLength = computeAverageEdgeLength(
                vertexIndex: vertexIndex,
                mesh: mesh,
                vertexTriangles: vertexTriangles
            )
            
            let feature = VertexFeatures(
                position: position,
                normal: normal,
                curvature: curvature,
                edgeLength: avgEdgeLength
            )
            
            features.append(feature)
            
            // Periodic yielding for large meshes
            if vertexIndex % 1000 == 999 {
                await Task.yield()
            }
        }
        
        return features
    }
    
    private func buildVertexTriangleAdjacency(mesh: MeshDTO) -> [Int: [Int]] {
        var vertexTriangles: [Int: [Int]] = [:]
        
        let triangleCount = mesh.triangleCount
        for triangleIndex in 0..<triangleCount {
            let baseIdx = triangleIndex * 3
            guard baseIdx + 2 < mesh.triangleIndices.count else { continue }
            
            let v1 = mesh.triangleIndices[baseIdx]
            let v2 = mesh.triangleIndices[baseIdx + 1] 
            let v3 = mesh.triangleIndices[baseIdx + 2]
            
            for vertex in [v1, v2, v3] {
                if vertexTriangles[vertex] == nil {
                    vertexTriangles[vertex] = []
                }
                vertexTriangles[vertex]?.append(triangleIndex)
            }
        }
        
        return vertexTriangles
    }
    
    private func computeVertexNormal(
        vertexIndex: Int,
        mesh: MeshDTO,
        vertexTriangles: [Int: [Int]]
    ) throws -> SIMD3<Float> {
        
        guard let adjacentTriangles = vertexTriangles[vertexIndex] else {
            return SIMD3<Float>(0, 0, 1) // Default normal
        }
        
        var weightedNormal = SIMD3<Float>(0, 0, 0)
        var totalWeight: Float = 0
        
        for triangleIndex in adjacentTriangles {
            let baseIdx = triangleIndex * 3
            guard baseIdx + 2 < mesh.triangleIndices.count else { continue }
            
            let v1Idx = mesh.triangleIndices[baseIdx]
            let v2Idx = mesh.triangleIndices[baseIdx + 1]
            let v3Idx = mesh.triangleIndices[baseIdx + 2]
            
            guard v1Idx < mesh.vertices.count,
                  v2Idx < mesh.vertices.count,
                  v3Idx < mesh.vertices.count else { continue }
            
            let v1 = mesh.vertices[v1Idx]
            let v2 = mesh.vertices[v2Idx]
            let v3 = mesh.vertices[v3Idx]
            
            // Calculate triangle normal and area
            let edge1 = v2 - v1
            let edge2 = v3 - v1
            let normal = simd_cross(edge1, edge2)
            let area = simd_length(normal) * 0.5
            
            if area > Config.minTriangleArea {
                let unitNormal = normal / (area * 2) // Normalize
                weightedNormal += unitNormal * area
                totalWeight += area
            }
        }
        
        if totalWeight > Config.minTriangleArea {
            return simd_normalize(weightedNormal)
        } else {
            return SIMD3<Float>(0, 0, 1)
        }
    }
    
    private func computeGaussianCurvature(
        vertexIndex: Int,
        mesh: MeshDTO,
        vertexTriangles: [Int: [Int]]
    ) throws -> Float {
        
        guard let adjacentTriangles = vertexTriangles[vertexIndex] else {
            return 0.0
        }
        
        guard adjacentTriangles.count >= 3 else {
            return 0.0 // Insufficient data for curvature estimation
        }
        
        let vertex = mesh.vertices[vertexIndex]
        var angleSum: Float = 0.0
        var areaSum: Float = 0.0
        
        // Compute angles at this vertex for each adjacent triangle
        for triangleIndex in adjacentTriangles {
            let baseIdx = triangleIndex * 3
            guard baseIdx + 2 < mesh.triangleIndices.count else { continue }
            
            let v1Idx = mesh.triangleIndices[baseIdx]
            let v2Idx = mesh.triangleIndices[baseIdx + 1]
            let v3Idx = mesh.triangleIndices[baseIdx + 2]
            
            // Find which vertex is our target vertex
            var angle: Float = 0
            var triangleArea: Float = 0
            
            if v1Idx == vertexIndex {
                angle = computeAngle(center: vertex, p1: mesh.vertices[v2Idx], p2: mesh.vertices[v3Idx])
                triangleArea = computeTriangleArea(mesh.vertices[v1Idx], mesh.vertices[v2Idx], mesh.vertices[v3Idx])
            } else if v2Idx == vertexIndex {
                angle = computeAngle(center: vertex, p1: mesh.vertices[v3Idx], p2: mesh.vertices[v1Idx])
                triangleArea = computeTriangleArea(mesh.vertices[v1Idx], mesh.vertices[v2Idx], mesh.vertices[v3Idx])
            } else if v3Idx == vertexIndex {
                angle = computeAngle(center: vertex, p1: mesh.vertices[v1Idx], p2: mesh.vertices[v2Idx])
                triangleArea = computeTriangleArea(mesh.vertices[v1Idx], mesh.vertices[v2Idx], mesh.vertices[v3Idx])
            }
            
            angleSum += angle
            areaSum += triangleArea
        }
        
        // Gaussian curvature approximation using angle defect
        if areaSum > Config.minTriangleArea {
            let angleDefect = 2 * Float.pi - angleSum
            return 3 * angleDefect / areaSum // Normalized by local area
        }
        
        return 0.0
    }
    
    private func computeAngle(center: SIMD3<Float>, p1: SIMD3<Float>, p2: SIMD3<Float>) -> Float {
        let v1 = simd_normalize(p1 - center)
        let v2 = simd_normalize(p2 - center)
        let dot = simd_clamp(simd_dot(v1, v2), -1.0, 1.0)
        return acos(dot)
    }
    
    private func computeTriangleArea(_ v1: SIMD3<Float>, _ v2: SIMD3<Float>, _ v3: SIMD3<Float>) -> Float {
        let edge1 = v2 - v1
        let edge2 = v3 - v1
        return simd_length(simd_cross(edge1, edge2)) * 0.5
    }
    
    private func computeAverageEdgeLength(
        vertexIndex: Int,
        mesh: MeshDTO,
        vertexTriangles: [Int: [Int]]
    ) -> Float {
        
        guard let adjacentTriangles = vertexTriangles[vertexIndex] else {
            return 1.0 // Default edge length
        }
        
        let vertex = mesh.vertices[vertexIndex]
        var totalLength: Float = 0
        var edgeCount = 0
        var connectedVertices: Set<Int> = []
        
        // Find all vertices connected to this vertex
        for triangleIndex in adjacentTriangles {
            let baseIdx = triangleIndex * 3
            guard baseIdx + 2 < mesh.triangleIndices.count else { continue }
            
            let indices = [
                mesh.triangleIndices[baseIdx],
                mesh.triangleIndices[baseIdx + 1],
                mesh.triangleIndices[baseIdx + 2]
            ]
            
            for idx in indices {
                if idx != vertexIndex && idx < mesh.vertices.count {
                    connectedVertices.insert(idx)
                }
            }
        }
        
        // Calculate edge lengths to connected vertices
        for connectedIdx in connectedVertices {
            let edgeLength = simd_distance(vertex, mesh.vertices[connectedIdx])
            totalLength += edgeLength
            edgeCount += 1
        }
        
        return edgeCount > 0 ? totalLength / Float(edgeCount) : 1.0
    }
    
    // MARK: - Phase 2: Triangle Feature Computation
    
    private func computeTriangleFeatures(
        mesh: MeshDTO, 
        vertexFeatures: [VertexFeatures]
    ) throws -> [VertexFeatures] {
        
        let triangleCount = mesh.triangleCount
        var triangleFeatures: [VertexFeatures] = []
        triangleFeatures.reserveCapacity(triangleCount)
        
        for triangleIndex in 0..<triangleCount {
            let baseIdx = triangleIndex * 3
            guard baseIdx + 2 < mesh.triangleIndices.count else {
                throw SegmentationError.invalidMesh("Invalid triangle indices")
            }
            
            let v1Idx = mesh.triangleIndices[baseIdx]
            let v2Idx = mesh.triangleIndices[baseIdx + 1]
            let v3Idx = mesh.triangleIndices[baseIdx + 2]
            
            guard v1Idx < vertexFeatures.count,
                  v2Idx < vertexFeatures.count,
                  v3Idx < vertexFeatures.count else {
                throw SegmentationError.invalidMesh("Triangle indices out of bounds")
            }
            
            let f1 = vertexFeatures[v1Idx]
            let f2 = vertexFeatures[v2Idx]
            let f3 = vertexFeatures[v3Idx]
            
            // Triangle feature is average of vertex features
            let centroid = (f1.position + f2.position + f3.position) / 3.0
            
            // Area-weighted normal average
            let area1 = computeTriangleArea(f1.position, f2.position, f3.position)
            let area2 = computeTriangleArea(f2.position, f3.position, f1.position)
            let area3 = computeTriangleArea(f3.position, f1.position, f2.position)
            let totalArea = area1 + area2 + area3
            
            let avgNormal: SIMD3<Float>
            if totalArea > Config.minTriangleArea {
                avgNormal = simd_normalize((f1.normal + f2.normal + f3.normal) / 3.0)
            } else {
                avgNormal = SIMD3<Float>(0, 0, 1)
            }
            
            let avgCurvature = (f1.curvature + f2.curvature + f3.curvature) / 3.0
            let avgEdgeLength = (f1.edgeLength + f2.edgeLength + f3.edgeLength) / 3.0
            
            let triangleFeature = VertexFeatures(
                position: centroid,
                normal: avgNormal,
                curvature: avgCurvature,
                edgeLength: avgEdgeLength
            )
            
            triangleFeatures.append(triangleFeature)
        }
        
        return triangleFeatures
    }
    
    // MARK: - Phase 3: Sophisticated K-means++ Initialization
    
    private func kMeansPlusPlusInitialization(
        features: [VertexFeatures], 
        k: Int
    ) throws -> [VertexFeatures] {
        
        guard !features.isEmpty else {
            throw SegmentationError.invalidMesh("No triangle features to cluster")
        }
        
        guard k > 0 && k <= features.count else {
            throw SegmentationError.invalidPanelCount(k)
        }
        
        var centers: [VertexFeatures] = []
        centers.reserveCapacity(k)
        
        // Choose first center randomly
        let firstIndex = Int.random(in: 0..<features.count)
        centers.append(features[firstIndex])
        
        logger.debug("K-means++: Selected initial center from triangle \(firstIndex)")
        
        // Choose remaining centers using K-means++ algorithm
        for centerIndex in 1..<k {
            var distances: [Double] = []
            distances.reserveCapacity(features.count)
            
            // Calculate squared distances to nearest center for each feature
            for feature in features {
                let minDistanceSquared = centers.map { center in
                    let dist = feature.distance(to: center)
                    return Double(dist * dist)
                }.min() ?? 0.0
                
                distances.append(minDistanceSquared)
            }
            
            // Choose next center with probability proportional to squared distance
            let totalDistance = distances.reduce(0, +)
            
            guard totalDistance > 0 else {
                // If all distances are zero, pick randomly from remaining
                let availableIndices = Set(0..<features.count).subtracting(
                    centers.compactMap { center in
                        features.firstIndex { $0.position == center.position }
                    }
                )
                
                if let randomIndex = availableIndices.randomElement() {
                    centers.append(features[randomIndex])
                } else {
                    centers.append(features[Int.random(in: 0..<features.count)])
                }
                continue
            }
            
            let randomValue = Double.random(in: 0..<totalDistance)
            var cumulativeDistance: Double = 0
            var selectedIndex = 0
            
            for (index, distance) in distances.enumerated() {
                cumulativeDistance += distance
                if cumulativeDistance >= randomValue {
                    selectedIndex = index
                    break
                }
            }
            
            centers.append(features[selectedIndex])
            logger.debug("K-means++: Selected center \(centerIndex + 1) from triangle \(selectedIndex)")
        }
        
        return centers
    }
    
    // MARK: - Phase 4: Enhanced Lloyd's Algorithm
    
    private func runEnhancedLloydsAlgorithm(
        features: [VertexFeatures],
        initialCenters: [VertexFeatures],
        startTime: Double
    ) async throws -> [Int] {
        
        var centers = initialCenters
        let k = centers.count
        var assignments = Array(repeating: 0, count: features.count)
        
        for iteration in 0..<Config.maxIterations {
            let previousCenters = centers
            
            // Assignment step: assign each triangle to nearest cluster using enhanced distance metric
            for (triangleIndex, feature) in features.enumerated() {
                var bestCluster = 0
                var bestDistance = feature.distance(to: centers[0])
                
                for clusterIndex in 1..<k {
                    let distance = feature.distance(to: centers[clusterIndex])
                    if distance < bestDistance {
                        bestDistance = distance
                        bestCluster = clusterIndex
                    }
                }
                
                assignments[triangleIndex] = bestCluster
            }
            
            // Update step: recalculate cluster centers using feature averaging
            var newCenters: [VertexFeatures] = []
            newCenters.reserveCapacity(k)
            
            for clusterIndex in 0..<k {
                var clusterFeatures: [VertexFeatures] = []
                
                for (triangleIndex, assignedCluster) in assignments.enumerated() {
                    if assignedCluster == clusterIndex {
                        clusterFeatures.append(features[triangleIndex])
                    }
                }
                
                if clusterFeatures.isEmpty {
                    // Keep previous center if cluster is empty
                    newCenters.append(centers[clusterIndex])
                } else {
                    // Compute mean of all features
                    let avgPosition = clusterFeatures.map(\.position).reduce(SIMD3<Float>(0,0,0), +) / Float(clusterFeatures.count)
                    let avgNormal = simd_normalize(
                        clusterFeatures.map(\.normal).reduce(SIMD3<Float>(0,0,0), +)
                    )
                    let avgCurvature = clusterFeatures.map(\.curvature).reduce(0, +) / Float(clusterFeatures.count)
                    let avgEdgeLength = clusterFeatures.map(\.edgeLength).reduce(0, +) / Float(clusterFeatures.count)
                    
                    let newCenter = VertexFeatures(
                        position: avgPosition,
                        normal: avgNormal,
                        curvature: avgCurvature,
                        edgeLength: avgEdgeLength
                    )
                    newCenters.append(newCenter)
                }
            }
            
            centers = newCenters
            
            // Check for convergence using center movement
            let maxCenterMovement = zip(centers, previousCenters)
                .map { $0.0.distance(to: $0.1) }
                .max() ?? 0.0
            
            if maxCenterMovement < Config.convergenceThreshold {
                logger.info("K-means converged after \(iteration + 1) iterations (movement: \(maxCenterMovement))")
                break
            }
            
            // Periodic yielding and timeout checking
            if iteration % 5 == 4 {
                await Task.yield()
                try checkTimeout(startTime: startTime)
            }
        }
        
        return assignments
    }
    
    // MARK: - Phase 5: Connected Component Enforcement
    
    private func enforceConnectedComponents(
        mesh: MeshDTO,
        assignments: [Int],
        k: Int,
        startTime: Double
    ) async throws -> [Int] {
        
        guard assignments.count == mesh.triangleCount else {
            throw SegmentationError.algorithmsFailure("Assignment count mismatch")
        }
        
        // Build triangle adjacency graph
        let adjacency = try buildOptimizedTriangleAdjacency(mesh: mesh)
        
        var processedAssignments = assignments
        
        // Process each cluster to enforce connectivity
        for clusterIndex in 0..<k {
            var visited = Array(repeating: false, count: mesh.triangleCount)
            var components: [[Int]] = []
            
            // Find all triangles in this cluster
            for (triangleIndex, assignment) in processedAssignments.enumerated() {
                if assignment == clusterIndex && !visited[triangleIndex] {
                    let component = floodFillConnectedComponent(
                        startTriangle: triangleIndex,
                        targetCluster: clusterIndex,
                        assignments: processedAssignments,
                        adjacency: adjacency,
                        visited: &visited
                    )
                    
                    if !component.isEmpty {
                        components.append(component)
                    }
                }
            }
            
            // If multiple components exist, merge smaller ones with nearest clusters
            if components.count > 1 {
                let largestComponent = components.max(by: { $0.count < $1.count }) ?? []
                let smallComponents = components.filter { $0 != largestComponent }
                
                for smallComponent in smallComponents {
                    let nearestCluster = findNearestClusterForComponent(
                        triangles: smallComponent,
                        mesh: mesh,
                        assignments: processedAssignments,
                        adjacency: adjacency,
                        excludeCluster: clusterIndex
                    )
                    
                    // Reassign small component to nearest cluster
                    for triangleIndex in smallComponent {
                        processedAssignments[triangleIndex] = nearestCluster
                    }
                }
                
                logger.debug("Cluster \(clusterIndex): merged \(smallComponents.count) disconnected components")
            }
            
            // Periodic yielding and timeout checking
            if clusterIndex % 3 == 2 {
                await Task.yield()
                try checkTimeout(startTime: startTime)
            }
        }
        
        return processedAssignments
    }
    
    private func buildOptimizedTriangleAdjacency(mesh: MeshDTO) throws -> [Int: Set<Int>] {
        let triangleCount = mesh.triangleCount
        var adjacency: [Int: Set<Int>] = [:]
        
        // Initialize adjacency sets with capacity
        for i in 0..<triangleCount {
            adjacency[i] = Set<Int>()
        }
        
        // Use efficient edge-based adjacency building
        var edgeToTriangles: [EdgeKey: [Int]] = [:]
        
        for triangleIndex in 0..<triangleCount {
            let baseIdx = triangleIndex * 3
            guard baseIdx + 2 < mesh.triangleIndices.count else { continue }
            
            let v1 = mesh.triangleIndices[baseIdx]
            let v2 = mesh.triangleIndices[baseIdx + 1]
            let v3 = mesh.triangleIndices[baseIdx + 2]
            
            let edges = [
                EdgeKey(v1, v2),
                EdgeKey(v2, v3), 
                EdgeKey(v3, v1)
            ]
            
            for edge in edges {
                if edgeToTriangles[edge] == nil {
                    edgeToTriangles[edge] = []
                }
                edgeToTriangles[edge]?.append(triangleIndex)
            }
        }
        
        // Build adjacency from edge mappings  
        for triangleIndices in edgeToTriangles.values {
            for i in 0..<triangleIndices.count {
                for j in (i+1)..<triangleIndices.count {
                    let tri1 = triangleIndices[i]
                    let tri2 = triangleIndices[j] 
                    adjacency[tri1]?.insert(tri2)
                    adjacency[tri2]?.insert(tri1)
                }
            }
        }
        
        return adjacency
    }
    
    private struct EdgeKey: Hashable, Sendable {
        let v1: Int
        let v2: Int
        
        init(_ vertex1: Int, _ vertex2: Int) {
            if vertex1 < vertex2 {
                v1 = vertex1
                v2 = vertex2
            } else {
                v1 = vertex2
                v2 = vertex1
            }
        }
    }
    
    private func floodFillConnectedComponent(
        startTriangle: Int,
        targetCluster: Int,
        assignments: [Int],
        adjacency: [Int: Set<Int>],
        visited: inout [Bool]
    ) -> [Int] {
        
        var component: [Int] = []
        var stack: [Int] = [startTriangle]
        
        while !stack.isEmpty {
            let triangleIndex = stack.removeLast()
            
            if visited[triangleIndex] { continue }
            if assignments[triangleIndex] != targetCluster { continue }
            
            visited[triangleIndex] = true
            component.append(triangleIndex)
            
            // Add unvisited adjacent triangles in same cluster
            if let neighbors = adjacency[triangleIndex] {
                for neighbor in neighbors {
                    if !visited[neighbor] && assignments[neighbor] == targetCluster {
                        stack.append(neighbor)
                    }
                }
            }
        }
        
        return component
    }
    
    private func findNearestClusterForComponent(
        triangles: [Int],
        mesh: MeshDTO,
        assignments: [Int],
        adjacency: [Int: Set<Int>],
        excludeCluster: Int
    ) -> Int {
        
        var clusterDistances: [Int: Float] = [:]
        
        // Find distances to adjacent clusters
        for triangleIndex in triangles {
            guard let neighbors = adjacency[triangleIndex] else { continue }
            
            for neighborIndex in neighbors {
                let neighborCluster = assignments[neighborIndex]
                if neighborCluster != excludeCluster {
                    let distance = computeTriangleCentroidDistance(
                        triangle1: triangleIndex,
                        triangle2: neighborIndex,
                        mesh: mesh
                    )
                    
                    if let existingDistance = clusterDistances[neighborCluster] {
                        clusterDistances[neighborCluster] = min(existingDistance, distance)
                    } else {
                        clusterDistances[neighborCluster] = distance
                    }
                }
            }
        }
        
        // Return nearest cluster, or 0 if none found
        return clusterDistances.min(by: { $0.value < $1.value })?.key ?? 0
    }
    
    private func computeTriangleCentroidDistance(
        triangle1: Int, 
        triangle2: Int, 
        mesh: MeshDTO
    ) -> Float {
        let centroid1 = computeTriangleCentroid(triangleIndex: triangle1, mesh: mesh)
        let centroid2 = computeTriangleCentroid(triangleIndex: triangle2, mesh: mesh)
        return simd_distance(centroid1, centroid2)
    }
    
    private func computeTriangleCentroid(triangleIndex: Int, mesh: MeshDTO) -> SIMD3<Float> {
        let baseIdx = triangleIndex * 3
        guard baseIdx + 2 < mesh.triangleIndices.count else {
            return SIMD3<Float>(0, 0, 0)
        }
        
        let v1Idx = mesh.triangleIndices[baseIdx]
        let v2Idx = mesh.triangleIndices[baseIdx + 1]
        let v3Idx = mesh.triangleIndices[baseIdx + 2]
        
        guard v1Idx < mesh.vertices.count,
              v2Idx < mesh.vertices.count,
              v3Idx < mesh.vertices.count else {
            return SIMD3<Float>(0, 0, 0)
        }
        
        let v1 = mesh.vertices[v1Idx]
        let v2 = mesh.vertices[v2Idx]
        let v3 = mesh.vertices[v3Idx]
        
        return (v1 + v2 + v3) / 3.0
    }
    
    // MARK: - Phase 6: Boundary Smoothing
    
    private func smoothPanelBoundaries(
        mesh: MeshDTO,
        assignments: [Int],
        startTime: Double
    ) async throws -> [Int] {
        
        let adjacency = try buildOptimizedTriangleAdjacency(mesh: mesh)
        var smoothedAssignments = assignments
        
        // Apply Laplacian smoothing to panel boundaries
        for iteration in 0..<Config.smoothingIterations {
            var newAssignments = smoothedAssignments
            
            for (triangleIndex, currentCluster) in smoothedAssignments.enumerated() {
                guard let neighbors = adjacency[triangleIndex] else { continue }
                
                // Check if this triangle is on a boundary (has neighbors in different clusters)
                let neighborClusters = neighbors.map { smoothedAssignments[$0] }
                let uniqueClusters = Set(neighborClusters)
                
                if uniqueClusters.count > 1 { // Boundary triangle
                    // Find most common cluster among neighbors
                    var clusterCounts: [Int: Int] = [:]
                    for cluster in neighborClusters {
                        clusterCounts[cluster, default: 0] += 1
                    }
                    
                    // Include current triangle's vote with higher weight
                    clusterCounts[currentCluster, default: 0] += 2
                    
                    // Assign to most voted cluster
                    if let mostCommonCluster = clusterCounts.max(by: { $0.value < $1.value })?.key {
                        newAssignments[triangleIndex] = mostCommonCluster
                    }
                }
            }
            
            smoothedAssignments = newAssignments
            
            // Periodic yielding and timeout checking
            if iteration % 2 == 1 {
                await Task.yield()
                try checkTimeout(startTime: startTime)
            }
        }
        
        logger.debug("Applied \(Config.smoothingIterations) iterations of boundary smoothing")
        return smoothedAssignments
    }
    
    // MARK: - Phase 7: Optimized Panel Generation
    
    private func generateOptimizedPanels(
        mesh: MeshDTO,
        assignments: [Int],
        k: Int
    ) throws -> [PanelDTO] {
        
        let colors: [ColorDTO] = [
            .red, .blue, .green, .yellow, .orange, .purple, .cyan, .magenta,
            ColorDTO(red: 0.7, green: 0.7, blue: 0.7), // Light gray
            ColorDTO(red: 0.4, green: 0.2, blue: 0.1), // Brown
            ColorDTO(red: 0.0, green: 0.5, blue: 0.0), // Dark green
            ColorDTO(red: 0.5, green: 0.0, blue: 0.5), // Dark purple
            ColorDTO(red: 0.0, green: 0.5, blue: 0.5), // Teal
            ColorDTO(red: 0.5, green: 0.5, blue: 0.0), // Olive
            ColorDTO(red: 0.8, green: 0.4, blue: 0.2), // Orange-brown
            ColorDTO(red: 0.2, green: 0.4, blue: 0.8), // Sky blue
            ColorDTO(red: 0.8, green: 0.2, blue: 0.4), // Pink
            ColorDTO(red: 0.4, green: 0.8, blue: 0.2), // Lime
            ColorDTO(red: 0.3, green: 0.3, blue: 0.3), // Dark gray
            ColorDTO(red: 0.9, green: 0.9, blue: 0.9)  // Almost white
        ]
        
        var panels: [PanelDTO] = []
        var panelStats: [String] = []
        
        for clusterIndex in 0..<k {
            var triangleIndices: [Int] = []
            var vertexIndices: Set<Int> = []
            
            // Collect triangles and vertices for this panel
            for (triangleIndex, assignment) in assignments.enumerated() {
                if assignment == clusterIndex {
                    let baseIdx = triangleIndex * 3
                    guard baseIdx + 2 < mesh.triangleIndices.count else { continue }
                    
                    let v1 = mesh.triangleIndices[baseIdx]
                    let v2 = mesh.triangleIndices[baseIdx + 1] 
                    let v3 = mesh.triangleIndices[baseIdx + 2]
                    
                    triangleIndices.append(contentsOf: [v1, v2, v3])
                    vertexIndices.formUnion([v1, v2, v3])
                }
            }
            
            // Only create panel if it has sufficient geometry
            if !triangleIndices.isEmpty && vertexIndices.count >= 3 {
                let triangleCount = triangleIndices.count / 3
                let panel = PanelDTO(
                    vertexIndices: vertexIndices,
                    triangleIndices: triangleIndices,
                    color: colors[clusterIndex % colors.count]
                )
                panels.append(panel)
                panelStats.append("Panel \(clusterIndex): \(vertexIndices.count) vertices, \(triangleCount) triangles")
            }
        }
        
        // Log panel statistics
        for stat in panelStats {
            logger.debug("\(stat)")
        }
        
        // Validation
        if panels.isEmpty {
            throw SegmentationError.segmentationFailed("No valid panels generated")
        }
        
        // Verify all panels are valid
        for panel in panels {
            if !panel.isValid {
                throw SegmentationError.segmentationFailed("Generated invalid panel")
            }
        }
        
        logger.info("Generated \(panels.count) optimized panels")
        return panels
    }
}

// MARK: - Service Registration

@available(iOS 18.0, macOS 15.0, *)
public extension DefaultDependencyContainer {
    
    /// Register segmentation services
    func registerSegmentationServices() {
        print("Registering K-means mesh segmentation services")
        
        registerSingleton({
            DefaultMeshSegmentationService()
        }, for: MeshSegmentationService.self)
        
        print("K-means segmentation services registration completed")
    }
}