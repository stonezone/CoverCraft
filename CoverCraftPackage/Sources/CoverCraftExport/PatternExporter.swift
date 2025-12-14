import Foundation
import PDFKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import CoverCraftDTO
import CoverCraftCore
#if canImport(UIKit)
import UIKit
typealias PlatformColor = UIColor
typealias PlatformFont = UIFont
typealias PlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit
typealias PlatformColor = NSColor
typealias PlatformFont = NSFont
typealias PlatformImage = NSImage
#endif

/// LEGACY: Actor-based pattern exporter with direct export API
///
/// Architecture Note:
/// This is a legacy implementation that provides actor-based isolation for export operations.
/// For new code, use DefaultPatternExportService which implements the PatternExportService protocol.
/// This exporter is maintained for compatibility with existing code that uses the direct exportPattern() API.
///
/// Key Differences from DefaultPatternExportService:
/// - Actor-based (provides automatic isolation)
/// - Direct export API (returns URL instead of ExportResult)
/// - Simpler rendering pipeline
/// - Does NOT implement PatternExportService protocol to avoid DI ambiguity
///
/// IMPORTANT: DXF export is NOT supported in this legacy exporter. Use DefaultPatternExportService
/// which correctly validates and rejects DXF requests until full implementation is available.
///
@available(iOS 18.0, macOS 15.0, *)
public actor PatternExporter {
    
    public init() {}
    
    public func exportPattern(_ panels: [FlattenedPanelDTO], format: ExportFormat) async throws -> URL {
        guard !panels.isEmpty else {
            throw ExportError.noPanels
        }
        
        switch format {
        case .png:
            return try await exportToPNG(panels)
        case .gif:
            return try await exportToGIF(panels)
        case .svg:
            return try await exportToSVG(panels)
        case .pdf:
            return try await exportToPDF(panels, pageSize: .a4)
        case .dxf:
            throw ExportError.unsupportedFormat
        }
    }
    
    // MARK: - PNG Export
    
    private func exportToPNG(_ panels: [FlattenedPanelDTO]) async throws -> URL {
        let layout = layoutPanels(panels, pageSize: .letter, dpi: 150)
        let size = CGSize(width: layout.pageWidth, height: layout.pageHeight)
        
        #if canImport(UIKit)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            let cgContext = context.cgContext
            
            // White background
            cgContext.setFillColor(PlatformColor.white.cgColor)
            cgContext.fill(CGRect(origin: .zero, size: size))
            
            // Draw patterns and labels
            drawPatterns(cgContext, layout: layout, includeLabels: true)
        }
        #else
        // For macOS, create CGContext manually
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        guard let cgContext = CGContext(
            data: nil,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            throw ExportError.fileCreationFailed
        }
        
        cgContext.scaleBy(x: 1.0, y: -1.0)
        cgContext.translateBy(x: 0.0, y: -size.height)
        
        // White background
        cgContext.setFillColor(PlatformColor.white.cgColor)
        cgContext.fill(CGRect(origin: .zero, size: size))
        
        // Draw patterns and labels
        drawPatterns(cgContext, layout: layout, includeLabels: true)
        
        guard let cgImage = cgContext.makeImage() else {
            throw ExportError.renderingFailed
        }
        let image = PlatformImage(cgImage: cgImage, size: size)
        #endif
        
        let url = getTemporaryURL(format: .png)
        
        #if canImport(UIKit)
        guard let data = image.pngData() else {
            throw ExportError.renderingFailed
        }
        try data.write(to: url)
        return url
        #else
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil),
              let destination = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil) else {
            throw ExportError.renderingFailed
        }
        CGImageDestinationAddImage(destination, cgImage, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw ExportError.renderingFailed
        }
        return url
        #endif
    }
    
    // MARK: - GIF Export
    
    @available(iOS 18.0, macOS 15.0, *)
    private func exportToGIF(_ panels: [FlattenedPanelDTO]) async throws -> URL {
        // GIF export only supported on iOS for now
        #if canImport(UIKit)
        // Create animated GIF showing panels one by one
        let layout = layoutPanels(panels, pageSize: .letter, dpi: 150)
        let size = CGSize(width: layout.pageWidth, height: layout.pageHeight)
        
        let url = getTemporaryURL(format: .gif)
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, "com.compuserve.gif" as CFString, panels.count + 1, nil) else {
            throw ExportError.fileCreationFailed
        }
        
        let gifProperties: [CFString: Any] = [
            kCGImagePropertyGIFDictionary: [
                kCGImagePropertyGIFLoopCount: 0,
                kCGImagePropertyGIFDelayTime: 1.0
            ]
        ]
        
        CGImageDestinationSetProperties(destination, gifProperties as CFDictionary)
        
        let renderer = UIGraphicsImageRenderer(size: size)
        
        // Frame 0: All panels
        let allPanelsImage = renderer.image { context in
            let cgContext = context.cgContext
            cgContext.setFillColor(PlatformColor.white.cgColor)
            cgContext.fill(CGRect(origin: .zero, size: size))
            drawPatterns(cgContext, layout: layout, includeLabels: true)
        }
        
        if let cgImage = allPanelsImage.cgImage {
            CGImageDestinationAddImage(destination, cgImage, gifProperties as CFDictionary)
        }
        
        // Individual panel frames
        for (index, _) in panels.enumerated() {
            let singlePanelImage = renderer.image { context in
                let cgContext = context.cgContext
                cgContext.setFillColor(PlatformColor.white.cgColor)
                cgContext.fill(CGRect(origin: .zero, size: size))
                drawSinglePanel(cgContext, layout: layout, panelIndex: index, includeLabels: true)
            }
            
            if let cgImage = singlePanelImage.cgImage {
                CGImageDestinationAddImage(destination, cgImage, gifProperties as CFDictionary)
            }
        }
        
        guard CGImageDestinationFinalize(destination) else {
            throw ExportError.renderingFailed
        }
        
        return url
        #else
        // GIF export not supported on macOS yet
        throw ExportError.unsupportedFormat
        #endif
    }
    
    // MARK: - SVG Export
    
    private func exportToSVG(_ panels: [FlattenedPanelDTO]) async throws -> URL {
        let layout = layoutPanels(panels, pageSize: PageSize.letter, dpi: 72) // SVG uses 72 DPI
        
        var svg = """
        <?xml version="1.0" encoding="UTF-8"?>
        <svg width="\(layout.pageWidth)" height="\(layout.pageHeight)" viewBox="0 0 \(layout.pageWidth) \(layout.pageHeight)" xmlns="http://www.w3.org/2000/svg">
        <defs>
          <style>
            .panel-outline { fill: none; stroke: #000; stroke-width: 1; }
            .panel-fill { fill-opacity: 0.1; stroke: #000; stroke-width: 0.5; }
            .scale-bar { fill: none; stroke: #000; stroke-width: 2; }
            .label-text { font-family: Arial, sans-serif; font-size: 12px; fill: #000; }
            .scale-text { font-family: Arial, sans-serif; font-size: 10px; fill: #000; }
          </style>
        </defs>
        
        """
        
        // Draw panels
        for (panelIndex, panelLayout) in layout.panels.enumerated() {
            let panel = panels[panelIndex]
            let color = panel.color
            
            // Convert ColorDTO to RGB hex
            let hexColor = String(format: "#%02x%02x%02x", 
                                Int(color.red * 255), 
                                Int(color.green * 255), 
                                Int(color.blue * 255))
            
            // Panel background
            svg += """
            <polygon class="panel-fill" fill="\(hexColor)" points="\(panelLayout.pathPoints)" />
            
            """
            
            // Panel outline
            svg += """
            <polygon class="panel-outline" points="\(panelLayout.pathPoints)" />
            
            """
            
            // Panel label
            svg += """
            <text class="label-text" x="\(panelLayout.labelPosition.x)" y="\(panelLayout.labelPosition.y)">Panel \(panelIndex + 1)</text>
            
            """
        }
        
        // Scale bar (10cm = 283.46 points at 72 DPI)
        let scaleBarLength: CGFloat = 283.46
        let scaleBarY = layout.pageHeight - 40
        
        svg += """
        <line class="scale-bar" x1="50" y1="\(scaleBarY)" x2="\(50 + scaleBarLength)" y2="\(scaleBarY)" />
        <text class="scale-text" x="50" y="\(scaleBarY - 10)">10 cm</text>
        
        </svg>
        """
        
        let url = getTemporaryURL(format: ExportFormat.svg)
        try svg.write(to: url, atomically: true, encoding: String.Encoding.utf8)
        return url
    }
    
    // MARK: - PDF Export
    
    private func exportToPDF(_ panels: [FlattenedPanelDTO], pageSize: PageSize) async throws -> URL {
        let layout = layoutPanels(panels, pageSize: pageSize, dpi: 72) // PDF uses 72 DPI
        let bounds = CGRect(x: 0, y: 0, width: layout.pageWidth, height: layout.pageHeight)
        
        let url = getTemporaryURL(format: .pdf)
        
        var mediaBox = bounds
        guard let context = CGContext(url as CFURL, mediaBox: &mediaBox, nil) else {
            throw ExportError.fileCreationFailed
        }
        
        context.beginPDFPage(nil as CFDictionary?)
        
        // White background
        context.setFillColor(PlatformColor.white.cgColor)
        context.fill(bounds)
        
        // Draw patterns and labels
        drawPatterns(context, layout: layout, includeLabels: true)
        
        context.endPDFPage()
        context.closePDF()
        
        return url
    }
    
    // MARK: - Layout and Drawing Helpers
    
    private struct PageLayout {
        let pageWidth: CGFloat
        let pageHeight: CGFloat
        let panels: [PanelLayout]
        
        struct PanelLayout {
            let bounds: CGRect
            let pathPoints: String
            let labelPosition: CGPoint
        }
    }
    
    private func layoutPanels(_ panels: [FlattenedPanelDTO], pageSize: PageSize, dpi: CGFloat) -> PageLayout {
        let pageSize = getPageSize(pageSize)
        let margin: CGFloat = 36 // 0.5 inch margin
        let availableWidth = pageSize.width - (2 * margin)
        let _ = pageSize.height - (2 * margin) // Available height for future use
        
        var panelLayouts: [PageLayout.PanelLayout] = []
        var currentY: CGFloat = margin
        var currentRowHeight: CGFloat = 0
        var currentX: CGFloat = margin
        
        // Simple bin packing algorithm
        for panel in panels {
            let scaledPoints = scalePointsForPrint(panel.points2D, dpi: dpi)
            let bbox = calculateBoundingBox(scaledPoints)
            
            let panelWidth = bbox.width + 20 // Add padding
            let panelHeight = bbox.height + 40 // Add padding for label
            
            // Check if we need a new row
            if currentX + panelWidth > margin + availableWidth {
                currentX = margin
                currentY += currentRowHeight + 20
                currentRowHeight = 0
            }
            
            // Position panel
            let panelBounds = CGRect(x: currentX, y: currentY, width: panelWidth, height: panelHeight)
            let offsetPoints = offsetPoints(scaledPoints, to: CGPoint(x: currentX + 10, y: currentY + 30))
            
            let pathPoints = offsetPoints.map { "\($0.x),\($0.y)" }.joined(separator: " ")
            let labelPosition = CGPoint(x: currentX + 10, y: currentY + 15)
            
            panelLayouts.append(PageLayout.PanelLayout(
                bounds: panelBounds,
                pathPoints: pathPoints,
                labelPosition: labelPosition
            ))
            
            currentX += panelWidth + 10
            currentRowHeight = max(currentRowHeight, panelHeight)
        }
        
        return PageLayout(
            pageWidth: pageSize.width,
            pageHeight: pageSize.height,
            panels: panelLayouts
        )
    }
    
    private func drawPatterns(_ context: CGContext, layout: PageLayout, includeLabels: Bool) {
        context.setLineWidth(1.0)
        context.setStrokeColor(PlatformColor.black.cgColor)
        
        for (index, panelLayout) in layout.panels.enumerated() {
            // Parse points from path string
            let pointStrings = panelLayout.pathPoints.split(separator: " ")
            var points: [CGPoint] = []
            
            for pointString in pointStrings {
                let coords = pointString.split(separator: ",")
                if coords.count == 2,
                   let x = Double(coords[0]),
                   let y = Double(coords[1]) {
                    points.append(CGPoint(x: x, y: y))
                }
            }
            
            // Draw panel outline
            if !points.isEmpty {
                context.beginPath()
                context.move(to: points[0])
                for point in points.dropFirst() {
                    context.addLine(to: point)
                }
                context.closePath()
                context.strokePath()
            }
            
            // Draw label
            if includeLabels {
                let text = "Panel \(index + 1)"
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: PlatformFont.systemFont(ofSize: 12),
                    .foregroundColor: PlatformColor.black
                ]
                
                let attributedString = NSAttributedString(string: text, attributes: attributes)
                let textBounds = attributedString.boundingRect(with: CGSize(width: 200, height: 50), options: [], context: nil)
                
                context.saveGState()
                context.translateBy(x: panelLayout.labelPosition.x, y: panelLayout.labelPosition.y + textBounds.height)
                context.scaleBy(x: 1, y: -1) // Flip coordinate system for text
                
                let line = CTLineCreateWithAttributedString(attributedString)
                CTLineDraw(line, context)
                context.restoreGState()
            }
        }
        
        // Draw scale bar (10cm)
        let scaleBarLength: CGFloat = 283.46 // 10cm at 72 DPI
        let scaleBarY = layout.pageHeight - 40
        
        context.setLineWidth(2.0)
        context.beginPath()
        context.move(to: CGPoint(x: 50, y: scaleBarY))
        context.addLine(to: CGPoint(x: 50 + scaleBarLength, y: scaleBarY))
        context.strokePath()
        
        // Scale bar label
        if includeLabels {
            let scaleText = "10 cm"
            let attributes: [NSAttributedString.Key: Any] = [
                .font: PlatformFont.systemFont(ofSize: 10),
                .foregroundColor: PlatformColor.black
            ]
            
            let attributedString = NSAttributedString(string: scaleText, attributes: attributes)
            let textBounds = attributedString.boundingRect(with: CGSize(width: 100, height: 20), options: [], context: nil)
            
            context.saveGState()
            context.translateBy(x: 50, y: scaleBarY - 10 + textBounds.height)
            context.scaleBy(x: 1, y: -1)
            
            let line = CTLineCreateWithAttributedString(attributedString)
            CTLineDraw(line, context)
            context.restoreGState()
        }
    }
    
    private func drawSinglePanel(_ context: CGContext, layout: PageLayout, panelIndex: Int, includeLabels: Bool) {
        guard panelIndex < layout.panels.count else { return }
        
        let panelLayout = layout.panels[panelIndex]
        
        // Parse and draw single panel
        let pointStrings = panelLayout.pathPoints.split(separator: " ")
        var points: [CGPoint] = []
        
        for pointString in pointStrings {
            let coords = pointString.split(separator: ",")
            if coords.count == 2,
               let x = Double(coords[0]),
               let y = Double(coords[1]) {
                points.append(CGPoint(x: x, y: y))
            }
        }
        
        context.setLineWidth(2.0)
        context.setStrokeColor(PlatformColor.red.cgColor)
        
        if !points.isEmpty {
            context.beginPath()
            context.move(to: points[0])
            for point in points.dropFirst() {
                context.addLine(to: point)
            }
            context.closePath()
            context.strokePath()
        }
        
        if includeLabels {
            let text = "Panel \(panelIndex + 1)"
            
            #if canImport(UIKit)
            let boldFont = PlatformFont.systemFont(ofSize: 14, weight: .bold)
            #else
            let boldFont = PlatformFont.boldSystemFont(ofSize: 14)
            #endif
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: boldFont,
                .foregroundColor: PlatformColor.red
            ]
            
            let attributedString = NSAttributedString(string: text, attributes: attributes)
            let textBounds = attributedString.boundingRect(with: CGSize(width: 200, height: 50), options: [], context: nil)
            
            context.saveGState()
            context.translateBy(x: panelLayout.labelPosition.x, y: panelLayout.labelPosition.y + textBounds.height)
            context.scaleBy(x: 1, y: -1)
            
            let line = CTLineCreateWithAttributedString(attributedString)
            CTLineDraw(line, context)
            context.restoreGState()
        }
    }
    
    // MARK: - Utility Functions
    
    private func scalePointsForPrint(_ points: [CGPoint], dpi: CGFloat) -> [CGPoint] {
        let scale = dpi / 72.0 // Convert to points (72 points per inch)
        return points.map { CGPoint(x: $0.x * scale, y: $0.y * scale) }
    }
    
    private func calculateBoundingBox(_ points: [CGPoint]) -> CGRect {
        guard !points.isEmpty else { return .zero }
        
        let xs = points.map { $0.x }
        let ys = points.map { $0.y }
        
        let minX = xs.min() ?? 0
        let maxX = xs.max() ?? 0
        let minY = ys.min() ?? 0
        let maxY = ys.max() ?? 0
        
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
    
    private func offsetPoints(_ points: [CGPoint], to origin: CGPoint) -> [CGPoint] {
        guard !points.isEmpty else { return points }
        
        let bbox = calculateBoundingBox(points)
        let offsetX = origin.x - bbox.minX
        let offsetY = origin.y - bbox.minY
        
        return points.map { CGPoint(x: $0.x + offsetX, y: $0.y + offsetY) }
    }
    
    private func getPageSize(_ pageSize: PageSize) -> CGSize {
        switch pageSize {
        case .letter:
            return CGSize(width: 612, height: 792) // 8.5" x 11" at 72 DPI
        case .a4:
            return CGSize(width: 595, height: 842) // A4 at 72 DPI
        }
    }
    
    private func getTemporaryURL(format: ExportFormat) -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = formatter.string(from: Date())
        
        let filename: String
        switch format {
        case .png:
            filename = "CoverCraft_Pattern_\(timestamp).png"
        case .gif:
            filename = "CoverCraft_Pattern_\(timestamp).gif"
        case .svg:
            filename = "CoverCraft_Pattern_\(timestamp).svg"
        case .pdf:
            filename = "CoverCraft_Pattern_\(timestamp).pdf"
        case .dxf:
            filename = "CoverCraft_Pattern_\(timestamp).dxf"
        }
        
        return FileManager.default.temporaryDirectory.appendingPathComponent(filename)
    }
    
    public enum PageSize {
        case letter, a4
    }
    
    public enum ExportError: LocalizedError {
        case noPanels
        case fileCreationFailed
        case renderingFailed
        case unsupportedFormat
        
        public var errorDescription: String? {
            switch self {
            case .noPanels:
                return "No panels available for export"
            case .fileCreationFailed:
                return "Failed to create export file"
            case .renderingFailed:
                return "Failed to render pattern"
            case .unsupportedFormat:
                return "Unsupported export format for this platform"
            }
        }
    }
}