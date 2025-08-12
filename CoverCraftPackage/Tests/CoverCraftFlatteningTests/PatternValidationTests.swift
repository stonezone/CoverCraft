// Version: 1.0.0
// CoverCraft Flattening Module - Comprehensive Pattern Validation Tests

import Testing
import Foundation
import CoreGraphics
import CoverCraftFlattening
import CoverCraftDTO
import CoverCraftCore

/// Comprehensive tests for the PatternValidator system
///
/// Tests cover all validation scenarios including:
/// - Basic geometric validation
/// - Seam allowance validation
/// - Panel overlap detection
/// - Fabric compatibility checks
/// - Real-world pattern constraints
@Suite("Pattern Validation Tests")
struct PatternValidationTests {
    
    // MARK: - Test Properties
    
    private let validator = PatternValidator()
    
    // MARK: - Basic Geometry Validation Tests
    
    @Test("Valid triangle panel passes basic geometry validation")
    func validTrianglePanelPassesValidation() async throws {
        let panel = createValidTrianglePanel()
        
        let result = await validator.validatePanel(panel)
        
        #expect(result.isValid)
        #expect(result.issues.isEmpty)
        #expect(result.panelId == panel.id)
    }
    
    @Test("Panel with insufficient points fails validation")
    func insufficientPointsFailsValidation() async throws {
        let panel = createPanelWithPoints([
            CGPoint(x: 0, y: 0),
            CGPoint(x: 10, y: 0)
        ])
        
        let result = await validator.validatePanel(panel)
        
        #expect(!result.isValid)
        #expect(result.issues.contains { $0.type == .geometryError })
        #expect(result.issues.contains { $0.message.contains("at least 3 points") })
    }
    
    @Test("Panel with duplicate points generates error")
    func duplicatePointsGenerateError() async throws {
        let panel = createPanelWithPoints([
            CGPoint(x: 0, y: 0),
            CGPoint(x: 10, y: 0),
            CGPoint(x: 10, y: 0), // Duplicate
            CGPoint(x: 5, y: 10)
        ])
        
        let result = await validator.validatePanel(panel)
        
        #expect(!result.isValid)
        #expect(result.issues.contains { $0.message.contains("duplicate points") })
    }
    
    @Test("Panel with collinear points fails validation")
    func collinearPointsFailValidation() async throws {
        let panel = createPanelWithPoints([
            CGPoint(x: 0, y: 0),
            CGPoint(x: 5, y: 0),
            CGPoint(x: 10, y: 0),
            CGPoint(x: 15, y: 0)
        ])
        
        let result = await validator.validatePanel(panel)
        
        #expect(!result.isValid)
        #expect(result.issues.contains { $0.message.contains("collinear") })
    }
    
    @Test("Panel with zero area fails validation")
    func zeroAreaPanelFailsValidation() async throws {
        let panel = createPanelWithPoints([
            CGPoint(x: 0, y: 0),
            CGPoint(x: 0, y: 0),
            CGPoint(x: 0, y: 0)
        ])
        
        let result = await validator.validatePanel(panel)
        
        #expect(!result.isValid)
        #expect(result.issues.contains { $0.type == .geometryError })
    }
    
    // MARK: - Seam Allowance Validation Tests
    
    @Test("Standard seam allowance passes validation")
    func standardSeamAllowancePassesValidation() async throws {
        let panel = createPanelWithSeamAllowance(PatternValidator.standardSeamAllowance)
        
        let result = await validator.validatePanel(panel)
        
        let seamIssues = result.issues.filter { $0.type == .seamAllowanceError }
        #expect(seamIssues.isEmpty)
    }
    
    @Test("Narrow seam allowance generates error")
    func narrowSeamAllowanceGeneratesError() async throws {
        let panel = createPanelWithSeamAllowance(2.0) // Below 3mm minimum
        
        let result = await validator.validatePanel(panel)
        
        #expect(!result.isValid)
        #expect(result.issues.contains { $0.type == .seamAllowanceError })
        #expect(result.issues.contains { $0.message.contains("too narrow") })
    }
    
    @Test("Wide seam allowance generates warning")
    func wideSeamAllowanceGeneratesWarning() async throws {
        let panel = createPanelWithSeamAllowance(20.0) // Above 15mm recommended maximum
        
        let result = await validator.validatePanel(panel)
        
        #expect(result.isValid) // Should be valid but with warnings
        #expect(result.warnings.contains { $0.type == .seamAllowanceWarning })
        #expect(result.warnings.contains { $0.message.contains("unusually wide") })
    }
    
