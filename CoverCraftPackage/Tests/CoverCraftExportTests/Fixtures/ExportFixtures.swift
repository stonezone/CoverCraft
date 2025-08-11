// Version: 1.0.0
// Test Fixtures for Export Module - Export Format Data

import Foundation
import CoreGraphics
import UniformTypeIdentifiers

/// Test fixtures for export formats and sample output data
@available(iOS 18.0, *)
public struct ExportFixtures {
    
    // MARK: - Export Format Configurations
    
    /// PDF export configuration for pattern printing
    public static let pdfPatternConfig = ExportConfiguration(
        format: .pdf,
        outputSize: CGSize(width: 612.0, height: 792.0), // US Letter (8.5" x 11")
        dpi: 300,
        includeMargins: true,
        marginSize: 36.0, // 0.5 inch margins
        includePatternMarks: true,
        includeDimensions: true,
        includeMetadata: true,
        colorMode: .rgb,
        paperSize: .usLetter
    )
    
    /// SVG export configuration for digital patterns
    public static let svgDigitalConfig = ExportConfiguration(
        format: .svg,
        outputSize: CGSize(width: 1200.0, height: 1600.0), // Digital canvas
        dpi: 72, // SVG is resolution-independent
        includeMargins: false,
        marginSize: 0.0,
        includePatternMarks: true,
        includeDimensions: true,
        includeMetadata: true,
        colorMode: .rgb,
        paperSize: .custom
    )
    
    /// PNG export configuration for preview images
    public static let pngPreviewConfig = ExportConfiguration(
        format: .png,
        outputSize: CGSize(width: 800.0, height: 600.0),
        dpi: 144, // 2x for retina
        includeMargins: true,
        marginSize: 20.0,
        includePatternMarks: false,
        includeDimensions: false,
        includeMetadata: false,
        colorMode: .rgb,
        paperSize: .custom
    )
    
    /// JPEG export configuration for thumbnails
    public static let jpegThumbnailConfig = ExportConfiguration(
        format: .jpeg,
        outputSize: CGSize(width: 300.0, height: 300.0),
        dpi: 72,
        includeMargins: false,
        marginSize: 0.0,
        includePatternMarks: false,
        includeDimensions: false,
        includeMetadata: false,
        colorMode: .rgb,
        paperSize: .custom,
        compressionQuality: 0.8
    )
    
    /// High-resolution PDF for professional printing
    public static let professionalPrintConfig = ExportConfiguration(
        format: .pdf,
        outputSize: CGSize(width: 595.0, height: 842.0), // A4
        dpi: 600, // High resolution for professional printing
        includeMargins: true,
        marginSize: 28.35, // 1cm margins
        includePatternMarks: true,
        includeDimensions: true,
        includeMetadata: true,
        colorMode: .cmyk,
        paperSize: .a4
    )
    
    /// Draft mode configuration for quick previews
    public static let draftModeConfig = ExportConfiguration(
        format: .png,
        outputSize: CGSize(width: 400.0, height: 300.0),
        dpi: 72,
        includeMargins: false,
        marginSize: 0.0,
        includePatternMarks: false,
        includeDimensions: false,
        includeMetadata: false,
        colorMode: .grayscale,
        paperSize: .custom,
        compressionQuality: 0.5
    )
    
    // MARK: - Sample Export Data
    
    /// Sample PDF data (minimal valid PDF)
    public static let samplePDFData: Data = {
        let pdfString = """%PDF-1.4
1 0 obj
<<
/Type /Catalog
/Pages 2 0 R
>>
endobj

2 0 obj
<<
/Type /Pages
/Kids [3 0 R]
/Count 1
>>
endobj

3 0 obj
<<
/Type /Page
/Parent 2 0 R
/MediaBox [0 0 612 792]
/Contents 4 0 R
>>
endobj

4 0 obj
<<
/Length 44
>>
stream
BT
/F1 12 Tf
100 700 Td
(Test Pattern) Tj
ET
endstream
endobj

xref
0 5
0000000000 65535 f 
0000000010 00000 n 
0000000053 00000 n 
0000000108 00000 n 
0000000178 00000 n 
trailer
<<
/Size 5
/Root 1 0 R
>>
startxref
267
%%EOF"""
        return pdfString.data(using: .utf8) ?? Data()
    }()
    
