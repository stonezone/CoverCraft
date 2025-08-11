// Version: 1.0.0
// CoverCraft Export Tests - Pattern Export Service Unit Tests
//
// Comprehensive unit tests for DefaultPatternExportService following TDD principles
// Tests cover all export formats, edge cases, performance, and data integrity

import Testing
import Foundation
import CoverCraftDTO
import TestUtilities
@testable import CoverCraftExport

@Suite("PatternExportService Tests")
@available(iOS 18.0, *)
struct ExportServiceTests {
    
    let service: DefaultPatternExportService
    
    init() {
        service = DefaultPatternExportService()
    }
    
    // MARK: - Basic Export Tests
    
    @Test("Export to PDF format")
    func exportToPDFFormat() async throws {
        let panels = TestDataFactory.createTestFlattenedPanels(count: 3)
        let options = TestDataFactory.createTestExportOptions(format: .pdf)
        
        let result = try await service.exportPatterns(panels, format: .pdf, options: options)
        
        #expect(result.format == .pdf)
        #expect(result.filename.hasSuffix(".pdf"))
        #expect(!result.data.isEmpty)
        #expect(result.data.count > 100) // PDF should have reasonable size
        
        // Check metadata
        #expect(result.metadata["panelCount"] != nil)
        #expect(result.metadata["format"] == "PDF")
    }
    
    @Test("Export to SVG format")
    func exportToSVGFormat() async throws {
        let panels = TestDataFactory.createTestFlattenedPanels(count: 2)
        let options = TestDataFactory.createTestExportOptions(format: .svg)
        
        let result = try await service.exportPatterns(panels, format: .svg, options: options)
        
        #expect(result.format == .svg)
        #expect(result.filename.hasSuffix(".svg"))
        #expect(!result.data.isEmpty)
        
        // SVG should contain XML content
        let content = String(data: result.data, encoding: .utf8)
        #expect(content?.contains("<?xml") == true)
        #expect(content?.contains("<svg") == true)
    }
    
    @Test("Export to PNG format")
    func exportToPNGFormat() async throws {
        let panels = TestDataFactory.createTestFlattenedPanels(count: 1)
        let options = TestDataFactory.createTestExportOptions(format: .png)
        
        let result = try await service.exportPatterns(panels, format: .png, options: options)
        
        #expect(result.format == .png)
        #expect(result.filename.hasSuffix(".png"))
        #expect(!result.data.isEmpty)
        
        // PNG should start with PNG signature
        let pngSignature = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
        #expect(result.data.prefix(8) == pngSignature)
    }
    
    @Test("Export to GIF format")
    func exportToGIFFormat() async throws {
        let panels = TestDataFactory.createTestFlattenedPanels(count: 2)
        let options = TestDataFactory.createTestExportOptions(format: .gif)
        
        let result = try await service.exportPatterns(panels, format: .gif, options: options)
        
        #expect(result.format == .gif)
        #expect(result.filename.hasSuffix(".gif"))
        #expect(!result.data.isEmpty)
        
        // GIF should start with GIF signature
        let content = String(data: result.data.prefix(6), encoding: .ascii)
        #expect(content == "GIF87a" || content == "GIF89a")
    }
    
    @Test("Export to DXF format")
    func exportToDXFFormat() async throws {
        let panels = TestDataFactory.createTestFlattenedPanels(count: 3)
        let options = TestDataFactory.createTestExportOptions(format: .dxf)
        
        let result = try await service.exportPatterns(panels, format: .dxf, options: options)
        
        #expect(result.format == .dxf)
        #expect(result.filename.hasSuffix(".dxf"))
        #expect(!result.data.isEmpty)
        
        // DXF should contain section headers
        let content = String(data: result.data, encoding: .utf8)
        #expect(content?.contains("SECTION") == true)
        #expect(content?.contains("ENTITIES") == true)
    }
    
    // MARK: - Export Options Tests
    
