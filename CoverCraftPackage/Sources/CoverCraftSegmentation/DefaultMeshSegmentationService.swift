// Version: 1.0.0
// CoverCraft Segmentation Module - Default Mesh Segmentation Implementation

import Foundation
import simd
import Logging
import CoverCraftCore
import CoverCraftDTO

/// Default implementation of mesh segmentation service using K-means clustering
@available(iOS 18.0, *)
public final class DefaultMeshSegmentationService: MeshSegmentationService {
    
    private let logger = Logger(label: "com.covercraft.segmentation")
    
    public init() {
        logger.info("Default Mesh Segmentation Service initialized with K-means clustering")
    }
    
    public func segmentMesh(_ mesh: MeshDTO, targetPanelCount: Int) async throws -> [PanelDTO] {
        logger.info("Starting K-means mesh segmentation with target panel count: \(targetPanelCount)")
        
        guard mesh.isValid else {
            throw SegmentationError.invalidMesh("Mesh validation failed")
        }
        
        guard targetPanelCount > 0 && targetPanelCount <= 20 else {
            throw SegmentationError.invalidPanelCount(targetPanelCount)
        }
        
        let panels = try await performSegmentation(mesh: mesh, targetCount: targetPanelCount)
        
        logger.info("K-means mesh segmentation completed with \(panels.count) panels")
        return panels
    }
    
    public func previewSegmentation(_ mesh: MeshDTO, resolution: SegmentationResolution) async throws -> [PanelDTO] {
        return try await segmentMesh(mesh, targetPanelCount: resolution.targetPanelCount)
    }
    
    private func performSegmentation(mesh: MeshDTO, targetCount: Int) async throws -> [PanelDTO] {
        logger.info("Starting K-means mesh segmentation with \(targetCount) clusters")
        
        let triangleCount = mesh.triangleCount
        guard triangleCount > 0 else {
            throw SegmentationError.invalidMesh("No triangles found")
        }
        
        // Handle edge case where target count exceeds triangle count
        let actualK = min(targetCount, triangleCount)
        
        do {
            // Step 1: Calculate surface normals for all triangles
            let normals = try await calculateSurfaceNormals(mesh: mesh)
            
            // Step 2: Initialize K cluster centers using K-means++
            let initialCenters = try kMeansPlusPlusInitialization(normals: normals, k: actualK)
            
            // Step 3: Run Lloyd's algorithm
            let assignments = try await runKMeansAlgorithm(
                normals: normals, 
                initialCenters: initialCenters,
                maxIterations: 50
            )
            
            // Step 4: Post-process with flood fill for connected components
            let connectedAssignments = try await floodFillPostProcess(
                mesh: mesh,
                assignments: assignments,
                k: actualK
            )
            
            // Step 5: Generate PanelDTO objects
            let panels = try generatePanels(
                mesh: mesh,
                assignments: connectedAssignments,
                k: actualK
            )
            
            logger.info("K-means segmentation completed with \(panels.count) panels")
            return panels
            
        } catch let error as SegmentationError {
            throw error
        } catch {
            logger.error("Unexpected error in segmentation: \(error)")
            throw SegmentationError.algorithmsFailure("K-means algorithm failed: \(error.localizedDescription)")
        }
    }

    
    // MARK: - K-means Algorithm Implementation
    
    /// Calculate surface normals for all triangles using SIMD
    private func calculateSurfaceNormals(mesh: MeshDTO) async throws -> [SIMD3<Float>] {
        let triangleCount = mesh.triangleCount
        var normals: [SIMD3<Float>] = []
        normals.reserveCapacity(triangleCount)
        
        for triangleIndex in 0..<triangleCount {
            let baseIdx = triangleIndex * 3
            
            guard baseIdx + 2 < mesh.triangleIndices.count else {
                throw SegmentationError.invalidMesh("Invalid triangle indices")
            }
            
            let v1Index = mesh.triangleIndices[baseIdx]
            let v2Index = mesh.triangleIndices[baseIdx + 1]
            let v3Index = mesh.triangleIndices[baseIdx + 2]
            
            guard v1Index < mesh.vertices.count,
                  v2Index < mesh.vertices.count,
                  v3Index < mesh.vertices.count else {
                throw SegmentationError.invalidMesh("Triangle indices out of bounds")
            }
            
            let v1 = mesh.vertices[v1Index]
            let v2 = mesh.vertices[v2Index]
            let v3 = mesh.vertices[v3Index]
            
            // Calculate face normal using cross product
            let edge1 = v2 - v1
            let edge2 = v3 - v1
            let normal = simd_cross(edge1, edge2)
            
            // Handle degenerate triangles (zero area)
            let normalLength = simd_length(normal)
            if normalLength < 1e-6 {
                // Use a default normal for degenerate triangles
                normals.append(SIMD3<Float>(0, 0, 1))
            } else {
                // Normalize the normal vector
                normals.append(normal / normalLength)
            }
        }
        
        return normals
    }
    
