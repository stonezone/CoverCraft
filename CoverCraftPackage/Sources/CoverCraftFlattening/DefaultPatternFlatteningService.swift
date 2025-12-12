// Version: 1.0.0
// CoverCraft Flattening Module - Default Pattern Flattening Implementation

import Foundation
import CoreGraphics
import simd
import Logging
import CoverCraftCore
import CoverCraftDTO
import Accelerate

/// Default implementation of pattern flattening service  
@available(iOS 18.0, macOS 15.0, *)
public final class DefaultPatternFlatteningService: PatternFlatteningService {
    
    private let logger = Logger(label: "com.covercraft.flattening")
    private let validator = PatternValidator()
    
    public init() {
        logger.info("Pattern Flattening Service initialized")
    }
    
    public func flattenPanels(_ panels: [PanelDTO], from mesh: MeshDTO) async throws -> [FlattenedPanelDTO] {
        logger.info("Starting pattern flattening for \(panels.count) panels")
        
        guard mesh.isValid else {
            throw FlatteningError.invalidPanel("Source mesh is invalid")
        }
        
        var flattenedPanels: [FlattenedPanelDTO] = []
        
        for panel in panels {
            guard panel.isValid else {
                logger.warning("Skipping invalid panel: \(panel.id)")
                continue
            }
            
            let flattenedPanel = try await flattenSinglePanel(panel, from: mesh)
            
            // Validate the flattened panel
            let validationResult = await validator.validatePanel(flattenedPanel)
            
            // Log validation results
            if !validationResult.issues.isEmpty {
                logger.warning("Panel \(panel.id) has \(validationResult.issues.count) validation issues")
                for issue in validationResult.issues {
                    logger.warning("  - \(issue.severity): \(issue.message)")
                }
            }
            
            if !validationResult.warnings.isEmpty {
                logger.info("Panel \(panel.id) has \(validationResult.warnings.count) warnings")
                for warning in validationResult.warnings {
                    logger.info("  - \(warning.message)")
                }
            }
            
            // Only include panels that pass critical validation
            let criticalIssues = validationResult.issues.filter { $0.severity == .critical }
            if criticalIssues.isEmpty {
                flattenedPanels.append(flattenedPanel)
                logger.info("Panel \(panel.id) passed validation and added to results")
            } else {
                logger.error("Panel \(panel.id) failed critical validation and was excluded")
                for issue in criticalIssues {
                    logger.error("  - Critical: \(issue.message)")
                }
            }
        }
        
        // Validate the complete panel set
        if !flattenedPanels.isEmpty {
            let setValidation = await validator.validatePanelSet(flattenedPanels)
            logger.info("Panel set validation completed - valid: \(setValidation.isValid ? "PASS" : "FAIL")")
            
            if !setValidation.layoutIssues.isEmpty {
                logger.warning("Panel set has \(setValidation.layoutIssues.count) layout issues")
                for issue in setValidation.layoutIssues {
                    logger.warning("  - Set issue: \(issue.message)")
                }
            }
        }
        
        logger.info("Pattern flattening completed with \(flattenedPanels.count) validated panels")
        return flattenedPanels
    }
    
    public func optimizeForCutting(_ panels: [FlattenedPanelDTO]) async throws -> [FlattenedPanelDTO] {
        logger.info("Optimizing \(panels.count) panels for cutting")
        
        // Placeholder optimization - in real app this would pack panels efficiently
        var optimized = panels
        
        // Simple optimization: arrange panels in a grid layout
        var currentX: Double = 0
        var currentY: Double = 0
        var maxRowHeight: Double = 0
        let margin: Double = 20 // 20 point margin
        
        for (index, panel) in optimized.enumerated() {
            let bbox = panel.boundingBox
            
            // If panel doesn't fit in current row, start new row
            if currentX + bbox.width > 800 { // Assume max width of 800 points
                currentX = 0
                currentY += maxRowHeight + margin
                maxRowHeight = 0
            }
            
            // Translate panel to current position
            let translatedPoints = panel.points2D.map { point in
                CGPoint(
                    x: point.x - bbox.minX + currentX,
                    y: point.y - bbox.minY + currentY
                )
            }
            
            optimized[index] = FlattenedPanelDTO(
                points2D: translatedPoints,
                edges: panel.edges,
                color: panel.color,
                scaleUnitsPerMeter: panel.scaleUnitsPerMeter,
                id: panel.id,
                originalPanelId: panel.originalPanelId,
                createdAt: panel.createdAt
            )
            
            currentX += bbox.width + margin
            maxRowHeight = max(maxRowHeight, bbox.height)
        }
        
        logger.info("Panel optimization completed")
        return optimized
    }
    
