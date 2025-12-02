// Version: 1.0.0
// CoverCraft Flattening Module - Comprehensive Pattern Validation System

import Foundation
import CoreGraphics
import simd
import Logging
import CoverCraftCore
import CoverCraftDTO

/// Configuration for pattern validation parameters
@available(iOS 18.0, macOS 15.0, *)
public struct PatternValidatorConfig: Sendable, Codable {
    /// Standard fabric widths in millimeters
    public let fabricWidths: [Double]

    /// Minimum seam allowance in millimeters
    public let minimumSeamAllowance: Double

    /// Maximum seam allowance in millimeters
    public let maximumSeamAllowance: Double

    /// Default configuration with common fabric widths
    /// - 1143.0mm (45 inches)
    /// - 1524.0mm (60 inches)
    /// - 1372.0mm (54 inches)
    /// - 1067.0mm (42 inches)
    public static let `default` = PatternValidatorConfig(
        fabricWidths: [1143.0, 1524.0, 1372.0, 1067.0],
        minimumSeamAllowance: 3.0,
        maximumSeamAllowance: 15.0
    )

    /// Initialize pattern validator configuration
    /// - Parameters:
    ///   - fabricWidths: Array of available fabric widths in millimeters
    ///   - minimumSeamAllowance: Minimum acceptable seam allowance in millimeters (default: 3.0)
    ///   - maximumSeamAllowance: Maximum acceptable seam allowance in millimeters (default: 15.0)
    public init(
        fabricWidths: [Double],
        minimumSeamAllowance: Double = 3.0,
        maximumSeamAllowance: Double = 15.0
    ) {
        self.fabricWidths = fabricWidths
        self.minimumSeamAllowance = minimumSeamAllowance
        self.maximumSeamAllowance = maximumSeamAllowance
    }
}

/// Comprehensive pattern validation system for manufacturability and sewability
///
/// This validator ensures that generated patterns are:
/// - Geometrically sound (no overlaps, valid shapes)
/// - Manufacturable (proper seam allowances, fabric constraints)
/// - Sewable (minimum dimensions, grain line consistency)
@available(iOS 18.0, macOS 15.0, *)
public final class PatternValidator: PatternValidationService {

    // MARK: - Constants

    /// Standard seam allowance in millimeters
    public static let standardSeamAllowance: Double = 5.0

    /// Minimum panel area in square millimeters (1cm²)
    public static let minimumPanelArea: Double = 100.0

    /// Minimum edge length in millimeters
    public static let minimumEdgeLength: Double = 10.0

    /// Maximum distortion factor for flattening validation
    public static let maximumDistortionFactor: Double = 1.5

    // MARK: - Properties

    private let logger = Logger(label: "com.covercraft.patternvalidator")
    private let config: PatternValidatorConfig

    // MARK: - Initialization

    /// Initialize pattern validator with custom configuration
    /// - Parameter config: Validation configuration (defaults to .default if not specified)
    public init(config: PatternValidatorConfig = .default) {
        self.config = config
        logger.info("Pattern Validator initialized with fabric widths: \(config.fabricWidths)")
    }
    
    // MARK: - Public Validation Methods
    
    /// Validate a single flattened panel for manufacturability
    /// - Parameter panel: The flattened panel to validate
    /// - Returns: Validation result with detailed feedback
    public func validatePanel(_ panel: FlattenedPanelDTO) async -> PatternValidationResult {
        logger.info("Validating panel \(panel.id)")
        
        var issues: [ValidationIssue] = []
        var warnings: [ValidationWarning] = []
        
        // Basic geometric validation
        issues.append(contentsOf: validateBasicGeometry(panel))
        
        // Seam allowance validation
        let seamIssues = validateSeamAllowances(panel)
        issues.append(contentsOf: seamIssues.issues)
        warnings.append(contentsOf: seamIssues.warnings)
        
        // Panel size validation
        issues.append(contentsOf: validatePanelSize(panel))
        
        // Edge validation
        issues.append(contentsOf: validateEdges(panel))
        
        // Self-intersection validation
        let intersectionIssues = await validateSelfIntersections(panel)
        issues.append(contentsOf: intersectionIssues)
        
        // Distortion validation
        let distortionWarnings = validateDistortion(panel)
        warnings.append(contentsOf: distortionWarnings)
        
        let result = PatternValidationResult(
            isValid: issues.isEmpty,
            issues: issues,
            warnings: warnings,
            panelId: panel.id,
            validatedAt: Date()
        )
        
        logger.info("Panel \(panel.id) validation completed - Valid: \(result.isValid), Issues: \(issues.count), Warnings: \(warnings.count)")
        
        return result
    }
    
