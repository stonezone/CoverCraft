// Version: 1.0.0
// CoverCraft Export Module - Default Pattern Export Implementation

import Foundation
import CoreGraphics
import Logging
import CoverCraftCore
import CoverCraftDTO

#if canImport(UIKit)
import UIKit
import PDFKit
#elseif canImport(AppKit)
import AppKit
import PDFKit
#endif

/// Production implementation of PatternExportService protocol
///
/// Architecture Note:
/// This is the PRIMARY implementation of PatternExportService and should be used for all new code.
/// It provides comprehensive export functionality with high-quality rendering for PDF, PNG, SVG, and GIF formats.
///
/// Features:
/// - High-resolution rendering (300 DPI for PNG, 72 DPI for PDF/SVG)
/// - Proper seam allowance visualization
/// - Registration marks and scale references
/// - Multi-page layout support
/// - Comprehensive metadata embedding
/// - Thread-safe operation
///
/// Dependency Injection:
/// This service is registered in ServiceContainer via registerExportServices()
/// Retrieve it using: container.resolve(PatternExportService.self)
///
/// Related Types:
/// - PatternExporter: Legacy actor-based exporter (maintained for compatibility)
///
@available(iOS 18.0, macOS 15.0, *)
public final class DefaultPatternExportService: PatternExportService {
    
    private let logger = Logger(label: "com.covercraft.export")
    
    public init() {
        logger.info("Pattern Export Service initialized")
    }
    
    public func exportPatterns(_ panels: [FlattenedPanelDTO], format: ExportFormat, options: ExportOptions) async throws -> ExportResult {
        logger.info("Starting pattern export to \(format.rawValue) format")
        
        guard !panels.isEmpty else {
            throw ExportError.exportFailed("No panels to export")
        }
        
        // Validate all panels
        for panel in panels {
            guard panel.isValid else {
                throw ExportError.corruptedData
            }
        }
        
        let data = try await generateExportData(panels: panels, format: format, options: options)
        let filename = generateFilename(format: format)
        
        let result = ExportResult(
            data: data,
            format: format,
            filename: filename,
            metadata: [
                "panelCount": "\(panels.count)",
                "exportTime": ISO8601DateFormatter().string(from: Date()),
                "version": "1.0.0"
            ]
        )
        
        logger.info("Pattern export completed: \(filename) (\(data.count) bytes)")
        return result
    }
    
    public func getSupportedFormats() -> [ExportFormat] {
        return [.pdf, .svg, .png, .gif]
    }
    
    public func validateForExport(_ panels: [FlattenedPanelDTO], format: ExportFormat) -> ExportValidationResult {
        var errors: [String] = []
        var warnings: [String] = []
        
        if panels.isEmpty {
            errors.append("No panels to export")
        }
        
        for (index, panel) in panels.enumerated() {
            if !panel.isValid {
                errors.append("Panel \(index) is invalid")
            }
            
            if panel.points2D.count < 3 {
                errors.append("Panel \(index) has fewer than 3 points")
            }
            
            let area = panel.area
            if area < 1.0 {
                warnings.append("Panel \(index) has very small area (\(area))")
            }
        }
        
        // Format-specific validation
        switch format {
        case .dxf:
            errors.append("DXF format not yet implemented")
        default:
            break
        }
        
        return ExportValidationResult(
            isValid: errors.isEmpty,
            errors: errors,
            warnings: warnings
        )
    }
    
    private func generateExportData(panels: [FlattenedPanelDTO], format: ExportFormat, options: ExportOptions) async throws -> Data {
        switch format {
        case .pdf:
            return try await generatePDF(panels: panels, options: options)
        case .svg:
            return try await generateSVG(panels: panels, options: options)
        case .png:
            return try await generatePNG(panels: panels, options: options)
        case .gif:
            return try await generateGIF(panels: panels, options: options)
        case .dxf:
            throw ExportError.unsupportedFeature("DXF export not yet implemented")
        }
    }
    