    private func flattenSinglePanel(_ panel: PanelDTO, from mesh: MeshDTO) async throws -> FlattenedPanelDTO {
        logger.info("Starting LSCM flattening for panel \(panel.id)")
        
        // Extract triangulated mesh data for this panel
        let meshData = try extractPanelMesh(panel, from: mesh)
        guard meshData.vertices.count >= 3 else {
            throw FlatteningError.invalidPanel("Panel has fewer than 3 vertices")
        }
        
        // Build mesh connectivity
        let connectivity = try buildMeshConnectivity(meshData)
        
        // Ensure the panel mesh is a single connected component to avoid numerical instability
        try validateSingleComponent(connectivity: connectivity)
        
        // Find boundary vertices and parameterize them on unit circle
        let boundary = try findBoundaryVertices(connectivity)
        guard boundary.count >= 3 else {
            throw FlatteningError.invalidPanel("Panel boundary has fewer than 3 vertices")
        }
        
        // Set up LSCM sparse linear system
        let lscmSystem = try setupLSCMSystem(meshData, connectivity: connectivity, boundary: boundary)
        
        // Solve the linear system using Accelerate sparse solver
        let uvCoordinates = try solveLSCMSystem(lscmSystem)
        
        // Guard against non-finite UV coordinates which would corrupt downstream geometry
        guard uvCoordinates.allSatisfy({ $0.x.isFinite && $0.y.isFinite }) else {
            throw FlatteningError.flatteningFailed("Non-finite UV coordinates produced by LSCM solver")
        }
        
        // Scale UV coordinates to real-world units and add seam allowances
        let scaledPoints = try scaleAndAddSeamAllowances(
            uvCoordinates: uvCoordinates,
            meshData: meshData,
            boundary: boundary
        )
        
        // Create edges for the flattened panel
        let edges = try createPanelEdges(
            boundary: boundary,
            meshData: meshData,
            connectivity: connectivity
        )
        
        logger.info("LSCM flattening completed for panel \(panel.id)")
        
        return FlattenedPanelDTO(
            points2D: scaledPoints,
            edges: edges,
            color: panel.color,
            scaleUnitsPerMeter: 1000.0, // 1000 units per meter for precision
            originalPanelId: panel.id
        )
    }
    
    // MARK: - LSCM Implementation Helper Methods
    
    /// Extract mesh data specific to a panel
    private func extractPanelMesh(_ panel: PanelDTO, from mesh: MeshDTO) throws -> PanelMeshData {
        let vertexIndices = Array(panel.vertexIndices).sorted()
        let vertices = vertexIndices.compactMap { index -> SIMD3<Float>? in
            guard index < mesh.vertices.count else { return nil }
            return mesh.vertices[index]
        }
        
        guard vertices.count == vertexIndices.count else {
            throw FlatteningError.invalidPanel("Invalid vertex indices in panel")
        }
        
        // Extract triangles that belong to this panel
        var panelTriangles: [(Int, Int, Int)] = []
        let vertexSet = Set(vertexIndices)
        
        // Process triangles in groups of 3 indices
        for i in stride(from: 0, to: panel.triangleIndices.count, by: 3) {
            guard i + 2 < panel.triangleIndices.count else { continue }
            
            let v0 = panel.triangleIndices[i]
            let v1 = panel.triangleIndices[i + 1]
            let v2 = panel.triangleIndices[i + 2]
            
            // Only include triangles where all vertices belong to this panel
            if vertexSet.contains(v0) && vertexSet.contains(v1) && vertexSet.contains(v2) {
                // Map to local vertex indices
                guard let localV0 = vertexIndices.firstIndex(of: v0),
                      let localV1 = vertexIndices.firstIndex(of: v1),
                      let localV2 = vertexIndices.firstIndex(of: v2) else { continue }
                
                panelTriangles.append((localV0, localV1, localV2))
            }
        }
        
        guard !panelTriangles.isEmpty else {
            throw FlatteningError.invalidPanel("Panel has no valid triangles")
        }
        
        return PanelMeshData(
            vertices: vertices,
            triangles: panelTriangles,
            originalIndices: vertexIndices
        )
    }
    
