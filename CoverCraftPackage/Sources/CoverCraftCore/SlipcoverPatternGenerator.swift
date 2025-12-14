import Foundation
import CoreGraphics
import simd
import CoverCraftDTO

@available(iOS 18.0, macOS 15.0, *)
public enum SlipcoverPatternGenerationError: Error, LocalizedError {
    case invalidMeshBounds
    case degenerateDimensions

    public var errorDescription: String? {
        switch self {
        case .invalidMeshBounds:
            return "Could not determine mesh bounds for slipcover generation"
        case .degenerateDimensions:
            return "Mesh bounds are degenerate; cannot generate a pattern"
        }
    }
}

/// Generates a simple bottom-open slipcover pattern derived from the mesh bounding box.
///
/// This generator is intended as a robust "fallback" pattern type that works even when
/// panel segmentation + LSCM flattening are unstable.
@available(iOS 18.0, macOS 15.0, *)
public struct SlipcoverPatternGenerator: Sendable {
    public init() {}

    /// Generate flattened (2D) panels in millimeters.
    ///
    /// - Parameters:
    ///   - mesh: Mesh in real-world meters (after calibration scaling).
    ///   - options: Slipcover options (ease in millimeters, panelization, etc).
    /// - Returns: Flattened panels ready for export.
    public func generate(from mesh: MeshDTO, options: SlipcoverPatternOptions) throws -> [FlattenedPanelDTO] {
        guard let bounds = mesh.boundingBox() else {
            throw SlipcoverPatternGenerationError.invalidMeshBounds
        }

        let sizeMeters = bounds.max - bounds.min
        guard sizeMeters.x.isFinite, sizeMeters.y.isFinite, sizeMeters.z.isFinite else {
            throw SlipcoverPatternGenerationError.invalidMeshBounds
        }

        let easeMm = options.easeMillimeters

        let widthMm = Double(sizeMeters.x) * 1000.0 + 2.0 * easeMm
        let depthMm = Double(sizeMeters.z) * 1000.0 + 2.0 * easeMm
        let heightMm = Double(sizeMeters.y) * 1000.0 + easeMm

        return try generatePanels(widthMm: widthMm, depthMm: depthMm, heightMm: heightMm, options: options)
    }

    /// Generate a slipcover pattern directly from object dimensions (millimeters).
    ///
    /// - Parameters:
    ///   - widthMillimeters: Object width (X) in millimeters.
    ///   - depthMillimeters: Object depth (Z) in millimeters.
    ///   - heightMillimeters: Object height (Y) in millimeters.
    ///   - options: Slipcover options (ease in millimeters, panelization, etc).
    public func generate(
        widthMillimeters: Double,
        depthMillimeters: Double,
        heightMillimeters: Double,
        options: SlipcoverPatternOptions
    ) throws -> [FlattenedPanelDTO] {
        let easeMm = options.easeMillimeters
        let widthMm = widthMillimeters + 2.0 * easeMm
        let depthMm = depthMillimeters + 2.0 * easeMm
        let heightMm = heightMillimeters + easeMm

        return try generatePanels(widthMm: widthMm, depthMm: depthMm, heightMm: heightMm, options: options)
    }