    /// Sample SVG data (simple rectangle pattern)
    public static let sampleSVGData: Data = {
        let svgString = """<?xml version="1.0" encoding="UTF-8"?>
<svg width="400" height="300" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <style>
      .pattern-line { stroke: #000; stroke-width: 1; fill: none; }
      .cut-line { stroke: #000; stroke-width: 2; }
      .fold-line { stroke: #000; stroke-width: 1; stroke-dasharray: 5,5; }
      .seam-line { stroke: #666; stroke-width: 1; }
    </style>
  </defs>
  <g id="pattern-group">
    <rect x="50" y="50" width="100" height="150" class="pattern-line"/>
    <line x1="50" y1="50" x2="150" y2="50" class="cut-line"/>
    <line x1="150" y1="50" x2="150" y2="200" class="cut-line"/>
    <line x1="150" y1="200" x2="50" y2="200" class="cut-line"/>
    <line x1="50" y1="200" x2="50" y2="50" class="cut-line"/>
    <text x="100" y="125" text-anchor="middle" font-size="12">Front Panel</text>
  </g>
</svg>"""
        return svgString.data(using: .utf8) ?? Data()
    }()
    
    /// Sample PNG data (1x1 pixel red PNG)
    public static let samplePNGData: Data = {
        // Minimal 1x1 red PNG file
        let bytes: [UInt8] = [
            0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
            0x00, 0x00, 0x00, 0x0D, // IHDR length
            0x49, 0x48, 0x44, 0x52, // IHDR
            0x00, 0x00, 0x00, 0x01, // Width: 1
            0x00, 0x00, 0x00, 0x01, // Height: 1
            0x08, 0x02, 0x00, 0x00, 0x00, // Bit depth, color type, etc.
            0x90, 0x77, 0x53, 0xDE, // CRC
            0x00, 0x00, 0x00, 0x0C, // IDAT length
            0x49, 0x44, 0x41, 0x54, // IDAT
            0x08, 0x99, 0x01, 0x01, 0x00, 0x00, 0xFE, 0xFF,
            0xFF, 0x00, 0x00, 0x00, 0x02, 0x00, 0x01, // Data
            0x00, 0x00, 0x00, 0x00, // IEND length
            0x49, 0x45, 0x4E, 0x44, // IEND
            0xAE, 0x42, 0x60, 0x82  // CRC
        ]
        return Data(bytes)
    }()
    
    /// Sample JPEG data (minimal valid JPEG)
    public static let sampleJPEGData: Data = {
        // Minimal JPEG structure
        let bytes: [UInt8] = [
            0xFF, 0xD8, 0xFF, 0xE0, // JPEG SOI + APP0
            0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01,
            0x01, 0x01, 0x00, 0x48, 0x00, 0x48, 0x00, 0x00,
            0xFF, 0xDB, 0x00, 0x43, 0x00, // Quantization table
            0x08, 0x06, 0x06, 0x07, 0x06, 0x05, 0x08, 0x07,
            0x07, 0x07, 0x09, 0x09, 0x08, 0x0A, 0x0C, 0x14,
            0x0D, 0x0C, 0x0B, 0x0B, 0x0C, 0x19, 0x12, 0x13,
            0x0F, 0x14, 0x1D, 0x1A, 0x1F, 0x1E, 0x1D, 0x1A,
            0x1C, 0x1C, 0x20, 0x24, 0x2E, 0x27, 0x20, 0x22,
            0x2C, 0x23, 0x1C, 0x1C, 0x28, 0x37, 0x29, 0x2C,
            0x30, 0x31, 0x34, 0x34, 0x34, 0x1F, 0x27, 0x39,
            0x3D, 0x38, 0x32, 0x3C, 0x2E, 0x33, 0x34, 0x32,
            0xFF, 0xD9 // EOI
        ]
        return Data(bytes)
    }()
    