    /// Build mesh connectivity graph
    private func buildMeshConnectivity(_ meshData: PanelMeshData) throws -> MeshConnectivity {
        var adjacency: [Int: Set<Int>] = [:]
        var edgeToTriangles: [Edge: Set<Int>] = [:]
        
        // Initialize adjacency lists
        for i in 0..<meshData.vertices.count {
            adjacency[i] = Set<Int>()
        }
        
        // Build connectivity from triangles
        for (triangleIndex, triangle) in meshData.triangles.enumerated() {
            let (v0, v1, v2) = triangle
            
            // Add edges
            let edges = [
                Edge(v0, v1),
                Edge(v1, v2),
                Edge(v2, v0)
            ]
            
            for edge in edges {
                adjacency[edge.v0]?.insert(edge.v1)
                adjacency[edge.v1]?.insert(edge.v0)
                
                if edgeToTriangles[edge] == nil {
                    edgeToTriangles[edge] = Set<Int>()
                }
                edgeToTriangles[edge]?.insert(triangleIndex)
            }
        }
        
        return MeshConnectivity(
            adjacency: adjacency,
            edgeToTriangles: edgeToTriangles,
            triangles: meshData.triangles
        )
    }
    
    /// Validate that the panel mesh forms a single connected component.
    /// Disconnected islands (often scanning noise) can cause LSCM to become unstable.
    private func validateSingleComponent(connectivity: MeshConnectivity) throws {
        guard let startVertex = connectivity.adjacency.keys.first else {
            throw FlatteningError.degenerateGeometry
        }
        
        var visited = Set<Int>()
        var stack: [Int] = [startVertex]
        visited.insert(startVertex)
        
        while let vertex = stack.popLast() {
            if let neighbors = connectivity.adjacency[vertex] {
                for neighbor in neighbors where !visited.contains(neighbor) {
                    visited.insert(neighbor)
                    stack.append(neighbor)
                }
            }
        }
        
        // If not all vertices were visited, we have multiple connected components
        if visited.count != connectivity.adjacency.count {
            throw FlatteningError.flatteningFailed("Panel mesh has multiple disconnected components")
        }
    }
    
    /// Find boundary vertices using edge-triangle connectivity
    private func findBoundaryVertices(_ connectivity: MeshConnectivity) throws -> [Int] {
        var boundaryEdges: Set<Edge> = Set()
        
        // Find edges that belong to only one triangle (boundary edges)
        for (edge, triangles) in connectivity.edgeToTriangles {
            if triangles.count == 1 {
                boundaryEdges.insert(edge)
            }
        }
        
        guard !boundaryEdges.isEmpty else {
            throw FlatteningError.degenerateGeometry
        }
        
        // Trace boundary loop
        var boundary: [Int] = []
        var visited: Set<Edge> = Set()
        
        // Start with any boundary edge
        guard let firstEdge = boundaryEdges.first else {
            throw FlatteningError.degenerateGeometry
        }
        
        var currentVertex = firstEdge.v0
        boundary.append(currentVertex)
        
        while true {
            // Find next boundary edge from current vertex
            var nextEdge: Edge?
            for edge in boundaryEdges {
                if !visited.contains(edge) && edge.contains(currentVertex) {
                    nextEdge = edge
                    break
                }
            }
            
            guard let edge = nextEdge else { break }
            
            visited.insert(edge)
            currentVertex = edge.other(currentVertex)
            
            // Check if we've completed the loop
            if currentVertex == boundary.first {
                break
            }
            
            boundary.append(currentVertex)
        }
        
        return boundary
    }
    
