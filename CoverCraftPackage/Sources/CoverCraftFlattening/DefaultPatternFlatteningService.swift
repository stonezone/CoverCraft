// Version: 1.0.0
// CoverCraft Flattening Module - Default Pattern Flattening Implementation

import Foundation
import CoreGraphics
import simd
import Logging
import CoverCraftCore
import CoverCraftDTO

/// Default implementation of pattern flattening service  
@available(iOS 18.0, *)
public final class DefaultPatternFlatteningService: PatternFlatteningService {
    
    private let logger = Logger(label: "com.covercraft.flattening")
    
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
            flattenedPanels.append(flattenedPanel)
        }
        
        logger.info("Pattern flattening completed with \(flattenedPanels.count) flattened panels")
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
        // Extract vertices for this panel
        let panelVertices = panel.vertexIndices.compactMap { index in
            guard index < mesh.vertices.count else { return nil }
            return mesh.vertices[index]
        }
        
        guard panelVertices.count >= 3 else {
            throw FlatteningError.invalidPanel("Panel has fewer than 3 vertices")
        }
        
        // Simple flattening: project to XY plane and center
        let centroid = panelVertices.reduce(SIMD3<Float>.zero) { sum, vertex in
            sum + vertex
        } / Float(panelVertices.count)
        
        let flattened2DPoints = panelVertices.map { vertex in
            let relative = vertex - centroid
            return CGPoint(x: Double(relative.x * 100), y: Double(relative.z * 100)) // Scale up for visibility
        }
        
        // Create edges connecting consecutive points
        var edges: [EdgeDTO] = []
        for i in 0..<flattened2DPoints.count {
            let nextIndex = (i + 1) % flattened2DPoints.count
            let edge = EdgeDTO(
                startIndex: i,
                endIndex: nextIndex,
                type: .cutLine,
                original3DLength: Double(simd_distance(panelVertices[i], panelVertices[nextIndex]))
            )
            edges.append(edge)
        }
        
        return FlattenedPanelDTO(
            points2D: flattened2DPoints,
            edges: edges,
            color: panel.color,
            scaleUnitsPerMeter: 100.0, // 100 units per meter
            originalPanelId: panel.id
        )
    }
}

// MARK: - Service Registration

@available(iOS 18.0, *)
public extension DefaultDependencyContainer {
    
    /// Register flattening services
    func registerFlatteningServices() {
        logger.info("Registering flattening services")
        
        registerSingleton({
            DefaultPatternFlatteningService()
        }, for: PatternFlatteningService.self)
        
        logger.info("Flattening services registration completed")
    }
}