    // MARK: - Pattern Template Data
    
    /// T-shirt pattern template metadata
    public static let tshirtTemplate = PatternTemplate(
        name: "Basic T-Shirt",
        category: .apparel,
        description: "Basic short-sleeve t-shirt pattern",
        difficulty: .beginner,
        estimatedTime: "2-3 hours",
        fabricRequirement: "1.5 yards cotton knit",
        sizes: ["XS", "S", "M", "L", "XL", "XXL"],
        instructions: [
            "Cut front and back panels",
            "Cut two sleeve pieces",
            "Sew shoulder seams",
            "Attach sleeves",
            "Sew side seams",
            "Hem neckline and sleeves",
            "Hem bottom edge"
        ],
        skillsRequired: ["Basic sewing", "Serger/overlock"],
        tools: ["Sewing machine", "Serger", "Scissors", "Pins"],
        tags: ["casual", "knit", "basic", "everyday"],
        version: "1.0"
    )
    
    /// Dress pattern template
    public static let dressTemplate = PatternTemplate(
        name: "A-Line Dress",
        category: .apparel,
        description: "Classic A-line dress with optional sleeves",
        difficulty: .intermediate,
        estimatedTime: "4-6 hours",
        fabricRequirement: "2.5 yards woven cotton",
        sizes: ["6", "8", "10", "12", "14", "16", "18"],
        instructions: [
            "Cut bodice front and back",
            "Cut skirt panels",
            "Cut sleeve pieces (if desired)",
            "Construct bodice",
            "Attach skirt to bodice",
            "Install zipper",
            "Finish seams and hem"
        ],
        skillsRequired: ["Intermediate sewing", "Zipper installation"],
        tools: ["Sewing machine", "Scissors", "Zipper foot", "Iron"],
        tags: ["dress", "woven", "formal", "fitted"],
        version: "1.2"
    )
    
    /// Bag pattern template
    public static let bagTemplate = PatternTemplate(
        name: "Tote Bag",
        category: .accessories,
        description: "Spacious tote bag with interior pockets",
        difficulty: .beginner,
        estimatedTime: "2 hours",
        fabricRequirement: "1 yard canvas + 0.5 yard lining",
        sizes: ["One Size"],
        instructions: [
            "Cut main panels from canvas",
            "Cut lining and pocket pieces",
            "Construct interior pockets",
            "Assemble lining",
            "Assemble outer bag",
            "Attach handles",
            "Join lining to outer bag"
        ],
        skillsRequired: ["Basic sewing", "Topstitching"],
        tools: ["Sewing machine", "Heavy duty needle", "Scissors"],
        tags: ["bag", "canvas", "utility", "everyday"],
        version: "1.0"
    )
    
    // MARK: - Export Result Test Cases
    
    /// Successful export result
    public static let successfulExport = ExportResult(
        isSuccess: true,
        outputData: samplePDFData,
        outputURL: URL(string: "file:///tmp/pattern.pdf")!,
        format: .pdf,
        fileSize: samplePDFData.count,
        exportedAt: Date(timeIntervalSince1970: 1609459200),
        metadata: ExportMetadata(
            originalPanelCount: 4,
            exportedPanelCount: 4,
            totalArea: 0.875, // square meters
            scale: 1000.0,
            dimensions: CGSize(width: 612.0, height: 792.0),
            colorProfile: "sRGB",
            compression: nil
        ),
        error: nil
    )
    
    /// Failed export result (file write error)
    public static let failedExport = ExportResult(
        isSuccess: false,
        outputData: nil,
        outputURL: nil,
        format: .pdf,
        fileSize: 0,
        exportedAt: Date(timeIntervalSince1970: 1609459200),
        metadata: nil,
        error: ExportError.fileWriteError("Permission denied")
    )
    