    /// Set up LSCM sparse linear system
    private func setupLSCMSystem(_ meshData: PanelMeshData, connectivity: MeshConnectivity, boundary: [Int]) throws -> LSCMSystem {
        // Validate edge cases (Issue #9)
        guard meshData.vertices.count >= 3 else {
            throw FlatteningError.invalidPanel("LSCM requires at least 3 vertices")
        }

        guard boundary.count >= 3 else {
            throw FlatteningError.invalidPanel("LSCM requires at least 3 boundary vertices")
        }

        guard meshData.triangles.count >= 1 else {
            throw FlatteningError.invalidPanel("LSCM requires at least 1 triangle")
        }

        let n = meshData.vertices.count
        let boundarySet = Set(boundary)
        let interiorVertices = (0..<n).filter { !boundarySet.contains($0) }
        
        // Parameterize boundary on unit circle
        var fixedUV: [Int: SIMD2<Double>] = [:]
        for (i, vertex) in boundary.enumerated() {
            let angle = 2.0 * Double.pi * Double(i) / Double(boundary.count)
            fixedUV[vertex] = SIMD2<Double>(cos(angle), sin(angle))
        }
        
        // Set up sparse matrix for Laplacian system
        var matrixEntries: [(Int, Int, Double)] = []
        var rhsU: [Double] = Array(repeating: 0.0, count: interiorVertices.count)
        var rhsV: [Double] = Array(repeating: 0.0, count: interiorVertices.count)
        
        for (localIndex, vertex) in interiorVertices.enumerated() {
            var weightSum = 0.0
            
            // Calculate cotangent weights for neighbors
            guard let neighbors = connectivity.adjacency[vertex] else { continue }
            
            for neighbor in neighbors {
                let weight = try calculateCotangentWeight(
                    vertex: vertex,
                    neighbor: neighbor,
                    meshData: meshData,
                    connectivity: connectivity
                )
                
                weightSum += weight
                
                if let neighborLocal = interiorVertices.firstIndex(of: neighbor) {
                    // Interior-interior connection
                    matrixEntries.append((localIndex, neighborLocal, -weight))
                } else if let fixedUV = fixedUV[neighbor] {
                    // Interior-boundary connection
                    rhsU[localIndex] += weight * fixedUV.x
                    rhsV[localIndex] += weight * fixedUV.y
                }
            }
            
            // Diagonal entry
            matrixEntries.append((localIndex, localIndex, weightSum))
        }
        
        return LSCMSystem(
            matrixEntries: matrixEntries,
            rhsU: rhsU,
            rhsV: rhsV,
            interiorVertices: interiorVertices,
            fixedUV: fixedUV,
            systemSize: interiorVertices.count
        )
    }
    
    /// Calculate cotangent weight for edge-based Laplacian
    private func calculateCotangentWeight(vertex: Int, neighbor: Int, meshData: PanelMeshData, connectivity: MeshConnectivity) throws -> Double {
        let edge = Edge(vertex, neighbor)
        
        guard let triangles = connectivity.edgeToTriangles[edge] else {
            throw FlatteningError.degenerateGeometry
        }
        
        var cotangentSum = 0.0
        
        for triangleIndex in triangles {
            let triangle = connectivity.triangles[triangleIndex]
            
            // Find the third vertex (opposite to the edge)
            let vertices = [triangle.0, triangle.1, triangle.2]
            guard let oppositeVertex = vertices.first(where: { $0 != vertex && $0 != neighbor }) else {
                continue
            }
            
            // Calculate cotangent of angle at opposite vertex
            let p0 = meshData.vertices[vertex]
            let p1 = meshData.vertices[neighbor]
            let p2 = meshData.vertices[oppositeVertex]
            
            // Vectors from opposite vertex to edge endpoints
            let v1 = p0 - p2
            let v2 = p1 - p2
            
            // Cotangent = cos/sin = dot/(cross magnitude)
            let dot = simd_dot(v1, v2)
            let cross = simd_cross(v1, v2)
            let crossLength = simd_length(cross)
            
            guard crossLength > 1e-8 else { continue } // Avoid degenerate triangles
            
            let cotangent = dot / crossLength
            cotangentSum += Double(cotangent)
        }
        
        return max(cotangentSum * 0.5, 1e-6) // Clamp to avoid numerical issues
    }
    
