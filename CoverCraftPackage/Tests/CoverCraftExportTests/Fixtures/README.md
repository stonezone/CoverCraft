# Export Tests Fixtures

This directory contains test fixtures for the Export module, providing configuration data, sample output files, and pattern templates for testing pattern export functionality.

## Overview

The Export fixtures cover:
- **Export Configurations**: Settings for different output formats
- **Sample Output Data**: Valid file data for PDF, SVG, PNG, JPEG
- **Pattern Templates**: Metadata for common sewing patterns
- **Paper Sizes**: Standard paper dimensions and layouts
- **Export Results**: Success/failure scenarios with metadata

## Fixture Files

### ExportFixtures.swift
Contains comprehensive export testing data:

#### Export Format Configurations
- `pdfPatternConfig` - High-quality PDF for printing (300 DPI)
- `svgDigitalConfig` - Scalable vector format for digital use
- `pngPreviewConfig` - Raster preview image (144 DPI)
- `jpegThumbnailConfig` - Compressed thumbnail (72 DPI)
- `professionalPrintConfig` - Professional printing (600 DPI, CMYK)
- `draftModeConfig` - Quick preview (low quality, grayscale)

#### Sample File Data
- `samplePDFData` - Valid minimal PDF file
- `sampleSVGData` - SVG pattern with cut/fold lines
- `samplePNGData` - 1x1 red PNG image
- `sampleJPEGData` - Minimal valid JPEG

#### Pattern Templates
- `tshirtTemplate` - Basic t-shirt sewing pattern
- `dressTemplate` - A-line dress pattern
- `bagTemplate` - Tote bag pattern

#### Export Results
- `successfulExport` - Complete successful export result
- `failedExport` - Export failure with error details
- `exportWithWarnings` - Successful export with warnings

#### Paper Sizes
- `usLetterPaper` - 8.5" × 11" (612 × 792 pts)
- `a4Paper` - 210 × 297 mm (595 × 842 pts)
- `a3Paper` - 297 × 420 mm (842 × 1191 pts)
- `legalPaper` - 8.5" × 14" (612 × 1008 pts)
- `tabloidPaper` - 11" × 17" (792 × 1224 pts)

## Usage Patterns

### Basic Export Configuration Testing
```swift
import Testing
@testable import CoverCraftExport

@Test func exportConfigurationValidation() {
    let config = ExportFixtures.pdfPatternConfig
    
    #expect(config.format == .pdf)
    #expect(config.dpi == 300)
    #expect(config.includeMargins == true)
    #expect(config.colorMode == .rgb)
}
```

### File Format Testing
```swift
@Test func pdfExportTesting() {
    let config = ExportFixtures.pdfPatternConfig
    let panels = FlattenedPanelFixtures.tshirtFlattenedSet
    
    let result = exportToPDF(panels: panels, config: config)
    
    #expect(result.isSuccess)
    #expect(result.format == .pdf)
    #expect(result.outputData != nil)
}
```

### Sample Data Validation
```swift
@Test func sampleDataIntegrity() {
    let pdfData = ExportFixtures.samplePDFData
    let svgData = ExportFixtures.sampleSVGData
    
    // Validate PDF structure
    #expect(pdfData.starts(with: "%PDF".data(using: .utf8)!))
    
    // Validate SVG structure  
    let svgString = String(data: svgData, encoding: .utf8)
    #expect(svgString?.contains("<?xml") == true)
    #expect(svgString?.contains("<svg") == true)
}
```

### Pattern Template Testing
```swift
@Test func patternTemplateValidation() {
    let template = ExportFixtures.tshirtTemplate
    
    #expect(template.name == "Basic T-Shirt")
    #expect(template.category == .apparel)
    #expect(template.difficulty == .beginner)
    #expect(template.sizes.contains("M"))
    #expect(!template.instructions.isEmpty)
}
```

### Paper Size Testing
```swift
@Test func paperSizeCalculations() {
    let usLetter = ExportFixtures.usLetterPaper
    let a4 = ExportFixtures.a4Paper
    
    // US Letter dimensions
    #expect(usLetter.width == 612.0)
    #expect(usLetter.height == 792.0)
    
    // A4 dimensions
    #expect(a4.width == 595.0)
    #expect(a4.height == 842.0)
    
    // Margin calculations
    let usLetterContent = CGSize(
        width: usLetter.width - usLetter.margins.left - usLetter.margins.right,
        height: usLetter.height - usLetter.margins.top - usLetter.margins.bottom
    )
    
    #expect(usLetterContent.width == 540.0) // 612 - 36 - 36
    #expect(usLetterContent.height == 720.0) // 792 - 36 - 36
}
```