    /// Export with warnings
    public static let exportWithWarnings = ExportResult(
        isSuccess: true,
        outputData: sampleSVGData,
        outputURL: URL(string: "file:///tmp/pattern.svg")!,
        format: .svg,
        fileSize: sampleSVGData.count,
        exportedAt: Date(timeIntervalSince1970: 1609459200),
        metadata: ExportMetadata(
            originalPanelCount: 5,
            exportedPanelCount: 4, // One panel was too small to export
            totalArea: 0.654,
            scale: 1000.0,
            dimensions: CGSize(width: 1200.0, height: 1600.0),
            colorProfile: "sRGB",
            compression: nil
        ),
        error: nil,
        warnings: ["Panel 'small_detail' was too small to export"]
    )
    
    // MARK: - Paper Sizes and Layout
    
    /// US Letter paper size
    public static let usLetterPaper = PaperSize(
        name: "US Letter",
        width: 612.0,  // 8.5 inches * 72 points
        height: 792.0, // 11 inches * 72 points
        margins: PaperMargins(top: 36, bottom: 36, left: 36, right: 36)
    )
    
    /// A4 paper size
    public static let a4Paper = PaperSize(
        name: "A4",
        width: 595.0,  // 210mm
        height: 842.0, // 297mm
        margins: PaperMargins(top: 28, bottom: 28, left: 28, right: 28)
    )
    
    /// A3 paper size (for large patterns)
    public static let a3Paper = PaperSize(
        name: "A3",
        width: 842.0,  // 297mm
        height: 1191.0, // 420mm
        margins: PaperMargins(top: 36, bottom: 36, left: 36, right: 36)
    )
    
    /// Legal paper size
    public static let legalPaper = PaperSize(
        name: "Legal",
        width: 612.0,  // 8.5 inches
        height: 1008.0, // 14 inches
        margins: PaperMargins(top: 36, bottom: 36, left: 36, right: 36)
    )
    
    /// Tabloid/Ledger paper size
    public static let tabloidPaper = PaperSize(
        name: "Tabloid",
        width: 792.0,  // 11 inches
        height: 1224.0, // 17 inches
        margins: PaperMargins(top: 36, bottom: 36, left: 36, right: 36)
    )
    
    // MARK: - Collections
    
    /// All export configurations
    public static let allExportConfigs: [ExportConfiguration] = [
        pdfPatternConfig,
        svgDigitalConfig,
        pngPreviewConfig,
        jpegThumbnailConfig,
        professionalPrintConfig,
        draftModeConfig
    ]
    
    /// All pattern templates
    public static let allPatternTemplates: [PatternTemplate] = [
        tshirtTemplate,
        dressTemplate,
        bagTemplate
    ]
    
    /// All paper sizes
    public static let allPaperSizes: [PaperSize] = [
        usLetterPaper,
        a4Paper,
        a3Paper,
        legalPaper,
        tabloidPaper
    ]
    
    /// All export results (for testing different outcomes)
    public static let allExportResults: [ExportResult] = [
        successfulExport,
        failedExport,
        exportWithWarnings
    ]
    
    /// Sample export data by format
    public static let sampleDataByFormat: [ExportFormat: Data] = [
        .pdf: samplePDFData,
        .svg: sampleSVGData,
        .png: samplePNGData,
        .jpeg: sampleJPEGData
    ]
    
    // MARK: - Factory Methods
    
    /// Create export configuration for specific format
    public static func configurationFor(format: ExportFormat) -> ExportConfiguration {
        switch format {
        case .pdf:
            return pdfPatternConfig
        case .svg:
            return svgDigitalConfig
        case .png:
            return pngPreviewConfig
        case .jpeg:
            return jpegThumbnailConfig
        }
    }
    
    /// Create configuration with custom size
    public static func configurationWithSize(
        _ size: CGSize,
        format: ExportFormat = .pdf
    ) -> ExportConfiguration {
        ExportConfiguration(
            format: format,
            outputSize: size,
            dpi: format == .pdf ? 300 : 144,
            includeMargins: true,
            marginSize: 36.0,
            includePatternMarks: true,
            includeDimensions: true,
            includeMetadata: true,
            colorMode: .rgb,
            paperSize: .custom
        )
    }
    