    /// Solve LSCM system using Accelerate sparse solver
    private func solveLSCMSystem(_ system: LSCMSystem) throws -> [SIMD2<Double>] {
        let n = system.systemSize
        if n == 0 {
            // No interior vertices: the solution is fully determined by fixed boundary UVs.
            // This can happen for very small panels (e.g., a single triangle).
            let totalVertexCount = system.interiorVertices.count + system.fixedUV.count
            var fullUVCoordinates: [SIMD2<Double>] = Array(repeating: SIMD2<Double>(0, 0), count: totalVertexCount)
            for (vertex, uv) in system.fixedUV {
                fullUVCoordinates[vertex] = uv
            }
            return fullUVCoordinates
        }
        
        // Reserved for future sparse solver implementation
        // These variables are prepared but not yet used until we integrate Accelerate's sparse solver
        let _rowIndices = system.matrixEntries.map { Int32($0.0) }
        let _colIndices = system.matrixEntries.map { Int32($0.1) }
        let _values = system.matrixEntries.map { $0.2 }
        let _solutionU = system.rhsU
        let _info: Int32 = 0

        // Suppress unused variable warnings
        _ = _rowIndices
        _ = _colIndices
        _ = _values
        _ = _solutionU
        _ = _info
        
        // Use iterative solver for better performance with sparse matrices
        let maxIterations: Int32 = 1000
        let tolerance = 1e-8
        
        // Simple conjugate gradient implementation for sparse positive definite system
        let uvSolution = try solveWithConjugateGradient(
            matrixEntries: system.matrixEntries,
            rhsU: system.rhsU,
            rhsV: system.rhsV,
            systemSize: n,
            tolerance: tolerance,
            maxIterations: Int(maxIterations)
        )
        
        // Combine interior and boundary solutions
        var fullUVCoordinates: [SIMD2<Double>] = Array(repeating: SIMD2<Double>(0, 0), count: system.interiorVertices.count + system.fixedUV.count)
        
        // Set interior vertices
        for (localIndex, globalIndex) in system.interiorVertices.enumerated() {
            fullUVCoordinates[globalIndex] = uvSolution[localIndex]
        }
        
        // Set boundary vertices
        for (vertex, uv) in system.fixedUV {
            fullUVCoordinates[vertex] = uv
        }
        
        return fullUVCoordinates
    }
    
    /// Conjugate gradient solver for sparse symmetric positive definite systems
    private func solveWithConjugateGradient(
        matrixEntries: [(Int, Int, Double)],
        rhsU: [Double],
        rhsV: [Double],
        systemSize: Int,
        tolerance: Double,
        maxIterations: Int
    ) throws -> [SIMD2<Double>] {
        
        // Solve U and V systems separately (they share the same matrix structure)
        let solutionU = try cgSolve(matrixEntries, rhs: rhsU, systemSize: systemSize, tolerance: tolerance, maxIterations: maxIterations)
        let solutionV = try cgSolve(matrixEntries, rhs: rhsV, systemSize: systemSize, tolerance: tolerance, maxIterations: maxIterations)
        
        var result: [SIMD2<Double>] = []
        for i in 0..<systemSize {
            result.append(SIMD2<Double>(solutionU[i], solutionV[i]))
        }
        
        return result
    }
    