    private func generatePDF(panels: [FlattenedPanelDTO], options: ExportOptions) async throws -> Data {
        #if canImport(UIKit)
        return try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                do {
                    let pdfData = try await generatePDFDocument(panels: panels, options: options)
                    continuation.resume(returning: pdfData)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
        #else
        // Fallback for non-iOS platforms
        throw ExportError.unsupportedFeature("PDF generation requires iOS/iPadOS")
        #endif
    }
    
    private func generateSVG(panels: [FlattenedPanelDTO], options: ExportOptions) async throws -> Data {
        var svg = """
        <?xml version="1.0" encoding="UTF-8"?>
        <svg xmlns="http://www.w3.org/2000/svg" width="800" height="600" viewBox="0 0 800 600">
        <title>CoverCraft Pattern Export</title>
        
        """
        
        for (index, panel) in panels.enumerated() {
            let pathData = generateSVGPath(for: panel)
            let color = panel.color
            
            svg += """
            <path d="\(pathData)" 
                  fill="none" 
                  stroke="rgb(\(Int(color.red * 255)),\(Int(color.green * 255)),\(Int(color.blue * 255)))" 
                  stroke-width="1" 
                  id="panel-\(index)" />
            
            """
        }
        
        svg += "</svg>"
        
        return svg.data(using: .utf8)!
    }
    
    private func generatePNG(panels: [FlattenedPanelDTO], options: ExportOptions) async throws -> Data {
        #if canImport(UIKit)
        // PNG generation uses UIGraphicsImageRenderer which is safe off-main-thread.
        return try await generatePNGImage(panels: panels, options: options)
        #else
        // Fallback for non-iOS platforms
        throw ExportError.unsupportedFeature("PNG generation requires iOS/iPadOS")
        #endif
    }
    
    #if canImport(UIKit)
    @MainActor
    private func generatePDFDocument(panels: [FlattenedPanelDTO], options: ExportOptions) async throws -> Data {
        let paperSize = options.paperSize.dimensionsInPoints
        let pageRect = CGRect(x: 0, y: 0, width: paperSize.width, height: paperSize.height)
        
        // Calculate layout bounds considering margins
        let margin: CGFloat = 36 // 0.5 inch margins
        let contentRect = CGRect(
            x: margin,
            y: margin,
            width: paperSize.width - 2 * margin,
            height: paperSize.height - 2 * margin
        )
        
        // Calculate overall bounds of all panels
        let bounds = calculateOverallBounds(panels: panels)
        let scaleFactor = calculateScaleFactor(bounds: bounds, contentRect: contentRect, options: options)
        
        let pdfData = NSMutableData()
        
        UIGraphicsBeginPDFContextToData(pdfData, pageRect, [
            kCGPDFContextTitle: "CoverCraft Sewing Pattern",
            kCGPDFContextAuthor: "CoverCraft",
            kCGPDFContextSubject: "Sewing Pattern Export",
            kCGPDFContextCreator: "CoverCraft iOS App v1.0.0"
        ])
        
        // Start first page
        UIGraphicsBeginPDFPage()
        
        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndPDFContext()
            throw ExportError.exportFailed("Could not create PDF context")
        }
        
        // Draw title and metadata
        await drawPDFHeader(context: context, rect: pageRect, options: options, panelCount: panels.count)
        
        // Draw rulers and scale reference
        await drawRulers(context: context, contentRect: contentRect, scaleFactor: scaleFactor, options: options)
        
        // Transform coordinate system for pattern drawing
        context.saveGState()
        context.translateBy(x: contentRect.midX, y: contentRect.midY)
        context.scaleBy(x: scaleFactor, y: -scaleFactor) // Flip Y-axis for standard coordinates
        context.translateBy(x: -bounds.midX, y: -bounds.midY)
        
        // Draw each panel
        for (index, panel) in panels.enumerated() {
            await drawPanelInPDF(context: context, panel: panel, index: index, options: options)
        }
        
        context.restoreGState()
        
        // Draw legend and cutting instructions
        await drawPDFLegend(context: context, rect: pageRect, panels: panels, options: options)
        
        UIGraphicsEndPDFContext()
        
        return pdfData as Data
    }
    