### Export Result Testing
```swift
@Test func exportResultHandling() {
    let success = ExportFixtures.successfulExport
    let failure = ExportFixtures.failedExport
    let warning = ExportFixtures.exportWithWarnings
    
    // Successful export
    #expect(success.isSuccess)
    #expect(success.outputData != nil)
    #expect(success.error == nil)
    
    // Failed export
    #expect(!failure.isSuccess)
    #expect(failure.outputData == nil)
    #expect(failure.error != nil)
    
    // Export with warnings
    #expect(warning.isSuccess)
    #expect(warning.outputData != nil)
    #expect(warning.warnings?.isEmpty == false)
}
```

### Multi-Format Export Testing
```swift
@Test func multiFormatExport() {
    let panels = FlattenedPanelFixtures.basicFlattenedShapes
    
    for format in ExportFormat.allCases {
        let config = ExportFixtures.configurationFor(format: format)
        let result = exportPanels(panels, config: config)
        
        #expect(result.format == format)
        
        if result.isSuccess {
            #expect(result.outputData != nil)
            #expect(result.fileSize > 0)
        }
    }
}
```

### Scale and DPI Testing
```swift
@Test func scaleAndResolutionTesting() {
    let highRes = ExportFixtures.professionalPrintConfig
    let lowRes = ExportFixtures.draftModeConfig
    
    #expect(highRes.dpi == 600)
    #expect(highRes.colorMode == .cmyk)
    
    #expect(lowRes.dpi == 72)
    #expect(lowRes.colorMode == .grayscale)
    
    // Same pattern, different resolutions should produce different file sizes
    let panels = [FlattenedPanelFixtures.rectangularFlattened]
    
    let highResResult = exportPanels(panels, config: highRes)
    let lowResResult = exportPanels(panels, config: lowRes)
    
    if highResResult.isSuccess && lowResResult.isSuccess {
        #expect(highResResult.fileSize > lowResResult.fileSize)
    }
}
```

## Test Categories

### Unit Tests - Individual Components
Use specific fixtures:
- Single format configurations
- Individual paper sizes
- Isolated pattern templates
- Sample data validation

### Integration Tests - Complete Workflows  
Use fixture combinations:
- `tshirtFlattenedSet` → `pdfPatternConfig` → `successfulExport`
- Multiple panels with layout optimization
- Cross-format compatibility

### Format-Specific Tests
Use format-specific fixtures:
- PDF: `pdfPatternConfig`, `professionalPrintConfig`
- SVG: `svgDigitalConfig`
- Raster: `pngPreviewConfig`, `jpegThumbnailConfig`

### Error Handling Tests
Use failure scenarios:
- `failedExport` for error processing
- Invalid configurations
- Memory/disk space limitations

### Performance Tests
Use complex scenarios:
- Large panel sets
- High-resolution exports
- Batch processing

## Export Format Testing

### PDF Export Testing
```swift
@Test func pdfExportFeatures() {
    let config = ExportFixtures.pdfPatternConfig
    let panels = FlattenedPanelFixtures.tshirtFlattenedSet
    
    let result = exportToPDF(panels: panels, config: config)
    
    if result.isSuccess {
        // Validate PDF content
        #expect(result.outputData?.starts(with: "%PDF".data(using: .utf8)!) == true)
        
        // Check metadata
        #expect(result.metadata?.originalPanelCount == panels.count)
        #expect(result.metadata?.exportedPanelCount == panels.count)
    }
}
```

### SVG Export Testing
```swift
@Test func svgExportFeatures() {
    let config = ExportFixtures.svgDigitalConfig
    let panel = FlattenedPanelFixtures.allEdgeTypesPanel
    
    let result = exportToSVG(panels: [panel], config: config)
    
    if result.isSuccess, let data = result.outputData {
        let svgString = String(data: data, encoding: .utf8)
        
        // Check for different edge types in SVG
        #expect(svgString?.contains("cut-line") == true)
        #expect(svgString?.contains("fold-line") == true)
        #expect(svgString?.contains("seam-line") == true)
    }
}
```