    /// Single conjugate gradient solve
    private func cgSolve(_ matrixEntries: [(Int, Int, Double)], rhs: [Double], systemSize: Int, tolerance: Double, maxIterations: Int) throws -> [Double] {
        let n = systemSize
        var x = Array(repeating: 0.0, count: n) // Initial guess
        var r = rhs // residual
        var p = rhs // search direction
        
        // Calculate rsold = r^T * r
        var rsold = 0.0
        var tempResult = Array(repeating: 0.0, count: n)
        vDSP_vmulD(r, 1, r, 1, &tempResult, 1, vDSP_Length(n))
        vDSP_sveD(tempResult, 1, &rsold, vDSP_Length(n))

        // Trivial solution: if RHS is (near) zero, x=0 is already a valid solution.
        if sqrt(rsold) < tolerance {
            return x
        }
        
        for iteration in 0..<maxIterations {
            // Compute Ap
            var Ap = Array(repeating: 0.0, count: n)
            for (row, col, value) in matrixEntries {
                if row < n && col < n {
                    Ap[row] += value * p[col]
                }
            }
            
            // alpha = rsold / (p^T * Ap)
            var pAp = 0.0
            vDSP_vmulD(p, 1, Ap, 1, &tempResult, 1, vDSP_Length(n))
            vDSP_sveD(tempResult, 1, &pAp, vDSP_Length(n))
            
            guard abs(pAp) > 1e-14 else {
                // If residual is already tiny, treat as converged; otherwise the system is ill-conditioned.
                if sqrt(rsold) < tolerance {
                    break
                }
                throw FlatteningError.flatteningFailed("Singular matrix in CG solver")
            }
            
            let alpha = rsold / pAp
            
            // x = x + alpha * p
            var alpha_var = alpha
            var alphaP = Array(repeating: 0.0, count: n)
            vDSP_vsmulD(p, 1, &alpha_var, &alphaP, 1, vDSP_Length(n))
            vDSP_vaddD(x, 1, alphaP, 1, &x, 1, vDSP_Length(n))
            
            // r = r - alpha * Ap
            var alphaAp = Array(repeating: 0.0, count: n)
            vDSP_vsmulD(Ap, 1, &alpha_var, &alphaAp, 1, vDSP_Length(n))
            vDSP_vsubD(r, 1, alphaAp, 1, &r, 1, vDSP_Length(n))
            
            // Check convergence: rsnew = r^T * r
            var rsnew = 0.0
            vDSP_vmulD(r, 1, r, 1, &tempResult, 1, vDSP_Length(n))
            vDSP_sveD(tempResult, 1, &rsnew, vDSP_Length(n))
            
            if sqrt(rsnew) < tolerance {
                logger.info("CG converged in \(iteration + 1) iterations")
                break
            }
            
            // beta = rsnew / rsold
            var beta = rsnew / rsold
            
            // p = r + beta * p
            var betaP = Array(repeating: 0.0, count: n)
            vDSP_vsmulD(p, 1, &beta, &betaP, 1, vDSP_Length(n))
            vDSP_vaddD(r, 1, betaP, 1, &p, 1, vDSP_Length(n))
            
            rsold = rsnew
        }
        
        return x
    }
    
    /// Scale UV coordinates to real-world units and add seam allowances
    private func scaleAndAddSeamAllowances(
        uvCoordinates: [SIMD2<Double>],
        meshData: PanelMeshData,
        boundary: [Int]
    ) throws -> [CGPoint] {
        guard !uvCoordinates.isEmpty else {
            throw FlatteningError.flatteningFailed("Empty UV coordinates")
        }
        
        // Calculate scaling factor from 3D to 2D
        let scaleFactor = try calculateScaleFactor(uvCoordinates: uvCoordinates, meshData: meshData)
        
        // Apply scaling and convert to CGPoint (millimeters)
        let scaledPoints = uvCoordinates.map { uv in
            CGPoint(
                x: uv.x * scaleFactor * 1000.0, // Convert to millimeters
                y: uv.y * scaleFactor * 1000.0
            )
        }

        // Seam allowances are applied at export time so they can be user-configurable and consistent
        // across PDF/SVG/PNG outputs.
        return scaledPoints
    }
    