    @Test("Inconsistent seam allowance widths generate warning")
    func inconsistentSeamAllowancesGenerateWarning() async throws {
        let panel = createPanelWithVariableSeamAllowances([5.0, 5.0, 12.0]) // Significant variation
        
        let result = await validator.validatePanel(panel)
        
        #expect(result.warnings.contains { $0.type == .seamAllowanceWarning })
        #expect(result.warnings.contains { $0.message.contains("Inconsistent") })
    }
    
    // MARK: - Panel Size Validation Tests
    
    @Test("Panel with adequate area passes validation")
    func adequateAreaPassesValidation() async throws {
        let panel = createLargePanelWithArea(500.0) // 5cm²
        
        let result = await validator.validatePanel(panel)
        
        let sizeIssues = result.issues.filter { $0.type == .sizeError }
        #expect(sizeIssues.isEmpty)
    }
    
    @Test("Panel with insufficient area fails validation")
    func insufficientAreaFailsValidation() async throws {
        let panel = createSmallPanelWithArea(50.0) // 0.5cm² - below 1cm² minimum
        
        let result = await validator.validatePanel(panel)
        
        #expect(!result.isValid)
        #expect(result.issues.contains { $0.type == .sizeError })
        #expect(result.issues.contains { $0.message.contains("area too small") })
    }
    
    @Test("Panel with extreme aspect ratio generates warning")
    func extremeAspectRatioGeneratesWarning() async throws {
        let panel = createPanelWithDimensions(width: 200, height: 5) // 40:1 aspect ratio
        
        let result = await validator.validatePanel(panel)
        
        #expect(result.issues.contains { $0.message.contains("extreme aspect ratio") })
    }
    
    // MARK: - Edge Validation Tests
    
    @Test("Edges with adequate length pass validation")
    func adequateEdgeLengthPassesValidation() async throws {
        let panel = createPanelWithEdgeLength(15.0) // Above 10mm minimum
        
        let result = await validator.validatePanel(panel)
        
        let edgeIssues = result.issues.filter { $0.message.contains("Edge too short") }
        #expect(edgeIssues.isEmpty)
    }
    
    @Test("Short edges fail validation")
    func shortEdgesFailValidation() async throws {
        let panel = createPanelWithEdgeLength(5.0) // Below 10mm minimum
        
        let result = await validator.validatePanel(panel)
        
        #expect(!result.isValid)
        #expect(result.issues.contains { $0.message.contains("Edge too short") })
    }
    
    @Test("Edge with significant 3D length distortion generates warning")
    func distortedEdgeGeneratesWarning() async throws {
        let panel = createPanelWithDistortedEdge(flattenedLength: 10.0, original3DLength: 20.0) // 2x distortion
        
        let result = await validator.validatePanel(panel)
        
        #expect(result.issues.contains { $0.type == .distortionError })
        #expect(result.issues.contains { $0.message.contains("length significantly changed") })
    }
    
    // MARK: - Self-Intersection Tests
    
    @Test("Simple convex panel has no self-intersections")
    func convexPanelNoIntersections() async throws {
        let panel = createValidTrianglePanel()
        
        let result = await validator.validatePanel(panel)
        
        let intersectionIssues = result.issues.filter { $0.type == .intersectionError }
        #expect(intersectionIssues.isEmpty)
    }
    
    @Test("Self-intersecting panel fails validation")
    func selfIntersectingPanelFailsValidation() async throws {
        let panel = createSelfIntersectingPanel()
        
        let result = await validator.validatePanel(panel)
        
        #expect(!result.isValid)
        #expect(result.issues.contains { $0.type == .intersectionError })
        #expect(result.issues.contains { $0.message.contains("edges intersect") })
    }
    
    // MARK: - Panel Set Validation Tests
    
    @Test("Non-overlapping panels pass layout validation")
    func nonOverlappingPanelsPassValidation() async throws {
        let panels = [
            createPanelAtPosition(x: 0, y: 0, width: 50, height: 50),
            createPanelAtPosition(x: 60, y: 0, width: 50, height: 50),
            createPanelAtPosition(x: 0, y: 60, width: 50, height: 50)
        ]
        
        let result = await validator.validatePanelSet(panels)
        
        #expect(result.isValid)
        #expect(result.layoutIssues.isEmpty)
    }
    