    /// K-means++ initialization for better cluster center selection
    private func kMeansPlusPlusInitialization(normals: [SIMD3<Float>], k: Int) throws -> [SIMD3<Float>] {
        guard !normals.isEmpty else {
            throw SegmentationError.invalidMesh("No normals to cluster")
        }
        
        guard k > 0 && k <= normals.count else {
            throw SegmentationError.invalidPanelCount(k)
        }
        
        var centers: [SIMD3<Float>] = []
        centers.reserveCapacity(k)
        
        // Choose first center randomly
        let firstIndex = Int.random(in: 0..<normals.count)
        centers.append(normals[firstIndex])
        
        // Choose remaining centers using K-means++ algorithm
        for _ in 1..<k {
            var distances: [Float] = []
            distances.reserveCapacity(normals.count)
            
            // Calculate squared distances to nearest center for each normal
            for normal in normals {
                let minDistanceSquared = centers.map { center in
                    let diff = normal - center
                    return dot(diff, diff)
                }.min() ?? 0.0
                distances.append(minDistanceSquared)
            }
            
            // Choose next center with probability proportional to squared distance
            let totalDistance = distances.reduce(0, +)
            guard totalDistance > 0 else {
                // If all distances are zero, pick randomly
                let randomIndex = Int.random(in: 0..<normals.count)
                centers.append(normals[randomIndex])
                continue
            }
            
            let randomValue = Float.random(in: 0..<totalDistance)
            var cumulativeDistance: Float = 0
            
            for (index, distance) in distances.enumerated() {
                cumulativeDistance += distance
                if cumulativeDistance >= randomValue {
                    centers.append(normals[index])
                    break
                }
            }
        }
        
        return centers
    }
    
    /// Run Lloyd's K-means algorithm with convergence checking
    private func runKMeansAlgorithm(
        normals: [SIMD3<Float>],
        initialCenters: [SIMD3<Float>],
        maxIterations: Int
    ) async throws -> [Int] {
        var centers = initialCenters
        let k = centers.count
        var assignments = Array(repeating: 0, count: normals.count)
        let convergenceThreshold: Float = 1e-4
        
        for iteration in 0..<maxIterations {
            let previousCenters = centers
            
            // Assignment step: assign each triangle to nearest cluster
            for (triangleIndex, normal) in normals.enumerated() {
                var bestCluster = 0
                var bestDistanceSquared = dot(normal - centers[0], normal - centers[0])
                
                for clusterIndex in 1..<k {
                    let diff = normal - centers[clusterIndex]
                    let distanceSquared = dot(diff, diff)
                    if distanceSquared < bestDistanceSquared {
                        bestDistanceSquared = distanceSquared
                        bestCluster = clusterIndex
                    }
                }
                
                assignments[triangleIndex] = bestCluster
            }
            
            // Update step: recalculate cluster centers
            var newCenters: [SIMD3<Float>] = []
            newCenters.reserveCapacity(k)
            
            for clusterIndex in 0..<k {
                var clusterNormals: [SIMD3<Float>] = []
                
                for (triangleIndex, assignedCluster) in assignments.enumerated() {
                    if assignedCluster == clusterIndex {
                        clusterNormals.append(normals[triangleIndex])
                    }
                }
                
                if clusterNormals.isEmpty {
                    // If cluster is empty, keep previous center
                    newCenters.append(centers[clusterIndex])
                } else {
                    // Calculate mean of assigned normals
                    let sum = clusterNormals.reduce(SIMD3<Float>(0, 0, 0), +)
                    let mean = sum / Float(clusterNormals.count)
                    
                    // Normalize the mean to unit length for surface normals
                    let meanLength = simd_length(mean)
                    if meanLength > 1e-6 {
                        newCenters.append(mean / meanLength)
                    } else {
                        newCenters.append(centers[clusterIndex])
                    }
                }
            }
            
            centers = newCenters
            
            // Check for convergence
            let maxCenterMovement = zip(centers, previousCenters)
                .map { simd_distance($0.0, $0.1) }
                .max() ?? 0.0
            
            if maxCenterMovement < convergenceThreshold {
                logger.info("K-means converged after \(iteration + 1) iterations")
                break
            }
            
            // Yield control periodically for async behavior
            if iteration % 10 == 9 {
                if #available(iOS 13.0, macOS 10.15, *) {
                    await Task.yield()
                }
            }
        }
        
