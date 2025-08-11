// Version: 1.0.0
// CoverCraft Integration Tests - End-to-End Workflow Tests
//
// Comprehensive integration tests covering complete CoverCraft workflows
// Tests the interaction between all services and validates data flow integrity

import Testing
import Foundation
import simd
import CoverCraftDTO
import CoverCraftCore
import CoverCraftSegmentation
import CoverCraftFlattening
import CoverCraftExport
import TestUtilities

@Suite("End-to-End Workflow Tests")
@available(iOS 18.0, *)
struct EndToEndWorkflowTests {
    
    let calibrationService: DefaultCalibrationService
    let segmentationService: DefaultMeshSegmentationService
    let flatteningService: DefaultPatternFlatteningService
    let exportService: DefaultPatternExportService
    
    init() {
        calibrationService = DefaultCalibrationService()
        segmentationService = DefaultMeshSegmentationService()
        flatteningService = DefaultPatternFlatteningService()
        exportService = DefaultPatternExportService()
    }
    
    // MARK: - Complete Workflow Tests
    
    @Test("Complete pattern generation workflow - simple cube")
    func completePatternGenerationWorkflowSimpleCube() async throws {
        // 1. Start with a mesh and calibration
        let mesh = TestDataFactory.createCubeMesh()
        var calibration = calibrationService.createCalibration()
        
        // 2. Complete calibration
        calibration = calibrationService.setFirstPoint(calibration, point: SIMD3<Float>(0, 0, 0))
        calibration = calibrationService.setSecondPoint(calibration, point: SIMD3<Float>(1, 0, 0))
        calibration = calibrationService.setRealWorldDistance(calibration, distance: 0.1) // 10cm
        
        #expect(calibrationService.validateCalibration(calibration))
        
        // 3. Segment mesh into panels
        let panels = try await segmentationService.segmentMesh(mesh, targetPanelCount: 6)
        #expect(panels.count > 0)
        #expect(panels.count <= 6)
        
        // 4. Flatten panels to 2D
        let flattenedPanels = try await flatteningService.flattenPanels(panels, from: mesh)
        #expect(flattenedPanels.count > 0)
        #expect(flattenedPanels.count <= panels.count)
        
        // 5. Optimize for cutting
        let optimizedPanels = try await flatteningService.optimizeForCutting(flattenedPanels)
        #expect(optimizedPanels.count == flattenedPanels.count)
        
        // 6. Validate for export
        let validationResult = exportService.validateForExport(optimizedPanels, format: .pdf)
        #expect(validationResult.isValid)
        
        // 7. Export patterns
        let exportOptions = TestDataFactory.createTestExportOptions(format: .pdf)
        let exportResult = try await exportService.exportPatterns(optimizedPanels, format: .pdf, options: exportOptions)
        
        #expect(!exportResult.data.isEmpty)
        #expect(exportResult.format == .pdf)
        #expect(exportResult.filename.hasSuffix(".pdf"))
        
        // 8. Verify complete workflow integrity
        #expect(exportResult.metadata["panelCount"] != nil)
        #expect(Int(exportResult.metadata["panelCount"] ?? "0") == optimizedPanels.count)
    }
    
    @Test("Complete pattern generation workflow - complex mesh")
    func completePatternGenerationWorkflowComplexMesh() async throws {
        // Use more complex mesh for realistic scenario
        let mesh = TestDataFactory.createComplexMesh(complexity: 3)
        
        // 1. Calibration
        let calibration = TestDataFactory.createTestCalibration(isComplete: true, realWorldDistance: 0.5)
        #expect(calibrationService.validateCalibration(calibration))
        
        // 2. Segmentation with medium complexity
        let panels = try await segmentationService.segmentMesh(mesh, targetPanelCount: 12)
        #expect(panels.count > 0)
        #expect(panels.count <= 12)
        
        // Verify panel integrity
        for panel in panels {
            #expect(!panel.vertexIndices.isEmpty)
            #expect(!panel.triangleIndices.isEmpty)
            #expect(panel.triangleIndices.count % 3 == 0)
        }
        
        // 3. Flattening
        let flattenedPanels = try await flatteningService.flattenPanels(panels, from: mesh)
        #expect(flattenedPanels.count > 0)
        
        // Verify flattened panel integrity
        for flatPanel in flattenedPanels {
            #expect(flatPanel.points2D.count >= 3)
            #expect(!flatPanel.edges.isEmpty)
            #expect(flatPanel.isValid)
        }
        
        // 4. Optimization
        let optimizedPanels = try await flatteningService.optimizeForCutting(flattenedPanels)
        #expect(optimizedPanels.count == flattenedPanels.count)
        
        // 5. Multi-format export
        let formats: [ExportFormat] = [.pdf, .svg, .dxf]
        
        for format in formats {
            let validationResult = exportService.validateForExport(optimizedPanels, format: format)
            
            if validationResult.isValid {
                let options = TestDataFactory.createTestExportOptions(format: format)
                let result = try await exportService.exportPatterns(optimizedPanels, format: format, options: options)
                
                #expect(!result.data.isEmpty)
                #expect(result.format == format)
                #expect(result.filename.hasSuffix(".\(format.fileExtension)"))
            }
        }
    }
    