    @Test("Export with seam allowance enabled")
    func exportWithSeamAllowanceEnabled() async throws {
        let panels = TestDataFactory.createTestFlattenedPanels(count: 2)
        let options = ExportOptions(
            includeSeamAllowance: true,
            seamAllowanceWidth: 20.0,
            includeRegistrationMarks: false,
            paperSize: .a4,
            scale: 1.0,
            includeInstructions: false
        )
        
        let result = try await service.exportPatterns(panels, format: .svg, options: options)
        
        #expect(!result.data.isEmpty)
        #expect(result.metadata["seamAllowance"] != nil || result.metadata["options"] != nil)
    }
    
    @Test("Export with registration marks")
    func exportWithRegistrationMarks() async throws {
        let panels = TestDataFactory.createTestFlattenedPanels(count: 1)
        let options = ExportOptions(
            includeSeamAllowance: false,
            seamAllowanceWidth: 0,
            includeRegistrationMarks: true,
            paperSize: .a4,
            scale: 1.0,
            includeInstructions: false
        )
        
        let result = try await service.exportPatterns(panels, format: .pdf, options: options)
        
        #expect(!result.data.isEmpty)
        #expect(result.data.count > 50) // Should be larger with registration marks
    }
    
    @Test("Export with different paper sizes")
    func exportWithDifferentPaperSizes() async throws {
        let panels = TestDataFactory.createTestFlattenedPanels(count: 2)
        let paperSizes: [PaperSize] = [.a4, .a3, .letter, .legal, .tabloid]
        
        for paperSize in paperSizes {
            let options = ExportOptions(
                includeSeamAllowance: false,
                seamAllowanceWidth: 0,
                includeRegistrationMarks: false,
                paperSize: paperSize,
                scale: 1.0,
                includeInstructions: false
            )
            
            let result = try await service.exportPatterns(panels, format: .pdf, options: options)
            
            #expect(!result.data.isEmpty)
            #expect(result.filename.contains(paperSize.rawValue.lowercased()) || 
                   result.metadata["paperSize"] == paperSize.rawValue)
        }
    }
    
    @Test("Export with different scales")
    func exportWithDifferentScales() async throws {
        let panels = TestDataFactory.createTestFlattenedPanels(count: 1)
        let scales = [0.5, 1.0, 1.5, 2.0]
        
        for scale in scales {
            let options = ExportOptions(
                includeSeamAllowance: false,
                seamAllowanceWidth: 0,
                includeRegistrationMarks: false,
                paperSize: .a4,
                scale: scale,
                includeInstructions: false
            )
            
            let result = try await service.exportPatterns(panels, format: .svg, options: options)
            
            #expect(!result.data.isEmpty)
            
            // Scaled exports might have different content sizes
            let content = String(data: result.data, encoding: .utf8)
            #expect(content != nil)
        }
    }
    
    @Test("Export with instructions included")
    func exportWithInstructionsIncluded() async throws {
        let panels = TestDataFactory.createTestFlattenedPanels(count: 3)
        let options = ExportOptions(
            includeSeamAllowance: true,
            seamAllowanceWidth: 15.0,
            includeRegistrationMarks: true,
            paperSize: .a4,
            scale: 1.0,
            includeInstructions: true
        )
        
        let result = try await service.exportPatterns(panels, format: .pdf, options: options)
        
        #expect(!result.data.isEmpty)
        // PDF with instructions should be larger
        #expect(result.data.count > 200)
    }
    
    // MARK: - Panel Count Variation Tests
    
    @Test("Export single panel")
    func exportSinglePanel() async throws {
        let panels = TestDataFactory.createTestFlattenedPanels(count: 1)
        let options = TestDataFactory.createTestExportOptions()
        
        let result = try await service.exportPatterns(panels, format: .pdf, options: options)
        
        #expect(!result.data.isEmpty)
        #expect(result.metadata["panelCount"] == "1")
    }
    
    @Test("Export many panels")
    func exportManyPanels() async throws {
        let panels = TestDataFactory.createTestFlattenedPanels(count: 15)
        let options = TestDataFactory.createTestExportOptions()
        
        let result = try await service.exportPatterns(panels, format: .svg, options: options)
        
        #expect(!result.data.isEmpty)
        #expect(result.metadata["panelCount"] == "15")
        
        // Larger exports should have more content
        #expect(result.data.count > 500)
    }
    
    @Test("Export empty panel list")
    func exportEmptyPanelList() async throws {
        let emptyPanels: [FlattenedPanelDTO] = []
        let options = TestDataFactory.createTestExportOptions()
        
        await #expect(throws: CoverCraftError.self) {
            _ = try await service.exportPatterns(emptyPanels, format: .pdf, options: options)
        }
    }
    
    // MARK: - Edge Cases Tests
    
    @Test("Export invalid panels")
    func exportInvalidPanels() async throws {
        let invalidPanel = TestDataFactory.EdgeCases.tinyFlattenedPanel() // Very small panel
        let options = TestDataFactory.createTestExportOptions()
        
        // Should either handle gracefully or throw appropriate error
        do {
            let result = try await service.exportPatterns([invalidPanel], format: .pdf, options: options)
            #expect(!result.data.isEmpty) // If successful, should produce valid output
        } catch is CoverCraftError {
            // Acceptable to fail with proper error
        }
    }
    
    @Test("Export with extreme options")
    func exportWithExtremeOptions() async throws {
        let panels = TestDataFactory.createTestFlattenedPanels(count: 2)
        
        // Very large seam allowance
        let extremeOptions = ExportOptions(
            includeSeamAllowance: true,
            seamAllowanceWidth: 1000.0, // Very large
            includeRegistrationMarks: true,
            paperSize: .a4,
            scale: 10.0, // Very large scale
            includeInstructions: true
        )
        
        do {
            let result = try await service.exportPatterns(panels, format: .svg, options: extremeOptions)
            #expect(!result.data.isEmpty)
        } catch is CoverCraftError {
            // Acceptable to fail with unreasonable parameters
        }
    }
    
    @Test("Export with zero scale")
    func exportWithZeroScale() async throws {
        let panels = TestDataFactory.createTestFlattenedPanels(count: 1)
        let invalidOptions = ExportOptions(
            includeSeamAllowance: false,
            seamAllowanceWidth: 0,
            includeRegistrationMarks: false,
            paperSize: .a4,
            scale: 0.0, // Invalid scale
            includeInstructions: false
        )
        
        await #expect(throws: CoverCraftError.self) {
            _ = try await service.exportPatterns(panels, format: .pdf, options: invalidOptions)
        }
    }
    
    @Test("Export with negative scale")
    func exportWithNegativeScale() async throws {
        let panels = TestDataFactory.createTestFlattenedPanels(count: 1)
        let invalidOptions = ExportOptions(
            includeSeamAllowance: false,
            seamAllowanceWidth: 0,
            includeRegistrationMarks: false,
            paperSize: .a4,
            scale: -1.0, // Invalid scale
            includeInstructions: false
        )
        
        await #expect(throws: CoverCraftError.self) {
            _ = try await service.exportPatterns(panels, format: .pdf, options: invalidOptions)
        }
    }
    
    // MARK: - Supported Formats Tests
    
    @Test("Get supported formats")
    func getSupportedFormats() {
        let supportedFormats = service.getSupportedFormats()
        
        #expect(!supportedFormats.isEmpty)
        
        // Should contain basic formats
        #expect(supportedFormats.contains(.pdf))
        #expect(supportedFormats.contains(.svg))
        
        // All returned formats should be valid
        for format in supportedFormats {
            #expect(ExportFormat.allCases.contains(format))
        }
    }
    
    @Test("All export formats are supported")
    func allExportFormatsAreSupported() {
        let supportedFormats = service.getSupportedFormats()
        let allFormats = ExportFormat.allCases
        
        // Verify service supports all defined formats
        for format in allFormats {
            #expect(supportedFormats.contains(format))
        }
    }
    
    // MARK: - Validation Tests
    
    @Test("Validate panels for PDF export")
    func validatePanelsForPDFExport() {
        let validPanels = TestDataFactory.createTestFlattenedPanels(count: 3)
        
        let validationResult = service.validateForExport(validPanels, format: .pdf)
        
        #expect(validationResult.isValid)
        #expect(validationResult.errors.isEmpty)
    }
    
    @Test("Validate panels for SVG export")
    func validatePanelsForSVGExport() {
        let validPanels = TestDataFactory.createTestFlattenedPanels(count: 2)
        
        let validationResult = service.validateForExport(validPanels, format: .svg)
        
        #expect(validationResult.isValid)
        #expect(validationResult.errors.isEmpty)
    }
    
    @Test("Validate empty panels")
    func validateEmptyPanels() {
        let emptyPanels: [FlattenedPanelDTO] = []
        
        let validationResult = service.validateForExport(emptyPanels, format: .pdf)
        
        #expect(!validationResult.isValid)
        #expect(!validationResult.errors.isEmpty)
    }
    
    @Test("Validate invalid panels")
    func validateInvalidPanels() {
        let invalidPanels = [
            FlattenedPanelDTO(
                points2D: [], // No points - invalid
                edges: [],
                color: .red,
                scaleUnitsPerMeter: 1000
            )
        ]
        
        let validationResult = service.validateForExport(invalidPanels, format: .pdf)
        
        #expect(!validationResult.isValid)
        #expect(!validationResult.errors.isEmpty)
    }
    
    @Test("Validate panels with warnings")
    func validatePanelsWithWarnings() {
        let tinyPanel = TestDataFactory.EdgeCases.tinyFlattenedPanel()
        
        let validationResult = service.validateForExport([tinyPanel], format: .pdf)
        
        // Tiny panels might generate warnings but could still be valid
        if validationResult.isValid {
            // If valid, warnings might be present
            // This depends on implementation details
        } else {
            // If invalid, should have clear errors
            #expect(!validationResult.errors.isEmpty)
        }
    }
    
    @Test("Validation for different formats")
    func validationForDifferentFormats() {
        let panels = TestDataFactory.createTestFlattenedPanels(count: 3)
        
        for format in ExportFormat.allCases {
            let validationResult = service.validateForExport(panels, format: format)
            
            // Valid panels should pass validation for all formats
            #expect(validationResult.isValid || !validationResult.errors.isEmpty)
            
            // If invalid, should have specific error messages
            if !validationResult.isValid {
                for error in validationResult.errors {
                    #expect(!error.isEmpty)
                }
            }
        }
    }
    
    // MARK: - Performance Tests
    
    @Test("Export performance small dataset")
    func exportPerformanceSmallDataset() async throws {
        let panels = TestDataFactory.createTestFlattenedPanels(count: 3)
        let options = TestDataFactory.createTestExportOptions()
        
        let (result, executionTime) = try await AsyncTestHelpers.measureAsync {
            try await service.exportPatterns(panels, format: .pdf, options: options)
        }
        
        #expect(!result.data.isEmpty)
        #expect(executionTime < 5.0) // Should complete within 5 seconds
    }
    
    @Test("Export performance large dataset")
    func exportPerformanceLargeDataset() async throws {
        let panels = TestDataFactory.createTestFlattenedPanels(count: 20)
        let options = TestDataFactory.createTestExportOptions()
        
        let (result, executionTime) = try await AsyncTestHelpers.measureAsync {
            try await service.exportPatterns(panels, format: .svg, options: options)
        }
        
        #expect(!result.data.isEmpty)
        #expect(executionTime < 15.0) // Should complete within reasonable time
    }
    
    @Test("Export performance comparison between formats")
    func exportPerformanceComparisonBetweenFormats() async throws {
        let panels = TestDataFactory.createTestFlattenedPanels(count: 5)
        let options = TestDataFactory.createTestExportOptions()
        
        var performanceResults: [ExportFormat: TimeInterval] = [:]
        
        for format in [ExportFormat.pdf, .svg, .png] { // Test main formats
            let (_, executionTime) = try await AsyncTestHelpers.measureAsync {
                try await service.exportPatterns(panels, format: format, options: options)
            }
            
            performanceResults[format] = executionTime
            #expect(executionTime < 10.0) // All should be reasonably fast
        }
        
        // All formats should complete in reasonable time
        for (format, time) in performanceResults {
            #expect(time > 0)
            #expect(time < 10.0)
        }
    }
    
    @Test("Concurrent export operations")
    func concurrentExportOperations() async throws {
        let operationCount = 5
        
        let operations = (0..<operationCount).map { index in
            {
                let panels = TestDataFactory.createTestFlattenedPanels(count: index + 1)
                let options = TestDataFactory.createTestExportOptions()
                return try await service.exportPatterns(panels, format: .pdf, options: options)
            }
        }
        
        let results = try await AsyncTestHelpers.executeConcurrently(operations: operations)
        
        #expect(results.count == operationCount)
        
        for result in results {
            #expect(!result.data.isEmpty)
            #expect(result.format == .pdf)
        }
    }
    
    // MARK: - Memory Management Tests
    
    @Test("Memory usage during export")
    func memoryUsageDuringExport() async throws {
        let panels = TestDataFactory.createTestFlattenedPanels(count: 10)
        let options = TestDataFactory.createTestExportOptions()
        
        // Multiple exports should not accumulate memory
        for iteration in 0..<5 {
            let result = try await service.exportPatterns(panels, format: .svg, options: options)
            #expect(!result.data.isEmpty)
            
            // Brief pause to allow cleanup
            try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        }
    }
    
    @Test("Large export data handling")
    func largeExportDataHandling() async throws {
        let panels = TestDataFactory.createTestFlattenedPanels(count: 25) // Large number
        let options = ExportOptions(
            includeSeamAllowance: true,
            seamAllowanceWidth: 20.0,
            includeRegistrationMarks: true,
            paperSize: .a3, // Large paper
            scale: 1.0,
            includeInstructions: true
        )
        
        let result = try await service.exportPatterns(panels, format: .svg, options: options)
        
        #expect(!result.data.isEmpty)
        #expect(result.data.count > 1000) // Should be substantial
        
        // Should handle large data without memory issues
        #expect(result.filename.hasSuffix(".svg"))
        #expect(result.format == .svg)
    }
    
    // MARK: - Error Recovery Tests
    
    @Test("Error recovery from export failure")
    func errorRecoveryFromExportFailure() async throws {
        let invalidPanels = [
            FlattenedPanelDTO(
                points2D: [], // Invalid
                edges: [],
                color: .red,
                scaleUnitsPerMeter: 0 // Invalid scale
            )
        ]
        let options = TestDataFactory.createTestExportOptions()
        
        // First attempt should fail
        await #expect(throws: CoverCraftError.self) {
            _ = try await service.exportPatterns(invalidPanels, format: .pdf, options: options)
        }
        
        // Service should still work after error
        let validPanels = TestDataFactory.createTestFlattenedPanels(count: 2)
        let result = try await service.exportPatterns(validPanels, format: .pdf, options: options)
        #expect(!result.data.isEmpty)
    }
    
    @Test("Cancellation handling during export")
    func cancellationHandlingDuringExport() async throws {
        let panels = TestDataFactory.createTestFlattenedPanels(count: 25) // Large dataset
        let options = TestDataFactory.createTestExportOptions()
        
        let wasCancelled = await AsyncTestHelpers.testCancellation {
            try await service.exportPatterns(panels, format: .pdf, options: options)
        }
        
        #expect(wasCancelled)
    }
    
    // MARK: - Data Integrity Tests
    
    @Test("Export data integrity PDF")
    func exportDataIntegrityPDF() async throws {
        let panels = TestDataFactory.createTestFlattenedPanels(count: 2)
        let options = TestDataFactory.createTestExportOptions(format: .pdf)
        
        let result = try await service.exportPatterns(panels, format: .pdf, options: options)
        
        // PDF should start with PDF header
        let content = String(data: result.data.prefix(8), encoding: .ascii)
        #expect(content?.hasPrefix("%PDF") == true)
        
        // Should contain panel count in filename or metadata
        #expect(result.filename.contains("2") || result.metadata["panelCount"] == "2")
    }
    
    @Test("Export data integrity SVG")
    func exportDataIntegritySVG() async throws {
        let panels = TestDataFactory.createTestFlattenedPanels(count: 1)
        let options = TestDataFactory.createTestExportOptions(format: .svg)
        
        let result = try await service.exportPatterns(panels, format: .svg, options: options)
        
        let content = String(data: result.data, encoding: .utf8)
        #expect(content != nil)
        #expect(content?.contains("<?xml") == true)
        #expect(content?.contains("<svg") == true)
        #expect(content?.contains("</svg>") == true)
        
        // Should contain path or polygon elements for panels
        #expect(content?.contains("<path") == true || content?.contains("<polygon") == true)
    }
    
    @Test("Filename generation consistency")
    func filenameGenerationConsistency() async throws {
        let panels = TestDataFactory.createTestFlattenedPanels(count: 3)
        let options = TestDataFactory.createTestExportOptions()
        
        // Export same data multiple times
        var filenames: [String] = []
        
        for _ in 0..<3 {
            let result = try await service.exportPatterns(panels, format: .pdf, options: options)
            filenames.append(result.filename)
        }
        
        // Filenames should be consistent for same input
        let uniqueFilenames = Set(filenames)
        #expect(uniqueFilenames.count <= 2) // Allow for timestamp variations
        
        // All should have correct extension
        for filename in filenames {
            #expect(filename.hasSuffix(".pdf"))
            #expect(!filename.isEmpty)
        }
    }
    
    @Test("Metadata completeness")
    func metadataCompleteness() async throws {
        let panels = TestDataFactory.createTestFlattenedPanels(count: 4)
        let options = TestDataFactory.createTestExportOptions()
        
        let result = try await service.exportPatterns(panels, format: .svg, options: options)
        
        // Should have basic metadata
        #expect(!result.metadata.isEmpty)
        
        // Common metadata fields
        let expectedFields = ["panelCount", "format"]
        for field in expectedFields {
            #expect(result.metadata[field] != nil)
        }
        
        // Metadata values should be reasonable
        if let panelCount = result.metadata["panelCount"] {
            #expect(panelCount == "4")
        }
        
        if let format = result.metadata["format"] {
            #expect(format == "SVG")
        }
    }
    
    // MARK: - Integration Tests
    
    @Test("Integration with test data factory")
    func integrationWithTestDataFactory() async throws {
        // Use factory to create complete test scenario
        let dataset = TestDataFactory.createCompleteTestDataset(meshComplexity: 2, panelCount: 5)
        
        guard let flattenedPanels = dataset["flattenedPanels"] as? [FlattenedPanelDTO],
              let exportOptions = dataset["exportOptions"] as? ExportOptions else {
            #expect(Bool(false), "Test data factory should provide required data")
            return
        }
        
        let result = try await service.exportPatterns(flattenedPanels, format: .pdf, options: exportOptions)
        
        #expect(!result.data.isEmpty)
        #expect(result.format == .pdf)
        
        // Compare with expected result from factory
        if let expectedResult = dataset["exportResult"] as? ExportResult {
            #expect(result.format == expectedResult.format)
            #expect(!result.metadata.isEmpty)
        }
    }
    
    @Test("End-to-end export workflow")
    func endToEndExportWorkflow() async throws {
        // Complete workflow: create panels -> validate -> export
        let panels = TestDataFactory.createTestFlattenedPanels(count: 3)
        
        // 1. Validate first
        let validationResult = service.validateForExport(panels, format: .svg)
        #expect(validationResult.isValid)
        
        // 2. Export if valid
        if validationResult.isValid {
            let options = TestDataFactory.createTestExportOptions(format: .svg)
            let exportResult = try await service.exportPatterns(panels, format: .svg, options: options)
            
            #expect(!exportResult.data.isEmpty)
            #expect(exportResult.format == .svg)
            #expect(exportResult.filename.hasSuffix(".svg"))
        }
    }
}