    /// Get sample data for format
    public static func sampleData(for format: ExportFormat) -> Data {
        sampleDataByFormat[format] ?? Data()
    }
    
    /// Create successful export result with custom data
    public static func successfulExportResult(
        data: Data,
        format: ExportFormat,
        url: URL? = nil
    ) -> ExportResult {
        ExportResult(
            isSuccess: true,
            outputData: data,
            outputURL: url,
            format: format,
            fileSize: data.count,
            exportedAt: Date(),
            metadata: ExportMetadata(
                originalPanelCount: 4,
                exportedPanelCount: 4,
                totalArea: 0.5,
                scale: 1000.0,
                dimensions: CGSize(width: 400, height: 300),
                colorProfile: "sRGB",
                compression: nil
            ),
            error: nil
        )
    }
    
    /// Create failed export result with specific error
    public static func failedExportResult(error: ExportError) -> ExportResult {
        ExportResult(
            isSuccess: false,
            outputData: nil,
            outputURL: nil,
            format: .pdf,
            fileSize: 0,
            exportedAt: Date(),
            metadata: nil,
            error: error
        )
    }
}

// MARK: - Supporting Data Structures

/// Export configuration settings
@available(iOS 18.0, *)
public struct ExportConfiguration: Sendable, Codable, Equatable {
    public let format: ExportFormat
    public let outputSize: CGSize
    public let dpi: Int
    public let includeMargins: Bool
    public let marginSize: Double
    public let includePatternMarks: Bool
    public let includeDimensions: Bool
    public let includeMetadata: Bool
    public let colorMode: ColorMode
    public let paperSize: PaperSizeType
    public let compressionQuality: Double?
    
    public init(
        format: ExportFormat,
        outputSize: CGSize,
        dpi: Int,
        includeMargins: Bool,
        marginSize: Double,
        includePatternMarks: Bool,
        includeDimensions: Bool,
        includeMetadata: Bool,
        colorMode: ColorMode,
        paperSize: PaperSizeType,
        compressionQuality: Double? = nil
    ) {
        self.format = format
        self.outputSize = outputSize
        self.dpi = dpi
        self.includeMargins = includeMargins
        self.marginSize = marginSize
        self.includePatternMarks = includePatternMarks
        self.includeDimensions = includeDimensions
        self.includeMetadata = includeMetadata
        self.colorMode = colorMode
        self.paperSize = paperSize
        self.compressionQuality = compressionQuality
    }
}

/// Export format types
@available(iOS 18.0, *)
public enum ExportFormat: String, Sendable, Codable, CaseIterable {
    case pdf = "pdf"
    case svg = "svg"
    case png = "png"
    case jpeg = "jpeg"
    
    public var fileExtension: String {
        return rawValue
    }
    
    public var mimeType: String {
        switch self {
        case .pdf: return "application/pdf"
        case .svg: return "image/svg+xml"
        case .png: return "image/png"
        case .jpeg: return "image/jpeg"
        }
    }
    
    public var utType: UTType {
        switch self {
        case .pdf: return .pdf
        case .svg: return .svg
        case .png: return .png
        case .jpeg: return .jpeg
        }
    }
}

/// Color mode for export
@available(iOS 18.0, *)
public enum ColorMode: String, Sendable, Codable, CaseIterable {
    case rgb = "rgb"
    case cmyk = "cmyk"
    case grayscale = "grayscale"
}

/// Paper size type
@available(iOS 18.0, *)
public enum PaperSizeType: String, Sendable, Codable, CaseIterable {
    case usLetter = "us_letter"
    case a4 = "a4"
    case a3 = "a3"
    case legal = "legal"
    case tabloid = "tabloid"
    case custom = "custom"
}

/// Pattern template metadata
@available(iOS 18.0, *)
public struct PatternTemplate: Sendable, Codable, Equatable {
    public let name: String
    public let category: PatternCategory
    public let description: String
    public let difficulty: DifficultyLevel
    public let estimatedTime: String
    public let fabricRequirement: String
    public let sizes: [String]
    public let instructions: [String]
    public let skillsRequired: [String]
    public let tools: [String]
    public let tags: [String]
    public let version: String
    