    /// Validate multiple panels for layout compatibility
    /// - Parameter panels: Array of flattened panels to validate
    /// - Returns: Comprehensive validation result for the entire pattern set
    public func validatePanelSet(_ panels: [FlattenedPanelDTO]) async -> PatternSetValidationResult {
        logger.info("Validating pattern set with \(panels.count) panels")
        
        var panelResults: [PatternValidationResult] = []
        var layoutIssues: [ValidationIssue] = []
        var fabricCompatibility: FabricCompatibilityResult? = nil
        
        // Validate each panel individually
        for panel in panels {
            let result = await validatePanel(panel)
            panelResults.append(result)
        }
        
        // Validate panel overlaps
        let overlapIssues = await validatePanelOverlaps(panels)
        layoutIssues.append(contentsOf: overlapIssues)
        
        // Validate fabric compatibility
        fabricCompatibility = validateFabricCompatibility(panels)
        
        // Validate grain line consistency
        let grainLineIssues = validateGrainLineConsistency(panels)
        layoutIssues.append(contentsOf: grainLineIssues)
        
        let allIssues = panelResults.flatMap { $0.issues } + layoutIssues
        let allWarnings = panelResults.flatMap { $0.warnings }
        
        let result = PatternSetValidationResult(
            isValid: allIssues.isEmpty,
            panelResults: panelResults,
            layoutIssues: layoutIssues,
            fabricCompatibility: fabricCompatibility,
            totalArea: panels.reduce(0) { $0 + $1.area },
            recommendedFabricWidth: fabricCompatibility?.recommendedWidth,
            validatedAt: Date()
        )
        
        logger.info("Pattern set validation completed - Valid: \(result.isValid), Total Issues: \(allIssues.count), Total Warnings: \(allWarnings.count)")
        
        return result
    }
    
    /// Validate fabric utilization efficiency
    /// - Parameters:
    ///   - panels: Array of panels to check
    ///   - fabricWidth: Available fabric width in millimeters
    /// - Returns: Fabric utilization analysis
    public func validateFabricUtilization(_ panels: [FlattenedPanelDTO], fabricWidth: Double) -> FabricUtilizationResult {
        logger.info("Validating fabric utilization for \(panels.count) panels with fabric width \(fabricWidth)mm")
        
        // Calculate total panel area
        let totalPanelArea = panels.reduce(0) { $0 + $1.area }
        
        // Estimate required fabric length using bin packing
        let requiredLength = estimateRequiredFabricLength(panels, fabricWidth: fabricWidth)
        let totalFabricArea = requiredLength * fabricWidth
        
        // Calculate utilization efficiency
        let efficiency = totalPanelArea / totalFabricArea
        
        // Check if panels fit within fabric width
        let oversizedPanels = panels.filter { panel in
            panel.boundingBox.width > fabricWidth
        }
        
        return FabricUtilizationResult(
            totalPanelArea: totalPanelArea,
            totalFabricArea: totalFabricArea,
            efficiency: efficiency,
            requiredFabricLength: requiredLength,
            oversizedPanels: oversizedPanels.map { $0.id },
            isEfficient: efficiency > 0.65, // 65% is considered good efficiency
            recommendations: generateUtilizationRecommendations(efficiency: efficiency, oversizedPanels: oversizedPanels)
        )
    }
    
    // MARK: - Private Validation Methods
    
    /// Validate basic geometric properties
    private func validateBasicGeometry(_ panel: FlattenedPanelDTO) -> [ValidationIssue] {
        var issues: [ValidationIssue] = []
        
        // Check minimum points requirement
        if panel.points2D.count < 3 {
            issues.append(ValidationIssue(
                severity: .critical,
                type: .geometryError,
                message: "Panel must have at least 3 points",
                panelId: panel.id,
                location: nil
            ))
        }
        
        // Check for degenerate points (duplicates)
        let uniquePoints = Set(panel.points2D.map { "\($0.x),\($0.y)" })
        if uniquePoints.count != panel.points2D.count {
            issues.append(ValidationIssue(
                severity: .error,
                type: .geometryError,
                message: "Panel contains duplicate points",
                panelId: panel.id,
                location: nil
            ))
        }
        
        // Check for valid bounding box
        let bbox = panel.boundingBox
        if bbox.width <= 0 || bbox.height <= 0 {
            issues.append(ValidationIssue(
                severity: .critical,
                type: .geometryError,
                message: "Panel has invalid bounding box",
                panelId: panel.id,
                location: CGPoint(x: bbox.midX, y: bbox.midY)
            ))
        }
        
        // Check for collinear points (all points on a line)
        if areAllPointsCollinear(panel.points2D) {
            issues.append(ValidationIssue(
                severity: .critical,
                type: .geometryError,
                message: "All panel points are collinear",
                panelId: panel.id,
                location: nil
            ))
        }
        
        return issues
    }
    