    /// Calculate appropriate scale factor from 3D to UV mapping
    private func calculateScaleFactor(uvCoordinates: [SIMD2<Double>], meshData: PanelMeshData) throws -> Double {
        // Calculate average edge length ratio between 3D and UV space
        var ratioSum = 0.0
        var ratioCount = 0
        
        for triangle in meshData.triangles {
            let indices = [triangle.0, triangle.1, triangle.2]
            
            for i in 0..<3 {
                let j = (i + 1) % 3
                let v1 = indices[i]
                let v2 = indices[j]
                
                guard v1 < meshData.vertices.count && v2 < meshData.vertices.count &&
                      v1 < uvCoordinates.count && v2 < uvCoordinates.count else { continue }
                
                // 3D edge length
                let p1_3d = meshData.vertices[v1]
                let p2_3d = meshData.vertices[v2]
                let length3D = simd_distance(p1_3d, p2_3d)
                
                // UV edge length
                let p1_uv = uvCoordinates[v1]
                let p2_uv = uvCoordinates[v2]
                let lengthUV = simd_distance(p1_uv, p2_uv)
                
                if lengthUV > 1e-8 {
                    ratioSum += Double(length3D) / lengthUV
                    ratioCount += 1
                }
            }
        }
        
        guard ratioCount > 0 else {
            throw FlatteningError.flatteningFailed("Unable to calculate scale factor")
        }
        
        return ratioSum / Double(ratioCount)
    }
    
    /// Create edges for the flattened panel
    private func createPanelEdges(
        boundary: [Int],
        meshData: PanelMeshData,
        connectivity: MeshConnectivity
    ) throws -> [EdgeDTO] {
        var edges: [EdgeDTO] = []
        
        // Add boundary edges as cut lines
        for i in 0..<boundary.count {
            let start = boundary[i]
            let end = boundary[(i + 1) % boundary.count]
            
            guard start < meshData.vertices.count && end < meshData.vertices.count else { continue }
            
            let original3DLength = Double(simd_distance(meshData.vertices[start], meshData.vertices[end]))
            
            edges.append(EdgeDTO(
                startIndex: start,
                endIndex: end,
                type: .cutLine,
                original3DLength: original3DLength
            ))
        }
        
        // Add seam allowance edges
        let seamAllowanceWidth = 5.0 // 5mm
        for i in 0..<boundary.count {
            let start = boundary[i]
            let end = boundary[(i + 1) % boundary.count]
            
            edges.append(EdgeDTO(
                startIndex: start,
                endIndex: end,
                type: .seamAllowance,
                original3DLength: seamAllowanceWidth
            ))
        }
        
        return edges
    }
}

// MARK: - Supporting Data Structures

/// Mesh data specific to a single panel
private struct PanelMeshData {
    let vertices: [SIMD3<Float>]
    let triangles: [(Int, Int, Int)]
    let originalIndices: [Int]
}

/// Mesh connectivity information
private struct MeshConnectivity {
    let adjacency: [Int: Set<Int>]
    let edgeToTriangles: [Edge: Set<Int>]
    let triangles: [(Int, Int, Int)]
}

/// Represents an undirected edge in the mesh
private struct Edge: Hashable {
    let v0: Int
    let v1: Int
    
    init(_ v0: Int, _ v1: Int) {
        // Ensure consistent ordering for undirected edge
        if v0 < v1 {
            self.v0 = v0
            self.v1 = v1
        } else {
            self.v0 = v1
            self.v1 = v0
        }
    }
    
    func contains(_ vertex: Int) -> Bool {
        return vertex == v0 || vertex == v1
    }
    
    func other(_ vertex: Int) -> Int {
        if vertex == v0 {
            return v1
        } else if vertex == v1 {
            return v0
        } else {
            fatalError("Vertex \(vertex) is not part of edge (\(v0), \(v1))")
        }
    }
}

/// LSCM linear system data
private struct LSCMSystem {
    let matrixEntries: [(Int, Int, Double)]  // (row, col, value) triplets
    let rhsU: [Double]                      // Right-hand side for U coordinates
    let rhsV: [Double]                      // Right-hand side for V coordinates
    let interiorVertices: [Int]             // Indices of interior vertices
    let fixedUV: [Int: SIMD2<Double>]       // Fixed boundary UV coordinates
    let systemSize: Int                     // Size of the linear system
}

// MARK: - Service Registration

@available(iOS 18.0, macOS 15.0, *)
public extension DefaultDependencyContainer {
    
    /// Register flattening services
    func registerFlatteningServices() {
        let logger = Logger(label: "com.covercraft.flattening.registration")
        logger.info("Registering flattening services")
        
        registerSingleton({
            DefaultPatternFlatteningService()
        }, for: PatternFlatteningService.self)
        
        logger.info("Flattening services registration completed")
    }
}
