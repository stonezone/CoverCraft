import Foundation
import simd
import os
#if canImport(UIKit)
import UIKit
#endif

/// Service responsible for segmenting mesh into panels
public actor MeshSegmentationService: MeshSegmentationServiceProtocol {
    
    private let logger = Logger(subsystem: "com.covercraft", category: "segmentation")
    
    public init() {}
    
    public func segmentMesh(_ mesh: Mesh, targetPanelCount: Int) async throws -> [Panel] {
        logger.info("Starting segmentation with target panel count: \(targetPanelCount)")
        logger.debug("Mesh stats - vertices: \(mesh.vertices.count), triangles: \(mesh.triangleCount)")
        
        // Validate input
        guard mesh.triangleCount > 0 else {
            throw SegmentationError.emptyMesh
        }
        
        // Step 1: Compute face normals
        let faceNormals = mesh.computeFaceNormals()
        
        // Step 2: Cluster faces using k-means
        let clusterAssignments = try performKMeansClustering(
            normals: faceNormals,
            clusterCount: min(targetPanelCount, faceNormals.count)
        )
        
        // Step 3: Group connected faces into panels
        let panels = groupConnectedFaces(
            mesh: mesh,
            clusterAssignments: clusterAssignments
        )
        
        // Step 4: Balance panel sizes
        return balancePanelSizes(panels, targetCount: targetPanelCount)
    }
    
    private func performKMeansClustering(normals: [SIMD3<Float>], clusterCount: Int) throws -> [Int] {
        guard !normals.isEmpty else {
            throw SegmentationError.invalidInput
        }
        
        logger.debug("Initializing \(clusterCount) clusters using k-means++")
        
        // Initialize cluster centers using k-means++
        var centers = try kMeansPlusPlusInit(normals: normals, clusterCount: clusterCount)
        var assignments = Array(repeating: 0, count: normals.count)
        
        // K-means iterations
        for _ in 0..<50 {
            // Assign each normal to nearest center
            for (index, normal) in normals.enumerated() {
                var bestCluster = 0
                var bestDistance = Float.greatestFiniteMagnitude
                
                for (clusterIndex, center) in centers.enumerated() {
                    let distance = simd_distance(normal, center)
                    if distance < bestDistance {
                        bestDistance = distance
                        bestCluster = clusterIndex
                    }
                }
                
                assignments[index] = bestCluster
            }
            
            // Update centers
            var newCenters: [SIMD3<Float>] = []
            for clusterIndex in 0..<clusterCount {
                let clusterNormals = normals.enumerated()
                    .filter { assignments[$0.offset] == clusterIndex }
                    .map { $0.element }
                
                if !clusterNormals.isEmpty {
                    let sum = clusterNormals.reduce(SIMD3<Float>(0, 0, 0), +)
                    newCenters.append(simd_normalize(sum))
                } else {
                    newCenters.append(centers[clusterIndex])
                }
            }
            
            centers = newCenters
        }
        
        return assignments
    }
    
    /// K-means++ initialization algorithm for better cluster center selection
    private func kMeansPlusPlusInit(normals: [SIMD3<Float>], clusterCount: Int) throws -> [SIMD3<Float>] {
        guard clusterCount > 0 && clusterCount <= normals.count else {
            throw SegmentationError.invalidInput
        }
        
        var centers: [SIMD3<Float>] = []
        var rng = SystemRandomNumberGenerator()
        
        // Choose first center randomly
        let firstCenter = normals.randomElement(using: &rng)!
        centers.append(firstCenter)
        
        logger.debug("Selected first center using random selection")
        
        // Choose remaining centers using k-means++ probability distribution
        for centerIndex in 1..<clusterCount {
            var distances: [Float] = []
            var totalDistance: Float = 0
            
            // Calculate minimum distance to existing centers for each point
            for normal in normals {
                var minDistance = Float.greatestFiniteMagnitude
                for center in centers {
                    let distance = simd_distance(normal, center)
                    minDistance = min(minDistance, distance)
                }
                let squaredDistance = minDistance * minDistance
                distances.append(squaredDistance)
                totalDistance += squaredDistance
            }
            
            // Select next center with probability proportional to squared distance
            let randomValue = Float.random(in: 0...totalDistance, using: &rng)
            var cumulativeDistance: Float = 0
            
            for (index, distance) in distances.enumerated() {
                cumulativeDistance += distance
                if cumulativeDistance >= randomValue {
                    centers.append(normals[index])
                    logger.debug("Selected center \(centerIndex + 1) using k-means++ at index \(index)")
                    break
                }
            }
        }
        
        logger.info("K-means++ initialization complete with \(centers.count) centers")
        return centers
    }
    
    private func groupConnectedFaces(mesh: Mesh, clusterAssignments: [Int]) -> [Panel] {
        // Build adjacency map for faces
        let adjacencyMap = buildFaceAdjacency(mesh: mesh)
        var visited = Set<Int>()
        var panels: [Panel] = []
        let colors = generateDistinctColors(count: 20)
        
        // Group connected faces with same cluster assignment
        for faceIndex in 0..<mesh.triangleCount {
            guard !visited.contains(faceIndex) else { continue }
            
            let clusterLabel = clusterAssignments[faceIndex]
            var currentPanel = Panel(
                vertexIndices: [],
                triangleIndices: [],
                color: colors[panels.count % colors.count]
            )
            
            // BFS to find connected component
            var queue = [faceIndex]
            visited.insert(faceIndex)
            
            while !queue.isEmpty {
                let current = queue.removeFirst()
                
                // Add face to panel
                let baseIndex = current * 3
                for i in 0..<3 {
                    currentPanel.vertexIndices.insert(mesh.triangleIndices[baseIndex + i])
                    currentPanel.triangleIndices.append(mesh.triangleIndices[baseIndex + i])
                }
                
                // Check adjacent faces
                if let neighbors = adjacencyMap[current] {
                    for neighbor in neighbors {
                        if !visited.contains(neighbor) && 
                           clusterAssignments[neighbor] == clusterLabel {
                            visited.insert(neighbor)
                            queue.append(neighbor)
                        }
                    }
                }
            }
            
            if currentPanel.isValid {
                panels.append(currentPanel)
            }
        }
        
        logger.info("Segmentation complete - generated \(panels.count) panels")
        return panels
    }
    
    private func buildFaceAdjacency(mesh: Mesh) -> [Int: Set<Int>] {
        var adjacency: [Int: Set<Int>] = [:]
        var edgeToFace: [Edge: Int] = [:]
        
        for faceIndex in 0..<mesh.triangleCount {
            let baseIndex = faceIndex * 3
            let vertices = [
                mesh.triangleIndices[baseIndex],
                mesh.triangleIndices[baseIndex + 1],
                mesh.triangleIndices[baseIndex + 2]
            ]
            
            // Create edges for this face
            let edges = [
                Edge(vertices[0], vertices[1]),
                Edge(vertices[1], vertices[2]),
                Edge(vertices[2], vertices[0])
            ]
            
            // Check for shared edges with other faces
            for edge in edges {
                if let otherFace = edgeToFace[edge] {
                    adjacency[faceIndex, default: []].insert(otherFace)
                    adjacency[otherFace, default: []].insert(faceIndex)
                } else {
                    edgeToFace[edge] = faceIndex
                }
            }
        }
        
        return adjacency
    }
    
    private func balancePanelSizes(_ panels: [Panel], targetCount: Int) -> [Panel] {
        var workingPanels = panels
        
        // Merge small panels if we have too many
        while workingPanels.count > targetCount && workingPanels.count > 1 {
            // Find two smallest panels
            let sorted = workingPanels.enumerated()
                .sorted { $0.element.triangleIndices.count < $1.element.triangleIndices.count }
            
            guard sorted.count >= 2 else { break }
            
            let panel1 = sorted[0].element
            let panel2 = sorted[1].element
            
            // Merge panels
            let merged = Panel(
                vertexIndices: panel1.vertexIndices.union(panel2.vertexIndices),
                triangleIndices: panel1.triangleIndices + panel2.triangleIndices,
                color: panel1.color
            )
            
            // Remove old panels and add merged
            workingPanels.removeAll { $0.id == panel1.id || $0.id == panel2.id }
            workingPanels.append(merged)
        }
        
        return workingPanels
    }
    
    private func generateDistinctColors(count: Int) -> [UIColor] {
        var colors: [UIColor] = []
        let hueStep = 1.0 / CGFloat(count)
        
        for i in 0..<count {
            let hue = CGFloat(i) * hueStep
            colors.append(UIColor(hue: hue, saturation: 0.7, brightness: 0.9, alpha: 1.0))
        }
        
        return colors
    }
    
    private struct Edge: Hashable {
        let vertex1: Int
        let vertex2: Int
        
        init(_ v1: Int, _ v2: Int) {
            vertex1 = min(v1, v2)
            vertex2 = max(v1, v2)
        }
    }
    
    public enum SegmentationError: LocalizedError {
        case emptyMesh
        case invalidInput
        case clusteringFailed
        
        public var errorDescription: String? {
            switch self {
            case .emptyMesh:
                return "Cannot segment an empty mesh"
            case .invalidInput:
                return "Invalid input parameters for segmentation"
            case .clusteringFailed:
                return "Failed to cluster mesh faces"
            }
        }
    }
}