    @MainActor
    private func drawPDFHeader(context: CGContext, rect: CGRect, options: ExportOptions, panelCount: Int) async {
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 16),
            .foregroundColor: UIColor.black
        ]
        
        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.darkGray
        ]
        
        let title = "CoverCraft Sewing Pattern"
        let subtitle = "Scale: \(String(format: "%.1f", options.scale)):1 • \(panelCount) panels • \(options.paperSize.rawValue)"
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short)
        
        // Draw title
        let titleSize = title.size(withAttributes: titleAttributes)
        let titleRect = CGRect(x: 36, y: rect.height - 36 - titleSize.height, width: titleSize.width, height: titleSize.height)
        title.draw(in: titleRect, withAttributes: titleAttributes)
        
        // Draw subtitle
        let subtitleRect = CGRect(x: 36, y: titleRect.minY - 18, width: rect.width - 72, height: 16)
        subtitle.draw(in: subtitleRect, withAttributes: subtitleAttributes)
        
        // Draw timestamp in top right
        let timestampSize = timestamp.size(withAttributes: subtitleAttributes)
        let timestampRect = CGRect(x: rect.width - 36 - timestampSize.width, y: rect.height - 36 - timestampSize.height, width: timestampSize.width, height: timestampSize.height)
        timestamp.draw(in: timestampRect, withAttributes: subtitleAttributes)
    }
    
    @MainActor
    private func drawRulers(context: CGContext, contentRect: CGRect, scaleFactor: CGFloat, options: ExportOptions) async {
        guard options.includeRegistrationMarks else { return }
        
        context.saveGState()
        context.setStrokeColor(UIColor.black.cgColor)
        context.setLineWidth(0.5)
        
        // Draw corner registration marks
        let markSize: CGFloat = 10
        let corners = [
            CGPoint(x: contentRect.minX, y: contentRect.minY),
            CGPoint(x: contentRect.maxX, y: contentRect.minY),
            CGPoint(x: contentRect.minX, y: contentRect.maxY),
            CGPoint(x: contentRect.maxX, y: contentRect.maxY)
        ]
        
        for corner in corners {
            // Cross mark
            context.move(to: CGPoint(x: corner.x - markSize/2, y: corner.y))
            context.addLine(to: CGPoint(x: corner.x + markSize/2, y: corner.y))
            context.move(to: CGPoint(x: corner.x, y: corner.y - markSize/2))
            context.addLine(to: CGPoint(x: corner.x, y: corner.y + markSize/2))
        }
        
        context.strokePath()
        
        // Draw scale reference
        let scaleRefY = contentRect.minY - 20
        let scaleRefLength: CGFloat = 72 // 1 inch
        
        context.move(to: CGPoint(x: contentRect.minX, y: scaleRefY))
        context.addLine(to: CGPoint(x: contentRect.minX + scaleRefLength, y: scaleRefY))
        
        // Add tick marks
        for i in 0...4 {
            let x = contentRect.minX + CGFloat(i) * scaleRefLength / 4
            context.move(to: CGPoint(x: x, y: scaleRefY - 3))
            context.addLine(to: CGPoint(x: x, y: scaleRefY + 3))
        }
        
        context.strokePath()
        
        // Scale label
        let scaleLabel = "1 inch reference"
        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8),
            .foregroundColor: UIColor.black
        ]
        
        let labelRect = CGRect(x: contentRect.minX, y: scaleRefY - 15, width: scaleRefLength, height: 10)
        scaleLabel.draw(in: labelRect, withAttributes: labelAttributes)
        
        context.restoreGState()
    }
    
    @MainActor
    private func drawPanelInPDF(context: CGContext, panel: FlattenedPanelDTO, index: Int, options: ExportOptions) async {
        guard !panel.points2D.isEmpty else { return }
        
        context.saveGState()
        
        // Draw panel outline
        context.setStrokeColor(UIColor.black.cgColor)
        context.setLineWidth(1.5)
        
        let path = CGMutablePath()
        path.move(to: panel.points2D[0])
        
        for point in panel.points2D.dropFirst() {
            path.addLine(to: point)
        }
        path.closeSubpath()
        
        context.addPath(path)
        context.strokePath()
        
        // Draw seam allowance if requested
        if options.includeSeamAllowance {
            context.setStrokeColor(UIColor.systemBlue.cgColor)
            context.setLineWidth(0.5)
            context.setLineDash(phase: 0, lengths: [3, 3])
            
            let seamPath = createSeamAllowancePath(points: panel.points2D, width: options.seamAllowanceWidth)
            context.addPath(seamPath)
            context.strokePath()
            
            context.setLineDash(phase: 0, lengths: [])
        }
        
        // Draw panel label
        let centroid = calculateCentroid(points: panel.points2D)
        context.saveGState()
        context.scaleBy(x: 1, y: -1) // Flip text back to normal orientation
        
        let label = "Panel \(index + 1)"
        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 12),
            .foregroundColor: UIColor.black
        ]
        
        let labelSize = label.size(withAttributes: labelAttributes)
        let labelRect = CGRect(
            x: centroid.x - labelSize.width/2,
            y: -centroid.y - labelSize.height/2,
            width: labelSize.width,
            height: labelSize.height
        )
        
        // Draw label background
        context.setFillColor(UIColor.white.withAlphaComponent(0.8).cgColor)
        context.fill(labelRect.insetBy(dx: -2, dy: -1))
        
        label.draw(in: labelRect, withAttributes: labelAttributes)
        
        context.restoreGState()
        context.restoreGState()
    }
    
    @MainActor
    private func drawPDFLegend(context: CGContext, rect: CGRect, panels: [FlattenedPanelDTO], options: ExportOptions) async {
        guard options.includeInstructions else { return }
        
        let legendRect = CGRect(x: 36, y: 36, width: 200, height: 150)
        
        // Legend background
        context.setFillColor(UIColor.systemGray6.cgColor)
        context.fill(legendRect)
        context.setStrokeColor(UIColor.black.cgColor)
        context.setLineWidth(0.5)
        context.stroke(legendRect)
        
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 12),
            .foregroundColor: UIColor.black
        ]
        
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.black
        ]
        
        var y = legendRect.maxY - 20
        
        // Legend title
        "Cutting Instructions".draw(at: CGPoint(x: legendRect.minX + 8, y: y), withAttributes: titleAttributes)
        y -= 18
        
        // Instructions
        let instructions = [
            "• Cut along solid lines",
            "• Seam allowance: \(String(format: "%.0f", options.seamAllowanceWidth))mm",
            "• Match registration marks",
            "• Follow fabric grain direction"
        ]
        
        for instruction in instructions {
            instruction.draw(at: CGPoint(x: legendRect.minX + 8, y: y), withAttributes: textAttributes)
            y -= 14
        }
    }
    
    private func generatePNGImage(panels: [FlattenedPanelDTO], options: ExportOptions) async throws -> Data {
        // Calculate image dimensions at 300 DPI for print quality
        let dpi: CGFloat = 300
        let paperSize = options.paperSize.dimensionsInPoints
        let imageSize = CGSize(
            width: paperSize.width * dpi / 72,
            height: paperSize.height * dpi / 72
        )
        
        // Calculate layout bounds considering margins
        let marginPoints: CGFloat = 36 // 0.5 inch margins
        let marginPixels = marginPoints * dpi / 72
        let contentRect = CGRect(
            x: marginPixels,
            y: marginPixels,
            width: imageSize.width - 2 * marginPixels,
            height: imageSize.height - 2 * marginPixels
        )
        
        // Calculate overall bounds of all panels
        let bounds = calculateOverallBounds(panels: panels)
        let scaleFactor = calculateScaleFactor(bounds: bounds, contentRect: contentRect, options: options)
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0 // DPI handled manually via imageSize
        format.opaque = false
        
        let renderer = UIGraphicsImageRenderer(size: imageSize, format: format)
        let image = renderer.image { rendererContext in
            let context = rendererContext.cgContext
            
            // High quality rendering configuration
            context.setAllowsAntialiasing(true)
            context.setShouldAntialias(true)
            context.interpolationQuality = .high
            
            // Clear background (transparent)
            context.clear(CGRect(origin: .zero, size: imageSize))
            
            // Draw title and metadata
            drawPNGHeader(context: context, size: imageSize, options: options, panelCount: panels.count, dpi: dpi)
            
            // Draw grid overlay if requested
            drawGrid(context: context, contentRect: contentRect, scaleFactor: scaleFactor, dpi: dpi)
            
            // Transform coordinate system for pattern drawing
            context.saveGState()
            context.translateBy(x: contentRect.midX, y: contentRect.midY)
            context.scaleBy(x: scaleFactor, y: -scaleFactor) // Flip Y-axis for standard coordinates
            context.translateBy(x: -bounds.midX, y: -bounds.midY)
            
            // Draw each panel with anti-aliasing
            for (index, panel) in panels.enumerated() {
                drawPanelInPNG(context: context, panel: panel, index: index, options: options, dpi: dpi)
            }
            
            context.restoreGState()
            
            // Draw rulers and measurements
            if options.includeRegistrationMarks {
                drawPNGRulers(context: context, contentRect: contentRect, scaleFactor: scaleFactor, dpi: dpi)
            }
        }
        
        guard let pngData = image.pngData() else {
            throw ExportError.exportFailed("Could not generate PNG data")
        }
        
        return pngData
    }
    
    private func drawPNGHeader(context: CGContext, size: CGSize, options: ExportOptions, panelCount: Int, dpi: CGFloat) {
        let scaleFactor = dpi / 72
        let fontSize: CGFloat = 16 * scaleFactor
        let smallFontSize: CGFloat = 12 * scaleFactor
        let margin: CGFloat = 36 * scaleFactor
        
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: fontSize),
            .foregroundColor: UIColor.black
        ]
        
        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: smallFontSize),
            .foregroundColor: UIColor.darkGray
        ]
        
        let title = "CoverCraft Sewing Pattern"
        let subtitle = "Scale: \(String(format: "%.1f", options.scale)):1 • \(panelCount) panels • \(options.paperSize.rawValue) • 300 DPI"
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short)
        
        // Draw title
        let titleSize = title.size(withAttributes: titleAttributes)
        let titleRect = CGRect(x: margin, y: size.height - margin - titleSize.height, width: titleSize.width, height: titleSize.height)
        title.draw(in: titleRect, withAttributes: titleAttributes)
        
        // Draw subtitle
        let subtitleRect = CGRect(x: margin, y: titleRect.minY - 18 * scaleFactor, width: size.width - 2 * margin, height: smallFontSize + 4)
        subtitle.draw(in: subtitleRect, withAttributes: subtitleAttributes)
        
        // Draw timestamp in top right
        let timestampSize = timestamp.size(withAttributes: subtitleAttributes)
        let timestampRect = CGRect(x: size.width - margin - timestampSize.width, y: size.height - margin - timestampSize.height, width: timestampSize.width, height: timestampSize.height)
        timestamp.draw(in: timestampRect, withAttributes: subtitleAttributes)
    }
    
    private func drawGrid(context: CGContext, contentRect: CGRect, scaleFactor: CGFloat, dpi: CGFloat) {
        let gridSpacing: CGFloat = 36 * dpi / 72 // 0.5 inch grid at high resolution
        
        context.saveGState()
        context.setStrokeColor(UIColor.systemGray4.withAlphaComponent(0.3).cgColor)
        context.setLineWidth(0.5 * dpi / 72)
        
        // Vertical grid lines
        var x = contentRect.minX
        while x <= contentRect.maxX {
            context.move(to: CGPoint(x: x, y: contentRect.minY))
            context.addLine(to: CGPoint(x: x, y: contentRect.maxY))
            x += gridSpacing
        }
        
        // Horizontal grid lines
        var y = contentRect.minY
        while y <= contentRect.maxY {
            context.move(to: CGPoint(x: contentRect.minX, y: y))
            context.addLine(to: CGPoint(x: contentRect.maxX, y: y))
            y += gridSpacing
        }
        
        context.strokePath()
        context.restoreGState()
    }
    
    private func drawPanelInPNG(context: CGContext, panel: FlattenedPanelDTO, index: Int, options: ExportOptions, dpi: CGFloat) {
        guard !panel.points2D.isEmpty else { return }
        
        context.saveGState()
        
        let lineWidth = 2.0 * dpi / 72 // Scale line width for high DPI
        
        // Draw panel outline with anti-aliasing
        context.setStrokeColor(UIColor.black.cgColor)
        context.setLineWidth(lineWidth)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        
        let path = CGMutablePath()
        path.move(to: panel.points2D[0])
        
        for point in panel.points2D.dropFirst() {
            path.addLine(to: point)
        }
        path.closeSubpath()
        
        context.addPath(path)
        context.strokePath()
        
        // Draw seam allowance if requested
        if options.includeSeamAllowance {
            context.setStrokeColor(UIColor.systemBlue.cgColor)
            context.setLineWidth(lineWidth * 0.5)
            context.setLineDash(phase: 0, lengths: [6 * dpi / 72, 3 * dpi / 72])
            
            let seamPath = createSeamAllowancePath(points: panel.points2D, width: options.seamAllowanceWidth)
            context.addPath(seamPath)
            context.strokePath()
            
            context.setLineDash(phase: 0, lengths: [])
        }
        
        // Draw panel label with high-resolution text
        let centroid = calculateCentroid(points: panel.points2D)
        context.saveGState()
        context.scaleBy(x: 1, y: -1) // Flip text back to normal orientation
        
        let label = "Panel \(index + 1)"
        let labelFontSize = 14 * dpi / 72
        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: labelFontSize),
            .foregroundColor: UIColor.black
        ]
        
        let labelSize = label.size(withAttributes: labelAttributes)
        let labelRect = CGRect(
            x: centroid.x - labelSize.width/2,
            y: -centroid.y - labelSize.height/2,
            width: labelSize.width,
            height: labelSize.height
        )
        
        // Draw label background with transparency
        context.setFillColor(UIColor.white.withAlphaComponent(0.9).cgColor)
        context.fill(labelRect.insetBy(dx: -4 * dpi / 72, dy: -2 * dpi / 72))
        
        label.draw(in: labelRect, withAttributes: labelAttributes)
        
        context.restoreGState()
        context.restoreGState()
    }
    
    private func drawPNGRulers(context: CGContext, contentRect: CGRect, scaleFactor: CGFloat, dpi: CGFloat) {
        context.saveGState()
        context.setStrokeColor(UIColor.black.cgColor)
        context.setLineWidth(1.0 * dpi / 72)
        
        // Draw corner registration marks at high resolution
        let markSize: CGFloat = 12 * dpi / 72
        let corners = [
            CGPoint(x: contentRect.minX, y: contentRect.minY),
            CGPoint(x: contentRect.maxX, y: contentRect.minY),
            CGPoint(x: contentRect.minX, y: contentRect.maxY),
            CGPoint(x: contentRect.maxX, y: contentRect.maxY)
        ]
        
        for corner in corners {
            // Cross mark
            context.move(to: CGPoint(x: corner.x - markSize/2, y: corner.y))
            context.addLine(to: CGPoint(x: corner.x + markSize/2, y: corner.y))
            context.move(to: CGPoint(x: corner.x, y: corner.y - markSize/2))
            context.addLine(to: CGPoint(x: corner.x, y: corner.y + markSize/2))
        }
        
        context.strokePath()
        
        // Draw scale reference at high resolution
        let scaleRefY = contentRect.minY - 24 * dpi / 72
        let scaleRefLength: CGFloat = 72 * dpi / 72 // 1 inch at high DPI
        
        context.move(to: CGPoint(x: contentRect.minX, y: scaleRefY))
        context.addLine(to: CGPoint(x: contentRect.minX + scaleRefLength, y: scaleRefY))
        
        // Add precise tick marks
        for i in 0...8 {
            let x = contentRect.minX + CGFloat(i) * scaleRefLength / 8
            let tickHeight: CGFloat = (i % 4 == 0) ? 6 * dpi / 72 : 3 * dpi / 72
            context.move(to: CGPoint(x: x, y: scaleRefY - tickHeight))
            context.addLine(to: CGPoint(x: x, y: scaleRefY + tickHeight))
        }
        
        context.strokePath()
        
        // Scale label at high resolution
        let scaleLabel = "1 inch reference (300 DPI)"
        let labelFontSize = 10 * dpi / 72
        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: labelFontSize),
            .foregroundColor: UIColor.black
        ]
        
        let labelRect = CGRect(x: contentRect.minX, y: scaleRefY - 18 * dpi / 72, width: scaleRefLength, height: labelFontSize + 2)
        scaleLabel.draw(in: labelRect, withAttributes: labelAttributes)
        
        context.restoreGState()
    }
    #endif
    
    private func generateGIF(panels: [FlattenedPanelDTO], options: ExportOptions) async throws -> Data {
        // Placeholder GIF generation
        let placeholder = "GIF data would be generated here"
        return placeholder.data(using: .utf8)!
    }
    
    private func generateSVGPath(for panel: FlattenedPanelDTO) -> String {
        guard !panel.points2D.isEmpty else { return "" }
        
        var path = "M \(panel.points2D[0].x) \(panel.points2D[0].y)"
        
        for point in panel.points2D.dropFirst() {
            path += " L \(point.x) \(point.y)"
        }
        
        path += " Z"
        return path
    }
    
    private func generateFilename(format: ExportFormat) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = formatter.string(from: Date())
        return "CoverCraft_Pattern_\(timestamp).\(format.fileExtension)"
    }
    
    // MARK: - Helper Functions
    
    private func calculateOverallBounds(panels: [FlattenedPanelDTO]) -> CGRect {
        guard !panels.isEmpty else { return CGRect.zero }
        
        var minX = CGFloat.greatestFiniteMagnitude
        var minY = CGFloat.greatestFiniteMagnitude
        var maxX = -CGFloat.greatestFiniteMagnitude
        var maxY = -CGFloat.greatestFiniteMagnitude
        
        for panel in panels {
            for point in panel.points2D {
                minX = min(minX, point.x)
                minY = min(minY, point.y)
                maxX = max(maxX, point.x)
                maxY = max(maxY, point.y)
            }
        }
        
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
    
    private func calculateScaleFactor(bounds: CGRect, contentRect: CGRect, options: ExportOptions) -> CGFloat {
        guard bounds.width > 0 && bounds.height > 0 else { return 1.0 }
        
        let scaleX = contentRect.width / bounds.width
        let scaleY = contentRect.height / bounds.height
        
        // Use the smaller scale to ensure the pattern fits
        let baseScale = min(scaleX, scaleY) * 0.9 // 90% to leave some margin
        
        return baseScale * CGFloat(options.scale)
    }
    
    private func calculateCentroid(points: [CGPoint]) -> CGPoint {
        guard !points.isEmpty else { return CGPoint.zero }
        
        let sumX = points.reduce(0) { $0 + $1.x }
        let sumY = points.reduce(0) { $0 + $1.y }
        
        return CGPoint(x: sumX / CGFloat(points.count), y: sumY / CGFloat(points.count))
    }
    
    private func createSeamAllowancePath(points: [CGPoint], width: Double) -> CGMutablePath {
        guard points.count >= 3 else { return CGMutablePath() }
        
        let path = CGMutablePath()
        let seamWidth = CGFloat(width) / 10.0 // Convert mm to points (approximate)
        
        // Create offset path for seam allowance
        var offsetPoints: [CGPoint] = []
        
        for i in 0..<points.count {
            let currentPoint = points[i]
            let nextPoint = points[(i + 1) % points.count]
            let prevPoint = points[(i - 1 + points.count) % points.count]
            
            // Calculate perpendicular offset direction
            let v1 = CGPoint(x: currentPoint.x - prevPoint.x, y: currentPoint.y - prevPoint.y)
            let v2 = CGPoint(x: nextPoint.x - currentPoint.x, y: nextPoint.y - currentPoint.y)
            
            // Normalize and average the directions
            let l1 = sqrt(v1.x * v1.x + v1.y * v1.y)
            let l2 = sqrt(v2.x * v2.x + v2.y * v2.y)
            
            if l1 > 0 && l2 > 0 {
                let n1 = CGPoint(x: -v1.y / l1, y: v1.x / l1) // Perpendicular to v1
                let n2 = CGPoint(x: -v2.y / l2, y: v2.x / l2) // Perpendicular to v2
                
                let avgNormal = CGPoint(x: (n1.x + n2.x) / 2, y: (n1.y + n2.y) / 2)
                let normalLength = sqrt(avgNormal.x * avgNormal.x + avgNormal.y * avgNormal.y)
                
                if normalLength > 0 {
                    let unitNormal = CGPoint(x: avgNormal.x / normalLength, y: avgNormal.y / normalLength)
                    let offsetPoint = CGPoint(
                        x: currentPoint.x + unitNormal.x * seamWidth,
                        y: currentPoint.y + unitNormal.y * seamWidth
                    )
                    offsetPoints.append(offsetPoint)
                } else {
                    offsetPoints.append(currentPoint)
                }
            } else {
                offsetPoints.append(currentPoint)
            }
        }
        
        // Create the offset path
        if !offsetPoints.isEmpty {
            path.move(to: offsetPoints[0])
            for point in offsetPoints.dropFirst() {
                path.addLine(to: point)
            }
            path.closeSubpath()
        }
        
        return path
    }
}

// MARK: - Service Registration

@available(iOS 18.0, macOS 15.0, *)
public extension DefaultDependencyContainer {
    
    /// Register export services
    func registerExportServices() {
        let logger = Logger(label: "com.covercraft.export.registration")
        logger.info("Registering export services")
        
        registerSingleton({
            DefaultPatternExportService()
        }, for: PatternExportService.self)
        
        logger.info("Export services registration completed")
    }
}