    /// Validate seam allowances
    private func validateSeamAllowances(_ panel: FlattenedPanelDTO) -> (issues: [ValidationIssue], warnings: [ValidationWarning]) {
        var issues: [ValidationIssue] = []
        var warnings: [ValidationWarning] = []
        
        let seamEdges = panel.edges.filter { $0.type == .seamAllowance }
        
        for edge in seamEdges {
            guard edge.startIndex < panel.points2D.count && edge.endIndex < panel.points2D.count else {
                continue
            }
            
            let startPoint = panel.points2D[edge.startIndex]
            let endPoint = panel.points2D[edge.endIndex]
            let edgeLength = distance(startPoint, endPoint)
            
            // Check if seam allowance is within acceptable range
            if edgeLength < config.minimumSeamAllowance {
                issues.append(ValidationIssue(
                    severity: .error,
                    type: .seamAllowanceError,
                    message: "Seam allowance too narrow: \(String(format: "%.1f", edgeLength))mm < \(config.minimumSeamAllowance)mm minimum",
                    panelId: panel.id,
                    location: CGPoint(x: (startPoint.x + endPoint.x) / 2, y: (startPoint.y + endPoint.y) / 2)
                ))
            } else if edgeLength > config.maximumSeamAllowance {
                warnings.append(ValidationWarning(
                    type: .seamAllowanceWarning,
                    message: "Seam allowance unusually wide: \(String(format: "%.1f", edgeLength))mm > \(config.maximumSeamAllowance)mm recommended maximum",
                    panelId: panel.id,
                    location: CGPoint(x: (startPoint.x + endPoint.x) / 2, y: (startPoint.y + endPoint.y) / 2)
                ))
            }
        }
        
        // Check for consistent seam allowance widths
        if seamEdges.count > 1 {
            let seamWidths = seamEdges.compactMap { edge -> Double? in
                guard edge.startIndex < panel.points2D.count && edge.endIndex < panel.points2D.count else { return nil }
                let startPoint = panel.points2D[edge.startIndex]
                let endPoint = panel.points2D[edge.endIndex]
                return distance(startPoint, endPoint)
            }
            
            let avgWidth = seamWidths.reduce(0, +) / Double(seamWidths.count)
            let maxDeviation = seamWidths.map { abs($0 - avgWidth) }.max() ?? 0
            
            if maxDeviation > Self.standardSeamAllowance * 0.5 {
                warnings.append(ValidationWarning(
                    type: .seamAllowanceWarning,
                    message: "Inconsistent seam allowance widths (deviation: \(String(format: "%.1f", maxDeviation))mm)",
                    panelId: panel.id,
                    location: nil
                ))
            }
        }
        
        return (issues, warnings)
    }
    
    /// Validate panel size constraints
    private func validatePanelSize(_ panel: FlattenedPanelDTO) -> [ValidationIssue] {
        var issues: [ValidationIssue] = []
        
        let area = panel.area
        let bbox = panel.boundingBox
        
        // Check minimum area
        if area < Self.minimumPanelArea {
            issues.append(ValidationIssue(
                severity: .error,
                type: .sizeError,
                message: "Panel area too small: \(String(format: "%.1f", area))mm² < \(Self.minimumPanelArea)mm² minimum",
                panelId: panel.id,
                location: CGPoint(x: bbox.midX, y: bbox.midY)
            ))
        }
        
        // Check for extremely thin panels
        let aspectRatio = max(bbox.width, bbox.height) / min(bbox.width, bbox.height)
        if aspectRatio > 20 {
            issues.append(ValidationIssue(
                severity: .warning,
                type: .sizeError,
                message: "Panel has extreme aspect ratio (\(String(format: "%.1f", aspectRatio)):1), may be difficult to handle",
                panelId: panel.id,
                location: CGPoint(x: bbox.midX, y: bbox.midY)
            ))
        }
        
        return issues
    }
    