    @Test("Overlapping panels fail layout validation")
    func overlappingPanelsFailValidation() async throws {
        let panels = [
            createPanelAtPosition(x: 0, y: 0, width: 60, height: 60),
            createPanelAtPosition(x: 30, y: 30, width: 60, height: 60) // Overlapping
        ]
        
        let result = await validator.validatePanelSet(panels)
        
        #expect(!result.isValid)
        #expect(result.layoutIssues.contains { $0.type == .intersectionError })
        #expect(result.layoutIssues.contains { $0.message.contains("overlap") })
    }
    
    // MARK: - Fabric Compatibility Tests
    
    @Test("Panels fitting standard fabric width pass compatibility test")
    func standardWidthPanelsPassCompatibility() async throws {
        let panels = [
            createPanelWithWidth(400), // 40cm - fits in 45" fabric
            createPanelWithWidth(500), // 50cm
            createPanelWithWidth(600)  // 60cm
        ]
        
        let result = await validator.validatePanelSet(panels)
        
        #expect(result.fabricCompatibility?.compatibleWidths.contains(1143.0) == true) // 45"
        #expect(result.fabricCompatibility?.requiresCustomWidth == false)
    }
    
    @Test("Oversized panels require custom fabric width")
    func oversizedPanelsRequireCustomWidth() async throws {
        let panels = [
            createPanelWithWidth(1200), // 120cm - exceeds 45" fabric
            createPanelWithWidth(1600)  // 160cm - exceeds 60" fabric
        ]
        
        let result = await validator.validatePanelSet(panels)
        
        #expect(result.fabricCompatibility?.requiresCustomWidth == true)
        #expect(result.fabricCompatibility?.compatibleWidths.isEmpty == true)
    }
    
    // MARK: - Fabric Utilization Tests
    
    @Test("Efficient panel layout has good utilization")
    func efficientLayoutGoodUtilization() {
        let panels = [
            createPanelWithDimensions(width: 400, height: 300), // Well-sized panels
            createPanelWithDimensions(width: 450, height: 250),
            createPanelWithDimensions(width: 350, height: 400)
        ]
        
        let result = validator.validateFabricUtilization(panels, fabricWidth: 1143.0) // 45"
        
        #expect(result.isEfficient)
        #expect(result.efficiency > 0.65)
    }
    
    @Test("Inefficient panel layout has poor utilization")
    func inefficientLayoutPoorUtilization() {
        let panels = [
            createPanelWithDimensions(width: 100, height: 100), // Many small panels
            createPanelWithDimensions(width: 80, height: 80),
            createPanelWithDimensions(width: 90, height: 70),
            createPanelWithDimensions(width: 110, height: 60)
        ]
        
        let result = validator.validateFabricUtilization(panels, fabricWidth: 1143.0)
        
        #expect(!result.isEfficient)
        #expect(result.recommendations.contains { $0.contains("low fabric efficiency") })
    }
    
    @Test("Panels exceeding fabric width are identified")
    func oversizedPanelsIdentified() {
        let panels = [
            createPanelWithWidth(1000), // Fits
            createPanelWithWidth(1200)  // Exceeds 45" width
        ]
        
        let result = validator.validateFabricUtilization(panels, fabricWidth: 1143.0)
        
        #expect(result.oversizedPanels.count == 1)
        #expect(result.recommendations.contains { $0.contains("oversized panels") })
    }
    
    // MARK: - Real-world Pattern Tests
    
    @Test("Realistic chair cushion pattern validates correctly")
    func realisticChairCushionPattern() async throws {
        let panels = createRealisticChairCushionPanels()
        
        let result = await validator.validatePanelSet(panels)
        
        #expect(result.isValid)
        #expect(result.fabricCompatibility?.compatibleWidths.contains(1143.0) == true)
        
        let utilizationResult = validator.validateFabricUtilization(panels, fabricWidth: 1143.0)
        #expect(utilizationResult.efficiency > 0.5)
    }
    
    @Test("Realistic sofa pattern with complex shapes validates")
    func realisticSofaPatternValidates() async throws {
        let panels = createRealisticSofaPanels()
        
        let result = await validator.validatePanelSet(panels)
        
        // May have warnings due to complexity but should be valid
        let criticalIssues = result.layoutIssues.filter { $0.severity == .critical }
        #expect(criticalIssues.isEmpty)
        
        // Should recommend appropriate fabric width
        #expect(result.recommendedFabricWidth != nil)
    }
    