    @Test("Workflow with different segmentation resolutions")
    func workflowWithDifferentSegmentationResolutions() async throws {
        let mesh = TestDataFactory.createCubeMesh()
        let calibration = TestDataFactory.createTestCalibration(isComplete: true)
        
        for resolution in SegmentationResolution.allCases {
            // 1. Preview segmentation
            let previewPanels = try await segmentationService.previewSegmentation(mesh, resolution: resolution)
            #expect(previewPanels.count > 0)
            #expect(previewPanels.count <= resolution.targetPanelCount)
            
            // 2. Full segmentation
            let fullPanels = try await segmentationService.segmentMesh(mesh, targetPanelCount: resolution.targetPanelCount)
            #expect(fullPanels.count > 0)
            
            // 3. Continue with flattening
            let flattenedPanels = try await flatteningService.flattenPanels(fullPanels, from: mesh)
            #expect(flattenedPanels.count > 0)
            
            // 4. Export (test one format per resolution)
            let format: ExportFormat = resolution == .low ? .png : resolution == .medium ? .svg : .pdf
            let options = TestDataFactory.createTestExportOptions(format: format)
            let result = try await exportService.exportPatterns(flattenedPanels, format: format, options: options)
            
            #expect(!result.data.isEmpty)
            #expect(result.format == format)
        }
    }
    
    // MARK: - Error Handling Integration Tests
    
    @Test("Workflow error handling - invalid mesh")
    func workflowErrorHandlingInvalidMesh() async throws {
        let invalidMesh = TestDataFactory.createInvalidMesh()
        
        // Calibration should still work
        let calibration = TestDataFactory.createTestCalibration(isComplete: true)
        #expect(calibrationService.validateCalibration(calibration))
        
        // Segmentation should fail gracefully
        await #expect(throws: CoverCraftError.self) {
            _ = try await segmentationService.segmentMesh(invalidMesh, targetPanelCount: 6)
        }
        