    /// Validate edge properties
    private func validateEdges(_ panel: FlattenedPanelDTO) -> [ValidationIssue] {
        var issues: [ValidationIssue] = []
        
        for edge in panel.edges {
            guard edge.startIndex < panel.points2D.count && edge.endIndex < panel.points2D.count else {
                issues.append(ValidationIssue(
                    severity: .critical,
                    type: .geometryError,
                    message: "Edge references invalid point indices",
                    panelId: panel.id,
                    location: nil
                ))
                continue
            }
            
            let startPoint = panel.points2D[edge.startIndex]
            let endPoint = panel.points2D[edge.endIndex]
            let edgeLength = distance(startPoint, endPoint)
            
            // Check minimum edge length
            if edgeLength < Self.minimumEdgeLength {
                issues.append(ValidationIssue(
                    severity: .error,
                    type: .geometryError,
                    message: "Edge too short: \(String(format: "%.1f", edgeLength))mm < \(Self.minimumEdgeLength)mm minimum",
                    panelId: panel.id,
                    location: CGPoint(x: (startPoint.x + endPoint.x) / 2, y: (startPoint.y + endPoint.y) / 2)
                ))
            }
            
            // Validate 3D length preservation if available
            if let original3DLength = edge.original3DLength {
                let lengthRatio = edgeLength / original3DLength
                if lengthRatio < 0.5 || lengthRatio > 2.0 {
                    issues.append(ValidationIssue(
                        severity: .warning,
                        type: .distortionError,
                        message: "Edge length significantly changed from 3D (ratio: \(String(format: "%.2f", lengthRatio)))",
                        panelId: panel.id,
                        location: CGPoint(x: (startPoint.x + endPoint.x) / 2, y: (startPoint.y + endPoint.y) / 2)
                    ))
                }
            }
        }
        
        return issues
    }
    
    /// Validate for self-intersections
    private func validateSelfIntersections(_ panel: FlattenedPanelDTO) async -> [ValidationIssue] {
        var issues: [ValidationIssue] = []
        
        let cutEdges = panel.edges.filter { $0.type == .cutLine }
        
        // Check for edge intersections
        for i in 0..<cutEdges.count {
            for j in (i + 1)..<cutEdges.count {
                let edge1 = cutEdges[i]
                let edge2 = cutEdges[j]
                
                // Skip adjacent edges
                if edge1.endIndex == edge2.startIndex || edge1.startIndex == edge2.endIndex {
                    continue
                }
                
                guard edge1.startIndex < panel.points2D.count && edge1.endIndex < panel.points2D.count &&
                      edge2.startIndex < panel.points2D.count && edge2.endIndex < panel.points2D.count else {
                    continue
                }
                
                let p1 = panel.points2D[edge1.startIndex]
                let p2 = panel.points2D[edge1.endIndex]
                let p3 = panel.points2D[edge2.startIndex]
                let p4 = panel.points2D[edge2.endIndex]
                
                if let intersection = lineIntersection(p1, p2, p3, p4) {
                    issues.append(ValidationIssue(
                        severity: .critical,
                        type: .intersectionError,
                        message: "Panel edges intersect, creating invalid geometry",
                        panelId: panel.id,
                        location: intersection
                    ))
                }
            }
        }
        
        return issues
    }
    
    /// Validate distortion from 3D flattening
    private func validateDistortion(_ panel: FlattenedPanelDTO) -> [ValidationWarning] {
        var warnings: [ValidationWarning] = []
        
        // Calculate area distortion if we have 3D reference data
        let edges = panel.edges.filter { $0.type == .cutLine }
        var totalDistortion: Double = 0
        var edgeCount = 0
        
        for edge in edges {
            guard let original3DLength = edge.original3DLength,
                  edge.startIndex < panel.points2D.count && edge.endIndex < panel.points2D.count else {
                continue
            }
            
            let startPoint = panel.points2D[edge.startIndex]
            let endPoint = panel.points2D[edge.endIndex]
            let flattenedLength = distance(startPoint, endPoint)
            
            let distortion = abs(flattenedLength - original3DLength) / original3DLength
            totalDistortion += distortion
            edgeCount += 1
        }
        
        if edgeCount > 0 {
            let averageDistortion = totalDistortion / Double(edgeCount)
            
            if averageDistortion > 0.1 { // 10% average distortion
                warnings.append(ValidationWarning(
                    type: .distortionWarning,
                    message: "High flattening distortion detected (average: \(String(format: "%.1f", averageDistortion * 100))%)",
                    panelId: panel.id,
                    location: nil
                ))
            }
        }
        
        return warnings
    }
    