    // MARK: - Edge Cases and Stress Tests
    
    @Test("Single point panel fails validation gracefully")
    func singlePointPanelFailsGracefully() async throws {
        let panel = createPanelWithPoints([CGPoint(x: 0, y: 0)])
        
        let result = await validator.validatePanel(panel)
        
        #expect(!result.isValid)
        #expect(result.issues.contains { $0.severity == .critical })
    }
    
    @Test("Empty panel set validates without crashing")
    func emptyPanelSetValidates() async throws {
        let result = await validator.validatePanelSet([])
        
        #expect(result.isValid) // Empty set is technically valid
        #expect(result.totalArea == 0)
    }
    
    @Test("Very large panel counts perform reasonably")
    func largePanelCountsPerformReasonably() async throws {
        let panels = (0..<50).map { i in
            createPanelAtPosition(x: Double(i % 10) * 60, y: Double(i / 10) * 60, width: 50, height: 50)
        }
        
        let startTime = Date()
        let result = await validator.validatePanelSet(panels)
        let duration = Date().timeIntervalSince(startTime)
        
        #expect(duration < 5.0) // Should complete within 5 seconds
        #expect(result.panelResults.count == 50)
    }
    
    // MARK: - Helper Methods for Test Data Creation
    
    private func createValidTrianglePanel() -> FlattenedPanelDTO {
        return createPanelWithPoints([
            CGPoint(x: 0, y: 0),
            CGPoint(x: 50, y: 0),
            CGPoint(x: 25, y: 43.3) // Equilateral triangle
        ])
    }
    
    private func createPanelWithPoints(_ points: [CGPoint]) -> FlattenedPanelDTO {
        let edges = createEdgesForPoints(points)
        
        return FlattenedPanelDTO(
            points2D: points,
            edges: edges,
            color: .blue,
            scaleUnitsPerMeter: 1000.0
        )
    }
    
    private func createPanelWithSeamAllowance(_ allowanceWidth: Double) -> FlattenedPanelDTO {
        let points = [
            CGPoint(x: 0, y: 0),
            CGPoint(x: 100, y: 0),
            CGPoint(x: 100, y: 100),
            CGPoint(x: 0, y: 100)
        ]
        
        let seamEdges = [
            EdgeDTO(startIndex: 0, endIndex: 1, type: .seamAllowance, original3DLength: allowanceWidth),
            EdgeDTO(startIndex: 1, endIndex: 2, type: .seamAllowance, original3DLength: allowanceWidth),
            EdgeDTO(startIndex: 2, endIndex: 3, type: .seamAllowance, original3DLength: allowanceWidth),
            EdgeDTO(startIndex: 3, endIndex: 0, type: .seamAllowance, original3DLength: allowanceWidth)
        ]
        
        return FlattenedPanelDTO(
            points2D: points,
            edges: seamEdges,
            color: .green,
            scaleUnitsPerMeter: 1000.0
        )
    }
    
    private func createPanelWithVariableSeamAllowances(_ widths: [Double]) -> FlattenedPanelDTO {
        let points = [
            CGPoint(x: 0, y: 0),
            CGPoint(x: 100, y: 0),
            CGPoint(x: 50, y: 87)  // Triangle
        ]
        
        let seamEdges = widths.enumerated().map { index, width in
            let nextIndex = (index + 1) % points.count
            return EdgeDTO(startIndex: index, endIndex: nextIndex, type: .seamAllowance, original3DLength: width)
        }
        
        return FlattenedPanelDTO(
            points2D: points,
            edges: seamEdges,
            color: .orange,
            scaleUnitsPerMeter: 1000.0
        )
    }
    
    private func createLargePanelWithArea(_ targetArea: Double) -> FlattenedPanelDTO {
        let side = sqrt(targetArea) // Square panel
        return createPanelWithDimensions(width: side, height: side)
    }
    
    private func createSmallPanelWithArea(_ targetArea: Double) -> FlattenedPanelDTO {
        let side = sqrt(targetArea)
        return createPanelWithDimensions(width: side, height: side)
    }
    