        return assignments
    }
    
    /// Post-process assignments with flood fill to ensure connected components
    private func floodFillPostProcess(
        mesh: MeshDTO,
        assignments: [Int],
        k: Int
    ) async throws -> [Int] {
        let triangleCount = mesh.triangleCount
        guard assignments.count == triangleCount else {
            throw SegmentationError.algorithmsFailure("Assignment count mismatch")
        }
        
        // Build triangle adjacency information
        let adjacency = try buildTriangleAdjacency(mesh: mesh)
        
        var processedAssignments = assignments
        var visited = Array(repeating: false, count: triangleCount)
        
        // Process each cluster separately
        for clusterIndex in 0..<k {
            var clusterTriangles: [Int] = []
            
            // Find all triangles assigned to this cluster
            for (triangleIndex, assignment) in processedAssignments.enumerated() {
                if assignment == clusterIndex {
                    clusterTriangles.append(triangleIndex)
                }
            }
            
            guard !clusterTriangles.isEmpty else { continue }
            
            // Find connected components within this cluster
            var components: [[Int]] = []
            
            for triangleIndex in clusterTriangles {
                if !visited[triangleIndex] {
                    let component = floodFillComponent(
                        startTriangle: triangleIndex,
                        targetCluster: clusterIndex,
                        assignments: processedAssignments,
                        adjacency: adjacency,
                        visited: &visited
                    )
                    components.append(component)
                }
            }
            
            // Keep the largest component in the original cluster
            // Reassign smaller components to nearest neighboring clusters
            if components.count > 1 {
                let largestComponent = components.max(by: { $0.count < $1.count }) ?? []
                let smallComponents = components.filter { $0 != largestComponent }
                
                for smallComponent in smallComponents {
                    let nearestCluster = findNearestCluster(
                        triangles: smallComponent,
                        mesh: mesh,
                        assignments: processedAssignments,
                        adjacency: adjacency,
                        excludeCluster: clusterIndex
                    )
                    
                    for triangleIndex in smallComponent {
                        processedAssignments[triangleIndex] = nearestCluster
                    }
                }
            }
            
            // Yield control periodically
            if clusterIndex % 5 == 4 {
                if #available(iOS 13.0, macOS 10.15, *) {
                    await Task.yield()
                }
            }
        }
        
        return processedAssignments
    }
    
    /// Build triangle adjacency map for flood fill
    private func buildTriangleAdjacency(mesh: MeshDTO) throws -> [Int: Set<Int>] {
        let triangleCount = mesh.triangleCount
        var adjacency: [Int: Set<Int>] = [:]
        
        // Initialize adjacency sets
        for i in 0..<triangleCount {
            adjacency[i] = Set<Int>()
        }
        
        // Build edge to triangle mapping
        var edgeToTriangles: [String: [Int]] = [:]
        
        for triangleIndex in 0..<triangleCount {
            let baseIdx = triangleIndex * 3
            guard baseIdx + 2 < mesh.triangleIndices.count else { continue }
            
            let v1 = mesh.triangleIndices[baseIdx]
            let v2 = mesh.triangleIndices[baseIdx + 1]
            let v3 = mesh.triangleIndices[baseIdx + 2]
            
            // Create edge keys (sorted to ensure consistency)
            let edges = [
                edgeKey(v1, v2),
                edgeKey(v2, v3),
                edgeKey(v3, v1)
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
            if triangleIndices.count >= 2 {
                // Triangles sharing an edge are adjacent
                for i in 0..<triangleIndices.count {
                    for j in (i+1)..<triangleIndices.count {
                        let tri1 = triangleIndices[i]
                        let tri2 = triangleIndices[j]
                        adjacency[tri1]?.insert(tri2)
                        adjacency[tri2]?.insert(tri1)
                    }
                }
            }
        }
        
        return adjacency
    }
    
    /// Create consistent edge key from two vertex indices
    private func edgeKey(_ v1: Int, _ v2: Int) -> String {
        let min = Swift.min(v1, v2)
        let max = Swift.max(v1, v2)
        return "\(min)-\(max)"
    }
    
    /// Flood fill to find connected component starting from a triangle
    private func floodFillComponent(
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
            
            // Add adjacent triangles to stack
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
    
    /// Find nearest cluster for reassigning disconnected components
    private func findNearestCluster(
        triangles: [Int],
        mesh: MeshDTO,
        assignments: [Int],
        adjacency: [Int: Set<Int>],
        excludeCluster: Int
    ) -> Int {
        var clusterDistances: [Int: Float] = [:]
        
        // Find all adjacent clusters and their distances
        for triangleIndex in triangles {
            guard let neighbors = adjacency[triangleIndex] else { continue }
            
            for neighborTriangle in neighbors {
                let neighborCluster = assignments[neighborTriangle]
                if neighborCluster != excludeCluster {
                    // Calculate distance between triangle centroids
                    let distance = triangleCentroidDistance(
                        triangle1: triangleIndex,
                        triangle2: neighborTriangle,
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
        
        // Return cluster with minimum distance, or 0 if no adjacent clusters found
        return clusterDistances.min(by: { $0.value < $1.value })?.key ?? 0
    }
    
    /// Calculate distance between triangle centroids
    private func triangleCentroidDistance(triangle1: Int, triangle2: Int, mesh: MeshDTO) -> Float {
        let centroid1 = triangleCentroid(triangleIndex: triangle1, mesh: mesh)
        let centroid2 = triangleCentroid(triangleIndex: triangle2, mesh: mesh)
        return simd_distance(centroid1, centroid2)
    }
    
    /// Calculate centroid of a triangle
    private func triangleCentroid(triangleIndex: Int, mesh: MeshDTO) -> SIMD3<Float> {
        let baseIdx = triangleIndex * 3
        guard baseIdx + 2 < mesh.triangleIndices.count else {
            return SIMD3<Float>(0, 0, 0)
        }
        
        let v1Index = mesh.triangleIndices[baseIdx]
        let v2Index = mesh.triangleIndices[baseIdx + 1]
        let v3Index = mesh.triangleIndices[baseIdx + 2]
        
        guard v1Index < mesh.vertices.count,
              v2Index < mesh.vertices.count,
              v3Index < mesh.vertices.count else {
            return SIMD3<Float>(0, 0, 0)
        }
        
        let v1 = mesh.vertices[v1Index]
        let v2 = mesh.vertices[v2Index]
        let v3 = mesh.vertices[v3Index]
        
        return (v1 + v2 + v3) / 3.0
    }
    
    /// Generate PanelDTO objects from final cluster assignments
    private func generatePanels(
        mesh: MeshDTO,
        assignments: [Int],
        k: Int
    ) throws -> [PanelDTO] {
        let colors: [ColorDTO] = [
            .red, .blue, .green, .yellow, .orange, .purple, .cyan, .magenta,
            ColorDTO(red: 0.5, green: 0.5, blue: 0.5), // Gray
            ColorDTO(red: 0.6, green: 0.4, blue: 0.2)   // Brown
        ]
        
        var panels: [PanelDTO] = []
        
        for clusterIndex in 0..<k {
            var triangleIndices: [Int] = []
            var vertexIndices: Set<Int> = []
            
            // Collect all triangles and vertices for this cluster
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
            
            // Only create panel if it has valid geometry
            if !triangleIndices.isEmpty && !vertexIndices.isEmpty {
                let panel = PanelDTO(
                    vertexIndices: vertexIndices,
                    triangleIndices: triangleIndices,
                    color: colors[clusterIndex % colors.count]
                )
                panels.append(panel)
            }
        }
        
        // Handle case where some clusters might be empty
        if panels.isEmpty {
            throw SegmentationError.segmentationFailed("No valid panels generated")
        }
        
        return panels
    }
}

// MARK: - Service Registration

@available(iOS 18.0, *)
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