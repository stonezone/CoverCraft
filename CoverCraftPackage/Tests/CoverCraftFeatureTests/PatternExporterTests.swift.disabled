import Testing
import Foundation
import CoreGraphics
import simd
@testable import CoverCraftFeature

/// Tests for PatternExporter multi-format export functionality
@Suite("PatternExporter Tests")
struct PatternExporterTests {
    
    let exporter = PatternExporter()
    
    // MARK: - Basic Functionality Tests
    
    @Test("Exporter initializes correctly")
    func exporterInitialization() async throws {
        let service = PatternExporter()
        #expect(service != nil)
    }
    
    @Test("Empty panels array throws appropriate error")
    func emptyPanelsHandling() async throws {
        await #expect(throws: PatternExporter.ExportError.self) {
            try await exporter.exportPattern([], format: .png)
        }
    }
    
    // MARK: - PNG Export Tests
    
    @Test("PNG export creates valid file")
    func pngExportSuccess() async throws {
        let panels = createTestPanels()
        let url = try await exporter.exportPattern(panels, format: .png)
        
        #expect(FileManager.default.fileExists(atPath: url.path), "PNG file should exist")
        #expect(url.pathExtension.lowercased() == "png", "File extension should be PNG")
        
        // Verify file has content
        let data = try Data(contentsOf: url)
        #expect(data.count > 0, "PNG file should not be empty")
        
        // Clean up
        try? FileManager.default.removeItem(at: url)
    }
    
    @Test("PNG file contains valid image data")
    func pngImageValidation() async throws {
        let panels = createTestPanels()
        let url = try await exporter.exportPattern(panels, format: .png)
        
        defer { try? FileManager.default.removeItem(at: url) }
        
        let data = try Data(contentsOf: url)
        
        // Check PNG header signature
        let pngHeader: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
        #expect(data.count >= 8, "PNG file should be at least 8 bytes")
        
        let fileHeader = Array(data.prefix(8))
        #expect(fileHeader == pngHeader, "File should have valid PNG header")
    }
    
    // MARK: - GIF Export Tests
    
    @Test("GIF export creates animated file")
    func gifExportSuccess() async throws {
        let panels = createTestPanels()
        let url = try await exporter.exportPattern(panels, format: .gif)
        
        #expect(FileManager.default.fileExists(atPath: url.path), "GIF file should exist")
        #expect(url.pathExtension.lowercased() == "gif", "File extension should be GIF")
        
        let data = try Data(contentsOf: url)
        #expect(data.count > 0, "GIF file should not be empty")
        
        // Clean up
        try? FileManager.default.removeItem(at: url)
    }
    
    @Test("GIF file contains valid header")
    func gifFormatValidation() async throws {
        let panels = createTestPanels()
        let url = try await exporter.exportPattern(panels, format: .gif)
        
        defer { try? FileManager.default.removeItem(at: url) }
        
        let data = try Data(contentsOf: url)
        #expect(data.count >= 6, "GIF file should be at least 6 bytes")
        
        // Check GIF header
        let gifHeader = String(data: data.prefix(6), encoding: .ascii)
        #expect(gifHeader == "GIF87a" || gifHeader == "GIF89a", "File should have valid GIF header")
    }    
    // MARK: - SVG Export Tests
    
    @Test("SVG export creates valid XML file")
    func svgExportSuccess() async throws {
        let panels = createTestPanels()
        let url = try await exporter.exportPattern(panels, format: .svg)
        
        #expect(FileManager.default.fileExists(atPath: url.path), "SVG file should exist")
        #expect(url.pathExtension.lowercased() == "svg", "File extension should be SVG")
        
        let content = try String(contentsOf: url)
        #expect(content.count > 0, "SVG file should not be empty")
        
        // Clean up
        try? FileManager.default.removeItem(at: url)
    }
    
    @Test("SVG contains valid XML structure")
    func svgXmlValidation() async throws {
        let panels = createTestPanels()
        let url = try await exporter.exportPattern(panels, format: .svg)
        
        defer { try? FileManager.default.removeItem(at: url) }
        
        let content = try String(contentsOf: url)
        
        #expect(content.contains("<?xml version=\"1.0\""), "SVG should have XML declaration")
        #expect(content.contains("<svg"), "SVG should have svg opening tag")
        #expect(content.contains("</svg>"), "SVG should have svg closing tag")
        #expect(content.contains("xmlns=\"http://www.w3.org/2000/svg\""), "SVG should have namespace")
        #expect(content.contains("Panel 1"), "SVG should contain panel labels")
        #expect(content.contains("10 cm"), "SVG should contain scale bar")
    }    
    // MARK: - PDF Export Tests
    
    @Test("PDF Letter export creates valid file")
    func pdfLetterExportSuccess() async throws {
        let panels = createTestPanels()
        let url = try await exporter.exportPattern(panels, format: .pdfLetter)
        
        #expect(FileManager.default.fileExists(atPath: url.path), "PDF file should exist")
        #expect(url.pathExtension.lowercased() == "pdf", "File extension should be PDF")
        #expect(url.lastPathComponent.contains("Letter"), "Filename should indicate Letter size")
        
        let data = try Data(contentsOf: url)
        #expect(data.count > 0, "PDF file should not be empty")
        
        // Clean up
        try? FileManager.default.removeItem(at: url)
    }
    
    @Test("PDF A4 export creates valid file")
    func pdfA4ExportSuccess() async throws {
        let panels = createTestPanels()
        let url = try await exporter.exportPattern(panels, format: .pdfA4)
        
        #expect(FileManager.default.fileExists(atPath: url.path), "PDF file should exist")
        #expect(url.pathExtension.lowercased() == "pdf", "File extension should be PDF")
        #expect(url.lastPathComponent.contains("A4"), "Filename should indicate A4 size")
        
        let data = try Data(contentsOf: url)
        #expect(data.count > 0, "PDF file should not be empty")
        
        // Clean up
        try? FileManager.default.removeItem(at: url)
    }    
    @Test("PDF files have valid PDF header")
    func pdfFormatValidation() async throws {
        let panels = createTestPanels()
        let letterUrl = try await exporter.exportPattern(panels, format: .pdfLetter)
        let a4Url = try await exporter.exportPattern(panels, format: .pdfA4)
        
        defer {
            try? FileManager.default.removeItem(at: letterUrl)
            try? FileManager.default.removeItem(at: a4Url)
        }
        
        for url in [letterUrl, a4Url] {
            let data = try Data(contentsOf: url)
            #expect(data.count >= 4, "PDF file should be at least 4 bytes")
            
            let pdfHeader = String(data: data.prefix(4), encoding: .ascii)
            #expect(pdfHeader == "%PDF", "File should have valid PDF header")
        }
    }
    
    // MARK: - Multiple Panel Export Tests
    
    @Test("Export handles multiple panels correctly")
    func multiplePanelExport() async throws {
        let panels = createComplexTestPanels()
        #expect(panels.count > 1, "Should have multiple panels for this test")
        
        for format in [ExportFormat.png, .gif, .svg, .pdfLetter, .pdfA4] {
            let url = try await exporter.exportPattern(panels, format: format)
            
            #expect(FileManager.default.fileExists(atPath: url.path), 
                   "File should exist for format \(format)")
            
            let data = try Data(contentsOf: url)
            #expect(data.count > 0, "File should not be empty for format \(format)")
            
            // Clean up
            try? FileManager.default.removeItem(at: url)
        }
    }    
    @Test("Export handles single panel correctly")
    func singlePanelExport() async throws {
        let panels = [createSingleTrianglePanel()]
        
        for format in [ExportFormat.png, .svg, .pdfLetter] {
            let url = try await exporter.exportPattern(panels, format: format)
            
            #expect(FileManager.default.fileExists(atPath: url.path), 
                   "Single panel should export successfully")
            
            // Clean up
            try? FileManager.default.removeItem(at: url)
        }
    }
    
    // MARK: - Layout and Scale Tests
    
    @Test("Exported files include scale bars")
    func scaleBarInclusion() async throws {
        let panels = createTestPanels()
        let svgUrl = try await exporter.exportPattern(panels, format: .svg)
        
        defer { try? FileManager.default.removeItem(at: svgUrl) }
        
        let svgContent = try String(contentsOf: svgUrl)
        #expect(svgContent.contains("scale-bar"), "SVG should contain scale bar class")
        #expect(svgContent.contains("10 cm"), "SVG should contain scale bar label")
    }
    
    @Test("Exported files include panel labels")
    func panelLabelInclusion() async throws {
        let panels = createTestPanels()
        let svgUrl = try await exporter.exportPattern(panels, format: .svg)
        
        defer { try? FileManager.default.removeItem(at: svgUrl) }
        
        let svgContent = try String(contentsOf: svgUrl)
        #expect(svgContent.contains("Panel 1"), "SVG should contain panel 1 label")
        #expect(svgContent.contains("Panel 2"), "SVG should contain panel 2 label")
    }    
    // MARK: - Performance Tests
    
    @Test("Export operations complete in reasonable time", .timeLimit(.seconds(30)))
    func exportPerformance() async throws {
        let panels = createComplexTestPanels()
        var exportedUrls: [URL] = []
        
        let startTime = Date()
        
        // Test all formats
        for format in [ExportFormat.png, .gif, .svg, .pdfLetter, .pdfA4] {
            let url = try await exporter.exportPattern(panels, format: format)
            exportedUrls.append(url)
        }
        
        let duration = Date().timeIntervalSince(startTime)
        #expect(duration < 20.0, "All exports should complete within 20 seconds")
        
        // Clean up all files
        for url in exportedUrls {
            try? FileManager.default.removeItem(at: url)
        }
    }
    
    @Test("Concurrent exports work correctly")
    func concurrentExports() async throws {
        let panels = createTestPanels()
        
        // Run multiple exports concurrently
        async let pngExport = exporter.exportPattern(panels, format: .png)
        async let svgExport = exporter.exportPattern(panels, format: .svg)
        async let pdfExport = exporter.exportPattern(panels, format: .pdfLetter)
        
        let (pngUrl, svgUrl, pdfUrl) = try await (pngExport, svgExport, pdfExport)
        
        // Verify all files were created
        #expect(FileManager.default.fileExists(atPath: pngUrl.path), "Concurrent PNG export should succeed")
        #expect(FileManager.default.fileExists(atPath: svgUrl.path), "Concurrent SVG export should succeed")
        #expect(FileManager.default.fileExists(atPath: pdfUrl.path), "Concurrent PDF export should succeed")
        
        // Clean up
        for url in [pngUrl, svgUrl, pdfUrl] {
            try? FileManager.default.removeItem(at: url)
        }
    }    
    // MARK: - Error Handling Tests
    
    @Test("Large panel count handled gracefully")
    func largePanelCount() async throws {
        // Create many panels
        var panels: [FlattenedPanel] = []
        for i in 0..<20 {
            let panel = createSingleTrianglePanel()
            // Offset each panel slightly
            let offsetPoints = panel.points2D.map { 
                CGPoint(x: $0.x + CGFloat(i * 2), y: $0.y + CGFloat(i * 2)) 
            }
            let offsetPanel = FlattenedPanel(
                points2D: offsetPoints,
                edges: panel.edges,
                sourcePanel: panel.sourcePanel,
                boundingBox: panel.boundingBox
            )
            panels.append(offsetPanel)
        }
        
        let url = try await exporter.exportPattern(panels, format: .svg)
        
        #expect(FileManager.default.fileExists(atPath: url.path), "Large panel count should export successfully")
        
        // Clean up
        try? FileManager.default.removeItem(at: url)
    }
    
    // MARK: - File Cleanup Tests
    
    @Test("Temporary files are created in correct location")
    func temporaryFileLocation() async throws {
        let panels = createTestPanels()
        let url = try await exporter.exportPattern(panels, format: .png)
        
        let tempDir = FileManager.default.temporaryDirectory
        #expect(url.path.hasPrefix(tempDir.path), "File should be in temporary directory")
        #expect(url.lastPathComponent.contains("CoverCraft_Pattern"), "Filename should contain app identifier")
        
        // Clean up
        try? FileManager.default.removeItem(at: url)
    }    
    @Test("Multiple exports create unique filenames")
    func uniqueFilenames() async throws {
        let panels = createTestPanels()
        
        let url1 = try await exporter.exportPattern(panels, format: .png)
        let url2 = try await exporter.exportPattern(panels, format: .png)
        let url3 = try await exporter.exportPattern(panels, format: .png)
        
        // Filenames should be unique (timestamp-based)
        let filenames = [url1.lastPathComponent, url2.lastPathComponent, url3.lastPathComponent]
        let uniqueFilenames = Set(filenames)
        
        #expect(uniqueFilenames.count == 3, "All filenames should be unique")
        
        // Clean up
        for url in [url1, url2, url3] {
            try? FileManager.default.removeItem(at: url)
        }
    }
    
    // MARK: - Helper Functions
    
    private func createTestPanels() -> [FlattenedPanel] {
        let mesh = SyntheticMeshes.cube()
        
        // Create two simple panels from cube faces
        let panel1 = Panel(
            vertexIndices: Set([0, 1, 2, 3]), // Front face vertices
            triangleIndices: [0, 1, 2, 0, 2, 3], // Front face triangles
            color: .red
        )
        
        let panel2 = Panel(
            vertexIndices: Set([4, 5, 6, 7]), // Back face vertices  
            triangleIndices: [5, 4, 7, 5, 7, 6], // Back face triangles
            color: .blue
        )
        
        // Create flattened versions
        let flattened1 = FlattenedPanel(
            points2D: [
                CGPoint(x: 0, y: 0),
                CGPoint(x: 100, y: 0),
                CGPoint(x: 100, y: 100),
                CGPoint(x: 0, y: 100)
            ],
            edges: [(0, 1), (1, 2), (2, 3), (3, 0)],
            sourcePanel: panel1,
            boundingBox: CGRect(x: 0, y: 0, width: 100, height: 100)
        )        
        let flattened2 = FlattenedPanel(
            points2D: [
                CGPoint(x: 120, y: 0),
                CGPoint(x: 220, y: 0),
                CGPoint(x: 220, y: 100),
                CGPoint(x: 120, y: 100)
            ],
            edges: [(0, 1), (1, 2), (2, 3), (3, 0)],
            sourcePanel: panel2,
            boundingBox: CGRect(x: 120, y: 0, width: 100, height: 100)
        )
        
        return [flattened1, flattened2]
    }
    
    private func createComplexTestPanels() -> [FlattenedPanel] {
        var panels: [FlattenedPanel] = []
        let colors: [UIColor] = [.red, .blue, .green, .orange, .purple, .cyan]
        
        for i in 0..<6 {
            let panel = Panel(
                vertexIndices: Set([i*4, i*4+1, i*4+2, i*4+3]),
                triangleIndices: [i*4, i*4+1, i*4+2, i*4, i*4+2, i*4+3],
                color: colors[i % colors.count]
            )
            
            let points = [
                CGPoint(x: CGFloat(i * 110), y: 0),
                CGPoint(x: CGFloat(i * 110 + 100), y: 0),
                CGPoint(x: CGFloat(i * 110 + 100), y: 100),
                CGPoint(x: CGFloat(i * 110), y: 100)
            ]
            
            let flattened = FlattenedPanel(
                points2D: points,
                edges: [(0, 1), (1, 2), (2, 3), (3, 0)],
                sourcePanel: panel,
                boundingBox: CGRect(x: CGFloat(i * 110), y: 0, width: 100, height: 100)
            )
            
            panels.append(flattened)
        }
        
        return panels
    }    
    private func createSingleTrianglePanel() -> FlattenedPanel {
        let panel = Panel(
            vertexIndices: Set([0, 1, 2]),
            triangleIndices: [0, 1, 2],
            color: .green
        )
        
        return FlattenedPanel(
            points2D: [
                CGPoint(x: 50, y: 0),
                CGPoint(x: 0, y: 100),
                CGPoint(x: 100, y: 100)
            ],
            edges: [(0, 1), (1, 2), (2, 0)],
            sourcePanel: panel,
            boundingBox: CGRect(x: 0, y: 0, width: 100, height: 100)
        )
    }
    
    // MARK: - Helper Types
    
    enum TestError: Error {
        case invalidTestSetup
    }
}