    private func createPanelWithDimensions(width: Double, height: Double) -> FlattenedPanelDTO {
        let points = [
            CGPoint(x: 0, y: 0),
            CGPoint(x: width, y: 0),
            CGPoint(x: width, y: height),
            CGPoint(x: 0, y: height)
        ]
        
        return createPanelWithPoints(points)
    }
    
    private func createPanelWithEdgeLength(_ edgeLength: Double) -> FlattenedPanelDTO {
        let points = [
            CGPoint(x: 0, y: 0),
            CGPoint(x: edgeLength, y: 0),
            CGPoint(x: edgeLength / 2, y: edgeLength * 0.866) // Equilateral triangle
        ]
        
        return createPanelWithPoints(points)
    }
    
    private func createPanelWithDistortedEdge(flattenedLength: Double, original3DLength: Double) -> FlattenedPanelDTO {
        let points = [
            CGPoint(x: 0, y: 0),
            CGPoint(x: flattenedLength, y: 0),
            CGPoint(x: flattenedLength / 2, y: 10)
        ]
        
        let edges = [
            EdgeDTO(startIndex: 0, endIndex: 1, type: .cutLine, original3DLength: original3DLength),
            EdgeDTO(startIndex: 1, endIndex: 2, type: .cutLine),
            EdgeDTO(startIndex: 2, endIndex: 0, type: .cutLine)
        ]
        
        return FlattenedPanelDTO(
            points2D: points,
            edges: edges,
            color: .red,
            scaleUnitsPerMeter: 1000.0
        )
    }
    
    private func createSelfIntersectingPanel() -> FlattenedPanelDTO {
        // Create a bowtie shape (self-intersecting)
        let points = [
            CGPoint(x: 0, y: 0),
            CGPoint(x: 50, y: 50),
            CGPoint(x: 100, y: 0),
            CGPoint(x: 50, y: -50)
        ]
        
        let edges = [
            EdgeDTO(startIndex: 0, endIndex: 1, type: .cutLine),
            EdgeDTO(startIndex: 1, endIndex: 2, type: .cutLine),
            EdgeDTO(startIndex: 2, endIndex: 3, type: .cutLine),
            EdgeDTO(startIndex: 3, endIndex: 0, type: .cutLine)
        ]
        
        return FlattenedPanelDTO(
            points2D: points,
            edges: edges,
            color: .purple,
            scaleUnitsPerMeter: 1000.0
        )
    }
    
    private func createPanelAtPosition(x: Double, y: Double, width: Double, height: Double) -> FlattenedPanelDTO {
        let points = [
            CGPoint(x: x, y: y),
            CGPoint(x: x + width, y: y),
            CGPoint(x: x + width, y: y + height),
            CGPoint(x: x, y: y + height)
        ]
        
        return createPanelWithPoints(points)
    }
    
    private func createPanelWithWidth(_ width: Double) -> FlattenedPanelDTO {
        return createPanelWithDimensions(width: width, height: 200) // Fixed height
    }
    
    private func createRealisticChairCushionPanels() -> [FlattenedPanelDTO] {
        return [
            // Top panel (square cushion)
            createPanelWithDimensions(width: 400, height: 400),
            // Side panels (rectangular)
            createPanelWithDimensions(width: 400, height: 60),
            createPanelWithDimensions(width: 400, height: 60),
            createPanelWithDimensions(width: 400, height: 60),
            createPanelWithDimensions(width: 400, height: 60)
        ]
    }
    
    private func createRealisticSofaPanels() -> [FlattenedPanelDTO] {
        return [
            // Back panel
            createPanelWithDimensions(width: 1800, height: 800),
            // Seat panels
            createPanelWithDimensions(width: 600, height: 600),
            createPanelWithDimensions(width: 600, height: 600),
            createPanelWithDimensions(width: 600, height: 600),
            // Arm panels
            createPanelWithDimensions(width: 300, height: 600),
            createPanelWithDimensions(width: 300, height: 600),
            // Various smaller panels
            createPanelWithDimensions(width: 200, height: 150),
            createPanelWithDimensions(width: 180, height: 200)
        ]
    }
    
    private func createEdgesForPoints(_ points: [CGPoint]) -> [EdgeDTO] {
        guard points.count >= 3 else { return [] }
        
        return (0..<points.count).map { i in
            let nextIndex = (i + 1) % points.count
            return EdgeDTO(startIndex: i, endIndex: nextIndex, type: .cutLine)
        }
    }
}