    public init(
        name: String,
        category: PatternCategory,
        description: String,
        difficulty: DifficultyLevel,
        estimatedTime: String,
        fabricRequirement: String,
        sizes: [String],
        instructions: [String],
        skillsRequired: [String],
        tools: [String],
        tags: [String],
        version: String
    ) {
        self.name = name
        self.category = category
        self.description = description
        self.difficulty = difficulty
        self.estimatedTime = estimatedTime
        self.fabricRequirement = fabricRequirement
        self.sizes = sizes
        self.instructions = instructions
        self.skillsRequired = skillsRequired
        self.tools = tools
        self.tags = tags
        self.version = version
    }
}

@available(iOS 18.0, *)
public enum PatternCategory: String, Sendable, Codable, CaseIterable {
    case apparel = "apparel"
    case accessories = "accessories"
    case home = "home"
    case craft = "craft"
}

@available(iOS 18.0, *)
public enum DifficultyLevel: String, Sendable, Codable, CaseIterable {
    case beginner = "beginner"
    case intermediate = "intermediate"
    case advanced = "advanced"
    case expert = "expert"
}

/// Export result data
@available(iOS 18.0, *)
public struct ExportResult: Sendable, Equatable {
    public let isSuccess: Bool
    public let outputData: Data?
    public let outputURL: URL?
    public let format: ExportFormat
    public let fileSize: Int
    public let exportedAt: Date
    public let metadata: ExportMetadata?
    public let error: ExportError?
    public let warnings: [String]?
    
    public init(
        isSuccess: Bool,
        outputData: Data?,
        outputURL: URL?,
        format: ExportFormat,
        fileSize: Int,
        exportedAt: Date,
        metadata: ExportMetadata?,
        error: ExportError?,
        warnings: [String]? = nil
    ) {
        self.isSuccess = isSuccess
        self.outputData = outputData
        self.outputURL = outputURL
        self.format = format
        self.fileSize = fileSize
        self.exportedAt = exportedAt
        self.metadata = metadata
        self.error = error
        self.warnings = warnings
    }
}

/// Export metadata
@available(iOS 18.0, *)
public struct ExportMetadata: Sendable, Codable, Equatable {
    public let originalPanelCount: Int
    public let exportedPanelCount: Int
    public let totalArea: Double // square meters
    public let scale: Double
    public let dimensions: CGSize
    public let colorProfile: String
    public let compression: String?
    
    public init(
        originalPanelCount: Int,
        exportedPanelCount: Int,
        totalArea: Double,
        scale: Double,
        dimensions: CGSize,
        colorProfile: String,
        compression: String?
    ) {
        self.originalPanelCount = originalPanelCount
        self.exportedPanelCount = exportedPanelCount
        self.totalArea = totalArea
        self.scale = scale
        self.dimensions = dimensions
        self.colorProfile = colorProfile
        self.compression = compression
    }
}

/// Export errors
@available(iOS 18.0, *)
public enum ExportError: Error, Sendable, Equatable {
    case invalidConfiguration(String)
    case fileWriteError(String)
    case insufficientMemory
    case unsupportedFormat(String)
    case renderingFailed(String)
    case networkError(String)
}

/// Paper size definition
@available(iOS 18.0, *)
public struct PaperSize: Sendable, Codable, Equatable {
    public let name: String
    public let width: Double
    public let height: Double
    public let margins: PaperMargins
    
    public init(name: String, width: Double, height: Double, margins: PaperMargins) {
        self.name = name
        self.width = width
        self.height = height
        self.margins = margins
    }
}

@available(iOS 18.0, *)
public struct PaperMargins: Sendable, Codable, Equatable {
    public let top: Double
    public let bottom: Double
    public let left: Double
    public let right: Double
    
    public init(top: Double, bottom: Double, left: Double, right: Double) {
        self.top = top
        self.bottom = bottom
        self.left = left
        self.right = right
    }
}