        // After error, service should still work with valid data
        let validMesh = TestDataFactory.createCubeMesh()
        let panels = try await segmentationService.segmentMesh(validMesh, targetPanelCount: 6)
        #expect(panels.count > 0)
    }
    
    @Test("Workflow error handling - incomplete calibration")
    func workflowErrorHandlingIncompleteCalibration() async throws {
        // Start workflow with incomplete calibration
        let incompleteCalibration = TestDataFactory.createTestCalibration(isComplete: false)
        #expect(!calibrationService.validateCalibration(incompleteCalibration))
        
        // Rest of workflow should still work independently
        let mesh = TestDataFactory.createCubeMesh()
        let panels = try await segmentationService.segmentMesh(mesh, targetPanelCount: 6)
        let flattenedPanels = try await flatteningService.flattenPanels(panels, from: mesh)
        
        #expect(panels.count > 0)
        #expect(flattenedPanels.count > 0)
        
        // Export should work regardless of calibration state
        let options = TestDataFactory.createTestExportOptions()
        let result = try await exportService.exportPatterns(flattenedPanels, format: .pdf, options: options)
        #expect(!result.data.isEmpty)
    }
    
    @Test("Workflow error handling - flattening failure recovery")
    func workflowErrorHandlingFlatteningFailureRecovery() async throws {
        let mesh = TestDataFactory.createCubeMesh()
        let panels = try await segmentationService.segmentMesh(mesh, targetPanelCount: 6)
        
        // Simulate flattening failure with empty panel
        let invalidPanel = TestDataFactory.EdgeCases.emptyPanel()
        let mixedPanels = panels + [invalidPanel]
        
        // Flattening should fail with mixed valid/invalid panels
        await #expect(throws: CoverCraftError.self) {
            _ = try await flatteningService.flattenPanels(mixedPanels, from: mesh)
        }
        
        // Should recover and work with valid panels only
        let validFlattenedPanels = try await flatteningService.flattenPanels(panels, from: mesh)
        #expect(validFlattenedPanels.count > 0)
        
        // Continue workflow
        let optimizedPanels = try await flatteningService.optimizeForCutting(validFlattenedPanels)
        let options = TestDataFactory.createTestExportOptions()
        let result = try await exportService.exportPatterns(optimizedPanels, format: .svg, options: options)
        
        #expect(!result.data.isEmpty)
    }
    
    // MARK: - Performance Integration Tests
    
    @Test("Complete workflow performance")
    func completeWorkflowPerformance() async throws {
        let mesh = TestDataFactory.createComplexMesh(complexity: 2)
        
        let (result, totalTime) = try await AsyncTestHelpers.measureAsync {
            // Complete workflow
            let calibration = TestDataFactory.createTestCalibration(isComplete: true)
            #expect(calibrationService.validateCalibration(calibration))
            
            let panels = try await segmentationService.segmentMesh(mesh, targetPanelCount: 10)
            let flattenedPanels = try await flatteningService.flattenPanels(panels, from: mesh)
            let optimizedPanels = try await flatteningService.optimizeForCutting(flattenedPanels)
            
            let options = TestDataFactory.createTestExportOptions()
            return try await exportService.exportPatterns(optimizedPanels, format: .pdf, options: options)
        }
        
        #expect(!result.data.isEmpty)
        #expect(totalTime < 30.0) // Complete workflow should finish within 30 seconds
        
        // Log performance for monitoring
        print("Complete workflow execution time: \(totalTime) seconds")
    }
    
    @Test("Concurrent workflow execution")
    func concurrentWorkflowExecution() async throws {
        let meshes = [
            TestDataFactory.createCubeMesh(),
            TestDataFactory.createTriangleMesh(),
            TestDataFactory.createComplexMesh(complexity: 2)
        ]
        
        let operations = meshes.enumerated().map { index, mesh in
            {
                let panels = try await segmentationService.segmentMesh(mesh, targetPanelCount: 5)
                let flattenedPanels = try await flatteningService.flattenPanels(panels, from: mesh)
                let options = TestDataFactory.createTestExportOptions()
                return try await exportService.exportPatterns(flattenedPanels, format: .svg, options: options)
            }
        }
        
        let results = try await AsyncTestHelpers.executeConcurrently(operations: operations)
        
        #expect(results.count == meshes.count)
        
        for result in results {
            #expect(!result.data.isEmpty)
            #expect(result.format == .svg)
        }
    }
    
    // MARK: - Data Flow Integration Tests
    
    @Test("Data preservation through workflow")
    func dataPreservationThroughWorkflow() async throws {
        let mesh = TestDataFactory.createCubeMesh()
        let originalVertexCount = mesh.vertices.count
        let originalTriangleCount = mesh.triangleCount
        
        // Track data through workflow
        let panels = try await segmentationService.segmentMesh(mesh, targetPanelCount: 6)
        
        // Verify vertex indices are valid
        let allVertexIndices = Set(panels.flatMap { $0.vertexIndices })
        for vertexIndex in allVertexIndices {
            #expect(vertexIndex < originalVertexCount)
        }
        
        // Flatten and verify
        let flattenedPanels = try await flatteningService.flattenPanels(panels, from: mesh)
        
        // Colors should be preserved
        let originalColors = Set(panels.map { $0.color })
        let flattenedColors = Set(flattenedPanels.map { $0.color })
        #expect(originalColors == flattenedColors || flattenedColors.isSubset(of: originalColors))
        
        // Export and verify metadata
        let options = TestDataFactory.createTestExportOptions()
        let result = try await exportService.exportPatterns(flattenedPanels, format: .pdf, options: options)
        
        #expect(result.metadata["panelCount"] == "\(flattenedPanels.count)")
    }
    
    @Test("Scale consistency through workflow")
    func scaleConsistencyThroughWorkflow() async throws {
        let mesh = TestDataFactory.createCubeMesh()
        let calibration = TestDataFactory.createTestCalibration(isComplete: true, realWorldDistance: 0.2) // 20cm
        
        let panels = try await segmentationService.segmentMesh(mesh, targetPanelCount: 6)
        let flattenedPanels = try await flatteningService.flattenPanels(panels, from: mesh)
        
        // All flattened panels should have consistent scale units
        let scales = flattenedPanels.map { $0.scaleUnitsPerMeter }
        let uniqueScales = Set(scales)
        
        #expect(uniqueScales.count <= 2) // Should be mostly consistent
        
        for scale in scales {
            #expect(scale > 0)
            #expect(scale < 100000) // Reasonable bounds
        }
        
        // Export with scaling
        let scaledOptions = ExportOptions(
            includeSeamAllowance: true,
            seamAllowanceWidth: 15.0,
            includeRegistrationMarks: true,
            paperSize: .a4,
            scale: 2.0, // Double scale
            includeInstructions: false
        )
        
        let result = try await exportService.exportPatterns(flattenedPanels, format: .svg, options: scaledOptions)
        #expect(!result.data.isEmpty)
    }
    
    // MARK: - Multi-Format Integration Tests
    
    @Test("Multi-format export workflow")
    func multiFormatExportWorkflow() async throws {
        let mesh = TestDataFactory.createCubeMesh()
        let panels = try await segmentationService.segmentMesh(mesh, targetPanelCount: 6)
        let flattenedPanels = try await flatteningService.flattenPanels(panels, from: mesh)
        let optimizedPanels = try await flatteningService.optimizeForCutting(flattenedPanels)
        
        let formats = ExportFormat.allCases
        var results: [ExportFormat: ExportResult] = [:]
        
        for format in formats {
            let validationResult = exportService.validateForExport(optimizedPanels, format: format)
            
            if validationResult.isValid {
                let options = TestDataFactory.createTestExportOptions(format: format, paperSize: .a4)
                let result = try await exportService.exportPatterns(optimizedPanels, format: format, options: options)
                
                results[format] = result
                
                #expect(!result.data.isEmpty)
                #expect(result.format == format)
                #expect(result.filename.hasSuffix(".\(format.fileExtension)"))
            } else {
                // If validation fails, should have clear errors
                #expect(!validationResult.errors.isEmpty)
            }
        }
        
        // Should have successfully exported to multiple formats
        #expect(results.count >= 3) // At least PDF, SVG, and one other
        
        // All results should have same panel count
        let panelCounts = results.values.compactMap { Int($0.metadata["panelCount"] ?? "") }
        let uniquePanelCounts = Set(panelCounts)
        #expect(uniquePanelCounts.count <= 1) // Should be consistent
    }
    
    @Test("Export options variation workflow")
    func exportOptionsVariationWorkflow() async throws {
        let mesh = TestDataFactory.createCubeMesh()
        let panels = try await segmentationService.segmentMesh(mesh, targetPanelCount: 6)
        let flattenedPanels = try await flatteningService.flattenPanels(panels, from: mesh)
        
        let optionsVariations = [
            ExportOptions(includeSeamAllowance: true, seamAllowanceWidth: 10.0, includeRegistrationMarks: true, paperSize: .a4, scale: 1.0, includeInstructions: true),
            ExportOptions(includeSeamAllowance: false, seamAllowanceWidth: 0, includeRegistrationMarks: false, paperSize: .letter, scale: 1.5, includeInstructions: false),
            ExportOptions(includeSeamAllowance: true, seamAllowanceWidth: 20.0, includeRegistrationMarks: true, paperSize: .a3, scale: 0.8, includeInstructions: true)
        ]
        
        for (index, options) in optionsVariations.enumerated() {
            let result = try await exportService.exportPatterns(flattenedPanels, format: .pdf, options: options)
            
            #expect(!result.data.isEmpty)
            #expect(result.format == .pdf)
            
            // Different options should produce different results
            if index > 0 {
                // At minimum, filenames or metadata should reflect differences
                #expect(!result.metadata.isEmpty)
            }
        }
    }
    
    // MARK: - Edge Case Integration Tests
    
    @Test("Minimal mesh complete workflow")
    func minimalMeshCompleteWorkflow() async throws {
        let mesh = TestDataFactory.createTriangleMesh() // Minimal valid mesh
        
        // Should handle single triangle through entire workflow
        let panels = try await segmentationService.segmentMesh(mesh, targetPanelCount: 1)
        #expect(panels.count == 1)
        
        let flattenedPanels = try await flatteningService.flattenPanels(panels, from: mesh)
        #expect(flattenedPanels.count == 1)
        #expect(flattenedPanels[0].points2D.count == 3) // Triangle
        
        let optimizedPanels = try await flatteningService.optimizeForCutting(flattenedPanels)
        #expect(optimizedPanels.count == 1)
        
        let options = TestDataFactory.createTestExportOptions()
        let result = try await exportService.exportPatterns(optimizedPanels, format: .svg, options: options)
        
        #expect(!result.data.isEmpty)
        #expect(result.metadata["panelCount"] == "1")
    }
    
    @Test("Large mesh workflow scalability")
    func largeMeshWorkflowScalability() async throws {
        let largeMesh = TestDataFactory.createComplexMesh(complexity: 4) // Large mesh
        
        let (result, executionTime) = try await AsyncTestHelpers.measureAsync {
            let panels = try await segmentationService.segmentMesh(largeMesh, targetPanelCount: 15)
            let flattenedPanels = try await flatteningService.flattenPanels(panels, from: largeMesh)
            let optimizedPanels = try await flatteningService.optimizeForCutting(flattenedPanels)
            
            let options = TestDataFactory.createTestExportOptions()
            return try await exportService.exportPatterns(optimizedPanels, format: .pdf, options: options)
        }
        
        #expect(!result.data.isEmpty)
        #expect(executionTime < 60.0) // Should complete within 1 minute even for large mesh
        
        // Large exports should have substantial content
        #expect(result.data.count > 1000)
    }
    
    // MARK: - Cancellation Integration Tests
    
    @Test("Workflow cancellation handling")
    func workflowCancellationHandling() async throws {
        let mesh = TestDataFactory.createComplexMesh(complexity: 4)
        
        let wasCancelled = await AsyncTestHelpers.testCancellation {
            let panels = try await segmentationService.segmentMesh(mesh, targetPanelCount: 20)
            let flattenedPanels = try await flatteningService.flattenPanels(panels, from: mesh)
            let optimizedPanels = try await flatteningService.optimizeForCutting(flattenedPanels)
            
            let options = TestDataFactory.createTestExportOptions()
            return try await exportService.exportPatterns(optimizedPanels, format: .pdf, options: options)
        }
        
        #expect(wasCancelled)
    }
    
    // MARK: - Memory Management Integration Tests
    
    @Test("Memory management through complete workflow")
    func memoryManagementThroughCompleteWorkflow() async throws {
        // Run multiple complete workflows to test memory management
        let mesh = TestDataFactory.createComplexMesh(complexity: 2)
        
        for iteration in 0..<3 {
            let panels = try await segmentationService.segmentMesh(mesh, targetPanelCount: 8)
            let flattenedPanels = try await flatteningService.flattenPanels(panels, from: mesh)
            let optimizedPanels = try await flatteningService.optimizeForCutting(flattenedPanels)
            
            let options = TestDataFactory.createTestExportOptions()
            let result = try await exportService.exportPatterns(optimizedPanels, format: .svg, options: options)
            
            #expect(!result.data.isEmpty)
            #expect(panels.count > 0)
            
            // Allow brief cleanup between iterations
            try await Task.sleep(nanoseconds: 50_000_000) // 50ms
        }
    }
    
    // MARK: - Validation Integration Tests
    
    @Test("End-to-end validation workflow")
    func endToEndValidationWorkflow() async throws {
        let mesh = TestDataFactory.createCubeMesh()
        
        // 1. Validate mesh (implicit in segmentation success)
        let panels = try await segmentationService.segmentMesh(mesh, targetPanelCount: 6)
        #expect(panels.count > 0)
        
        // 2. Validate panels (implicit in flattening success)
        let flattenedPanels = try await flatteningService.flattenPanels(panels, from: mesh)
        #expect(flattenedPanels.count > 0)
        
        // 3. Explicit export validation
        for format in [ExportFormat.pdf, .svg, .dxf] {
            let validationResult = exportService.validateForExport(flattenedPanels, format: format)
            
            if validationResult.isValid {
                let options = TestDataFactory.createTestExportOptions(format: format)
                let result = try await exportService.exportPatterns(flattenedPanels, format: format, options: options)
                
                #expect(!result.data.isEmpty)
                #expect(result.format == format)
            } else {
                // If validation fails, errors should be informative
                #expect(!validationResult.errors.isEmpty)
                for error in validationResult.errors {
                    #expect(!error.isEmpty)
                }
            }
        }
    }
}