### Raster Export Testing
```swift
@Test func rasterExportFeatures() {
    let pngConfig = ExportFixtures.pngPreviewConfig
    let jpegConfig = ExportFixtures.jpegThumbnailConfig
    
    let panels = [FlattenedPanelFixtures.rectangularFlattened]
    
    let pngResult = exportToPNG(panels: panels, config: pngConfig)
    let jpegResult = exportToJPEG(panels: panels, config: jpegConfig)
    
    if pngResult.isSuccess {
        // PNG should support transparency
        #expect(pngResult.outputData?.count ?? 0 > 100)
    }
    
    if jpegResult.isSuccess {
        // JPEG should be smaller due to compression
        #expect(jpegResult.fileSize < pngResult.fileSize)
    }
}
```

## Factory Methods

### Dynamic Configuration Creation
```swift
// Create configuration for specific format
let config = ExportFixtures.configurationFor(format: .svg)

// Create configuration with custom size
let customConfig = ExportFixtures.configurationWithSize(
    CGSize(width: 800, height: 600),
    format: .png
)

// Get sample data for format
let sampleData = ExportFixtures.sampleData(for: .pdf)

// Create successful result with custom data
let result = ExportFixtures.successfulExportResult(
    data: myData,
    format: .svg,
    url: fileURL
)

// Create failed result with specific error
let failedResult = ExportFixtures.failedExportResult(
    error: .fileWriteError("Permission denied")
)
```

## Best Practices

### Configuration Testing
- Test all export formats
- Validate DPI and resolution settings
- Check color mode compatibility
- Test margin and layout parameters

### File Output Validation
```swift
// Always check export success first
#expect(result.isSuccess)

// Validate output data exists
#expect(result.outputData != nil)

// Check file size is reasonable
#expect(result.fileSize > 0)
#expect(result.fileSize < maxExpectedSize)

// Verify format-specific structure
switch result.format {
case .pdf:
    #expect(result.outputData?.starts(with: "%PDF".data(using: .utf8)!) == true)
case .svg:
    let string = String(data: result.outputData!, encoding: .utf8)
    #expect(string?.contains("<svg") == true)
case .png:
    #expect(result.outputData?.starts(with: Data([0x89, 0x50, 0x4E, 0x47])) == true)
case .jpeg:
    #expect(result.outputData?.starts(with: Data([0xFF, 0xD8, 0xFF])) == true)
}
```

### Pattern Template Validation
```swift
// Validate template completeness
#expect(!template.name.isEmpty)
#expect(!template.description.isEmpty)
#expect(!template.sizes.isEmpty)
#expect(!template.instructions.isEmpty)

// Check category and difficulty
#expect(PatternCategory.allCases.contains(template.category))
#expect(DifficultyLevel.allCases.contains(template.difficulty))
```

### Error Handling Patterns
```swift
// Test error conditions
let invalidConfig = ExportConfiguration(/* invalid settings */)
let result = exportPanels(panels, config: invalidConfig)

#expect(!result.isSuccess)
#expect(result.error != nil)

// Specific error types
switch result.error {
case .invalidConfiguration(let message):
    #expect(!message.isEmpty)
case .fileWriteError(let message):
    #expect(!message.isEmpty)
case .insufficientMemory:
    // Handle memory constraints
    break
case .none:
    #expect(false, "Expected an error")
}
```

### Performance Considerations
- Use draft mode for performance tests
- Test large panel sets gradually
- Monitor memory usage during export
- Validate export timeouts

## Fixture Maintenance

### Adding New Configurations
1. Follow naming convention: `descriptiveFormatConfig`
2. Use realistic DPI and size values
3. Include appropriate margins and settings
4. Add to `allExportConfigs` collection

### Sample Data Updates
1. Keep sample files minimal but valid
2. Test sample data integrity
3. Update when format specifications change
4. Maintain cross-platform compatibility

### Pattern Template Management
1. Use realistic pattern information
2. Include comprehensive instruction lists
3. Cover various difficulty levels
4. Test template serialization/deserialization

### Quality Assurance
- All configurations produce valid output
- Sample data represents format correctly
- Paper sizes match real-world standards
- Error scenarios provide meaningful messages