    /// Validate overlaps between panels
    private func validatePanelOverlaps(_ panels: [FlattenedPanelDTO]) async -> [ValidationIssue] {
        var issues: [ValidationIssue] = []
        
        for i in 0..<panels.count {
            for j in (i + 1)..<panels.count {
                let panel1 = panels[i]
                let panel2 = panels[j]
                
                // Quick bounding box intersection test
                if panel1.boundingBox.intersects(panel2.boundingBox) {
                    // Detailed polygon intersection test
                    if await polygonsIntersect(panel1.points2D, panel2.points2D) {
                        let overlap = panel1.boundingBox.intersection(panel2.boundingBox)
                        issues.append(ValidationIssue(
                            severity: .critical,
                            type: .intersectionError,
                            message: "Panels overlap - this will cause cutting conflicts",
                            panelId: panel1.id,
                            location: CGPoint(x: overlap.midX, y: overlap.midY)
                        ))
                    }
                }
            }
        }
        
        return issues
    }
    
    /// Validate fabric compatibility
    private func validateFabricCompatibility(_ panels: [FlattenedPanelDTO]) -> FabricCompatibilityResult {
        var compatibleWidths: [Double] = []
        var issues: [String] = []

        // Check which fabric widths can accommodate all panels
        for width in config.fabricWidths {
            let oversizedPanels = panels.filter { panel in
                panel.boundingBox.width > width
            }

            if oversizedPanels.isEmpty {
                compatibleWidths.append(width)
            } else {
                issues.append("Fabric width \(Int(width))mm cannot accommodate \(oversizedPanels.count) panels")
            }
        }

        return FabricCompatibilityResult(
            compatibleWidths: compatibleWidths,
            recommendedWidth: compatibleWidths.min(),
            issues: issues,
            requiresCustomWidth: compatibleWidths.isEmpty
        )
    }
    
    /// Validate grain line consistency
    private func validateGrainLineConsistency(_ panels: [FlattenedPanelDTO]) -> [ValidationIssue] {
        var issues: [ValidationIssue] = []
        
        // For now, we'll check that all panels have consistent orientation
        // In a full implementation, this would check actual grain line data
        
        if panels.count > 1 {
            let firstPanelBbox = panels.first?.boundingBox
            let orientations = panels.map { panel in
                panel.boundingBox.width > panel.boundingBox.height
            }
            
            let consistentOrientation = orientations.allSatisfy { $0 == orientations.first }
            
            if !consistentOrientation && firstPanelBbox != nil {
                issues.append(ValidationIssue(
                    severity: .warning,
                    type: .grainLineError,
                    message: "Panels have inconsistent orientations - may affect fabric grain alignment",
                    panelId: panels.first?.id,
                    location: CGPoint(x: firstPanelBbox!.midX, y: firstPanelBbox!.midY)
                ))
            }
        }
        
        return issues
    }
    
    /// Estimate required fabric length using simple bin packing
    private func estimateRequiredFabricLength(_ panels: [FlattenedPanelDTO], fabricWidth: Double) -> Double {
        // Sort panels by height (tallest first) for better packing
        let sortedPanels = panels.sorted { $0.boundingBox.height > $1.boundingBox.height }
        
        var currentY: Double = 0
        var currentRowHeight: Double = 0
        var currentRowWidth: Double = 0
        
        for panel in sortedPanels {
            let bbox = panel.boundingBox
            
            // If panel doesn't fit in current row, start new row
            if currentRowWidth + bbox.width > fabricWidth {
                currentY += currentRowHeight
                currentRowHeight = bbox.height
                currentRowWidth = bbox.width
            } else {
                // Panel fits in current row
                currentRowWidth += bbox.width
                currentRowHeight = max(currentRowHeight, bbox.height)
            }
        }
        
        // Add final row height
        currentY += currentRowHeight
        
        // Add 10% padding for handling
        return currentY * 1.1
    }
    
    /// Generate fabric utilization recommendations
    private func generateUtilizationRecommendations(efficiency: Double, oversizedPanels: [FlattenedPanelDTO]) -> [String] {
        var recommendations: [String] = []
        
        if efficiency < 0.5 {
            recommendations.append("Very low fabric efficiency (\(String(format: "%.1f", efficiency * 100))%) - consider rearranging panels")
        } else if efficiency < 0.65 {
            recommendations.append("Low fabric efficiency (\(String(format: "%.1f", efficiency * 100))%) - optimization possible")
        }
        
        if !oversizedPanels.isEmpty {
            recommendations.append("Consider using wider fabric or splitting \(oversizedPanels.count) oversized panels")
        }
        
        if efficiency > 0.85 {
            recommendations.append("Excellent fabric efficiency (\(String(format: "%.1f", efficiency * 100))%)")
        }
        
        return recommendations
    }
    
