// Version: 1.0.0

import SwiftUI
import simd
import CoverCraftDTO

@available(iOS 18.0, macOS 15.0, *)
@MainActor
public struct MeshMeasurementSummaryView: View {
    private let mesh: MeshDTO
    private let boundaryInfo: MeshBoundaryInfo?

    public init(mesh: MeshDTO, boundaryInfo: MeshBoundaryInfo? = nil) {
        self.mesh = mesh
        self.boundaryInfo = boundaryInfo ?? (mesh.isValid ? mesh.analyzeBoundaries() : nil)
    }

    public var body: some View {
        CoverCraftCard(tone: mesh.isValid ? .neutral : .warning) {
            CoverCraftSectionHeading(
                step: "Mesh",
                title: "Measurement Summary",
                subtitle: "Geometry counts and bounding-box extents from the current mesh.",
                statusTitle: mesh.isValid ? "Valid" : "Invalid",
                statusImage: mesh.isValid ? "checkmark.seal.fill" : "exclamationmark.triangle.fill",
                tone: mesh.isValid ? .neutral : .warning
            )

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ],
                spacing: 12
            ) {
                CoverCraftMetricTile(
                    title: "Vertices",
                    value: mesh.vertices.count.formatted(),
                    subtitle: "Captured points",
                    systemImage: "point.3.connected.trianglepath.dotted",
                    tone: .accent
                )

                CoverCraftMetricTile(
                    title: "Triangles",
                    value: mesh.triangleCount.formatted(),
                    subtitle: "Surface faces",
                    systemImage: "triangle",
                    tone: .accent
                )

                if let dimensions {
                    CoverCraftMetricTile(
                        title: "Max length",
                        value: formatMeasurement(dimensions.maxLength),
                        subtitle: "Longest bounding-box side",
                        systemImage: "ruler",
                        tone: .neutral
                    )

                    CoverCraftMetricTile(
                        title: "Width",
                        value: formatMeasurement(dimensions.width),
                        subtitle: "X-axis extent",
                        systemImage: "arrow.left.and.right",
                        tone: .neutral
                    )

                    CoverCraftMetricTile(
                        title: "Height",
                        value: formatMeasurement(dimensions.height),
                        subtitle: "Y-axis extent",
                        systemImage: "arrow.up.and.down",
                        tone: .neutral
                    )

                    CoverCraftMetricTile(
                        title: "Depth",
                        value: formatMeasurement(dimensions.depth),
                        subtitle: "Z-axis extent",
                        systemImage: "arrow.forward",
                        tone: .neutral
                    )
                } else {
                    CoverCraftMetricTile(
                        title: "Bounds",
                        value: "Unavailable",
                        subtitle: "Mesh has no vertices",
                        systemImage: "cube.transparent",
                        tone: .warning
                    )
                }

                if let boundaryInfo {
                    CoverCraftMetricTile(
                        title: "Validity",
                        value: mesh.isValid ? "Valid" : "Invalid",
                        subtitle: boundaryInfo.isWatertight ? "Watertight mesh" : "Open boundaries found",
                        systemImage: mesh.isValid ? "checkmark.seal.fill" : "exclamationmark.triangle.fill",
                        tone: mesh.isValid ? .success : .warning
                    )

                    CoverCraftMetricTile(
                        title: "Holes",
                        value: boundaryInfo.isWatertight ? "None" : boundaryInfo.holeCount.formatted(),
                        subtitle: boundaryInfo.isWatertight ? "No boundary edges" : "\(boundaryInfo.boundaryEdges.count.formatted()) boundary edges",
                        systemImage: boundaryInfo.isWatertight ? "checkmark.circle" : "circle.dashed",
                        tone: boundaryInfo.isWatertight ? .success : .warning
                    )
                } else {
                    CoverCraftMetricTile(
                        title: "Validity",
                        value: mesh.isValid ? "Valid" : "Invalid",
                        subtitle: mesh.isValid ? "Boundary analysis unavailable" : "Check mesh indices",
                        systemImage: mesh.isValid ? "checkmark.seal.fill" : "exclamationmark.triangle.fill",
                        tone: mesh.isValid ? .success : .warning
                    )
                }
            }
        }
    }

    private var dimensions: MeshDimensions? {
        guard let bounds = mesh.boundingBox() else { return nil }
        let size = bounds.max - bounds.min
        return MeshDimensions(size: size)
    }

    private func formatMeasurement(_ value: Float) -> String {
        value.formatted(.number.precision(.fractionLength(3)))
    }
}

@available(iOS 18.0, macOS 15.0, *)
private struct MeshDimensions {
    let width: Float
    let height: Float
    let depth: Float
    let maxLength: Float

    init(size: SIMD3<Float>) {
        self.width = size.x
        self.height = size.y
        self.depth = size.z
        self.maxLength = max(size.x, size.y, size.z)
    }
}