    private func generatePanels(
        widthMm: Double,
        depthMm: Double,
        heightMm: Double,
        options: SlipcoverPatternOptions
    ) throws -> [FlattenedPanelDTO] {
        guard widthMm > 1, depthMm > 1, heightMm > 1 else {
            throw SlipcoverPatternGenerationError.degenerateDimensions
        }

        let segmentsPerSide = max(1, options.segmentsPerSide)
        let verticalSegments = max(1, options.verticalSegments)
        let seamWidthMm = options.seamAllowanceMillimeters

        let colors: [ColorDTO] = [.red, .green, .blue, .yellow, .orange, .purple, .cyan, .magenta]
        var colorIndex = 0

        func nextColor() -> ColorDTO {
            defer { colorIndex += 1 }
            return colors[colorIndex % colors.count]
        }

        func makeQuad(width: Double, height: Double, color: ColorDTO) -> FlattenedPanelDTO {
            let points: [CGPoint] = [
                CGPoint(x: 0, y: 0),
                CGPoint(x: width, y: 0),
                CGPoint(x: width, y: height),
                CGPoint(x: 0, y: height)
            ]

            let cutEdges: [EdgeDTO] = [
                EdgeDTO(startIndex: 0, endIndex: 1, type: .cutLine),
                EdgeDTO(startIndex: 1, endIndex: 2, type: .cutLine),
                EdgeDTO(startIndex: 2, endIndex: 3, type: .cutLine),
                EdgeDTO(startIndex: 3, endIndex: 0, type: .cutLine)
            ]

            let seamEdges: [EdgeDTO] = [
                EdgeDTO(startIndex: 0, endIndex: 1, type: .seamAllowance, original3DLength: seamWidthMm),
                EdgeDTO(startIndex: 1, endIndex: 2, type: .seamAllowance, original3DLength: seamWidthMm),
                EdgeDTO(startIndex: 2, endIndex: 3, type: .seamAllowance, original3DLength: seamWidthMm),
                EdgeDTO(startIndex: 3, endIndex: 0, type: .seamAllowance, original3DLength: seamWidthMm)
            ]

            return FlattenedPanelDTO(
                points2D: points,
                edges: cutEdges + seamEdges,
                color: color,
                scaleUnitsPerMeter: 1000.0
            )
        }

        func makeTriangles(fromQuadWidth width: Double, height: Double, color: ColorDTO) -> [FlattenedPanelDTO] {
            let pointsA: [CGPoint] = [
                CGPoint(x: 0, y: 0),
                CGPoint(x: width, y: 0),
                CGPoint(x: width, y: height)
            ]
            let pointsB: [CGPoint] = [
                CGPoint(x: 0, y: 0),
                CGPoint(x: width, y: height),
                CGPoint(x: 0, y: height)
            ]

            func triangle(points: [CGPoint]) -> FlattenedPanelDTO {
                let cutEdges: [EdgeDTO] = [
                    EdgeDTO(startIndex: 0, endIndex: 1, type: .cutLine),
                    EdgeDTO(startIndex: 1, endIndex: 2, type: .cutLine),
                    EdgeDTO(startIndex: 2, endIndex: 0, type: .cutLine)
                ]
                let seamEdges: [EdgeDTO] = [
                    EdgeDTO(startIndex: 0, endIndex: 1, type: .seamAllowance, original3DLength: seamWidthMm),
                    EdgeDTO(startIndex: 1, endIndex: 2, type: .seamAllowance, original3DLength: seamWidthMm),
                    EdgeDTO(startIndex: 2, endIndex: 0, type: .seamAllowance, original3DLength: seamWidthMm)
                ]

                return FlattenedPanelDTO(
                    points2D: points,
                    edges: cutEdges + seamEdges,
                    color: color,
                    scaleUnitsPerMeter: 1000.0
                )
            }

            return [triangle(points: pointsA), triangle(points: pointsB)]
        }

        func emitPanel(width: Double, height: Double) -> [FlattenedPanelDTO] {
            let color = nextColor()
            switch options.panelization {
            case .quads:
                return [makeQuad(width: width, height: height, color: color)]
            case .triangles:
                return makeTriangles(fromQuadWidth: width, height: height, color: color)
            }
        }

        // Side panels: 4 sides, subdivided per-side and vertically.
        let sideWidths: [Double] = [widthMm, depthMm, widthMm, depthMm]
        let segmentHeights = (0..<verticalSegments).map { _ in heightMm / Double(verticalSegments) }

        var panels: [FlattenedPanelDTO] = []

        for sideWidth in sideWidths {
            let segmentWidth = sideWidth / Double(segmentsPerSide)
            for _ in 0..<segmentsPerSide {
                for segmentHeight in segmentHeights {
                    panels.append(contentsOf: emitPanel(width: segmentWidth, height: segmentHeight))
                }
            }
        }

        // Optional top panel (water protection)
        if options.topStyle == .closed {
            panels.append(contentsOf: emitPanel(width: widthMm, height: depthMm))
        }

        return panels
    }
}