    // MARK: - Geometric Helper Methods
    
    /// Check if all points are collinear
    private func areAllPointsCollinear(_ points: [CGPoint]) -> Bool {
        guard points.count >= 3 else { return true }
        
        let tolerance: Double = 1e-6
        
        for i in 2..<points.count {
            let area = triangleArea(points[0], points[1], points[i])
            if abs(area) > tolerance {
                return false
            }
        }
        
        return true
    }
    
    /// Calculate triangle area using cross product
    private func triangleArea(_ p1: CGPoint, _ p2: CGPoint, _ p3: CGPoint) -> Double {
        return 0.5 * abs((p2.x - p1.x) * (p3.y - p1.y) - (p3.x - p1.x) * (p2.y - p1.y))
    }
    
    /// Calculate distance between two points
    private func distance(_ p1: CGPoint, _ p2: CGPoint) -> Double {
        let dx = p1.x - p2.x
        let dy = p1.y - p2.y
        return sqrt(dx * dx + dy * dy)
    }
    
    /// Find intersection point of two line segments
    private func lineIntersection(_ p1: CGPoint, _ p2: CGPoint, _ p3: CGPoint, _ p4: CGPoint) -> CGPoint? {
        let d1 = (p2.x - p1.x) * (p4.y - p3.y) - (p2.y - p1.y) * (p4.x - p3.x)
        let d2 = (p1.x - p3.x) * (p4.y - p3.y) - (p1.y - p3.y) * (p4.x - p3.x)
        let d3 = (p1.x - p3.x) * (p2.y - p1.y) - (p1.y - p3.y) * (p2.x - p1.x)
        
        guard abs(d1) > 1e-8 else { return nil } // Lines are parallel
        
        let t1 = d2 / d1
        let t2 = d3 / d1
        
        // Check if intersection is within both line segments
        if t1 >= 0 && t1 <= 1 && t2 >= 0 && t2 <= 1 {
            return CGPoint(
                x: p1.x + t1 * (p2.x - p1.x),
                y: p1.y + t1 * (p2.y - p1.y)
            )
        }
        
        return nil
    }
    
    /// Check if two polygons intersect
    private func polygonsIntersect(_ poly1: [CGPoint], _ poly2: [CGPoint]) async -> Bool {
        // Simplified polygon intersection using separating axis theorem
        // For production use, consider more robust algorithms like Sutherland-Hodgman
        
        // Check if any vertices of poly1 are inside poly2
        for point in poly1 {
            if isPointInPolygon(point, polygon: poly2) {
                return true
            }
        }
        
        // Check if any vertices of poly2 are inside poly1
        for point in poly2 {
            if isPointInPolygon(point, polygon: poly1) {
                return true
            }
        }
        
        // Check edge intersections
        for i in 0..<poly1.count {
            let p1 = poly1[i]
            let p2 = poly1[(i + 1) % poly1.count]
            
            for j in 0..<poly2.count {
                let p3 = poly2[j]
                let p4 = poly2[(j + 1) % poly2.count]
                
                if lineIntersection(p1, p2, p3, p4) != nil {
                    return true
                }
            }
        }
        
        return false
    }
    
    /// Check if a point is inside a polygon using ray casting
    private func isPointInPolygon(_ point: CGPoint, polygon: [CGPoint]) -> Bool {
        guard polygon.count >= 3 else { return false }
        
        var inside = false
        var j = polygon.count - 1
        
        for i in 0..<polygon.count {
            let xi = polygon[i].x
            let yi = polygon[i].y
            let xj = polygon[j].x
            let yj = polygon[j].y
            
            if ((yi > point.y) != (yj > point.y)) &&
               (point.x < (xj - xi) * (point.y - yi) / (yj - yi) + xi) {
                inside.toggle()
            }
            j = i
        }
        
        return inside
    }
}

// MARK: - Extensions

@available(iOS 18.0, macOS 15.0, *)
extension PatternValidationResult {
    /// Summary of the validation
    public var summary: String {
        if isValid {
            if warnings.isEmpty {
                return "Panel validation passed with no issues"
            } else {
                return "Panel validation passed with \(warnings.count) warnings"
            }
        } else {
            return "Panel validation failed with \(issues.count) issues"
        }
    }
}