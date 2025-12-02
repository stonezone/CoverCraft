// MeshProcessingOptions.swift
// CoverCraft DTO Module - Mesh Processing Configuration

import Foundation

/// Configuration options for mesh cleanup and processing
@available(iOS 18.0, macOS 15.0, *)
public struct MeshProcessingOptions: Sendable, Codable, Equatable {

    // MARK: - Hole Filling

    /// Whether to automatically fill small holes in the mesh
    public var enableHoleFilling: Bool

    /// Maximum number of edges in a hole to auto-fill (larger holes are left alone)
    /// Range: 3-50, default 12
    public var maxHoleEdges: Int

    // MARK: - Plane Cropping

    /// Whether to crop geometry below a horizontal plane (removes floor)
    public var enablePlaneCropping: Bool

    /// Height offset from mesh minimum for the cutting plane (in mesh units)
    /// 0.0 = at the very bottom, positive values move the plane up
    /// Range: 0.0-1.0 (as fraction of mesh height), default 0.05 (5%)
    public var cropPlaneHeightFraction: Float

    /// Which direction to crop: .below removes floor, .above removes ceiling
    public var cropDirection: CropDirection

    // MARK: - Connected Components

    /// Whether to isolate the largest connected component (removes disconnected fragments)
    public var enableComponentIsolation: Bool

    /// Minimum triangle count for a component to be kept (smaller ones are removed)
    /// Range: 1-1000, default 100
    public var minComponentTriangles: Int

    // MARK: - Initialization

    public init(
        enableHoleFilling: Bool = false,
        maxHoleEdges: Int = 12,
        enablePlaneCropping: Bool = false,
        cropPlaneHeightFraction: Float = 0.05,
        cropDirection: CropDirection = .below,
        enableComponentIsolation: Bool = false,
        minComponentTriangles: Int = 100
    ) {
        self.enableHoleFilling = enableHoleFilling
        self.maxHoleEdges = maxHoleEdges
        self.enablePlaneCropping = enablePlaneCropping
        self.cropPlaneHeightFraction = cropPlaneHeightFraction
        self.cropDirection = cropDirection
        self.enableComponentIsolation = enableComponentIsolation
        self.minComponentTriangles = minComponentTriangles
    }

    /// Default options with all processing disabled
    public static func disabled() -> MeshProcessingOptions {
        MeshProcessingOptions()
    }

    /// Recommended options for typical LiDAR scans
    public static func recommended() -> MeshProcessingOptions {
        MeshProcessingOptions(
            enableHoleFilling: true,
            maxHoleEdges: 12,
            enablePlaneCropping: true,
            cropPlaneHeightFraction: 0.05,
            cropDirection: .below,
            enableComponentIsolation: true,
            minComponentTriangles: 100
        )
    }
}

/// Direction for plane-based cropping
public enum CropDirection: String, Sendable, Codable, CaseIterable {
    case below = "Below (Remove Floor)"
    case above = "Above (Remove Ceiling)"

    public var displayName: String { rawValue }
}

/// Result of mesh processing operation
@available(iOS 18.0, macOS 15.0, *)
public struct MeshProcessingResult: Sendable {
    /// The processed mesh
    public let mesh: MeshDTO

    /// Number of holes that were filled
    public let holesFilled: Int

    /// Number of triangles removed by plane cropping
    public let trianglesCropped: Int

    /// Number of disconnected components removed
    public let componentsRemoved: Int

    /// Total triangles before processing
    public let originalTriangleCount: Int

    /// Total triangles after processing
    public let finalTriangleCount: Int

    public init(
        mesh: MeshDTO,
        holesFilled: Int = 0,
        trianglesCropped: Int = 0,
        componentsRemoved: Int = 0,
        originalTriangleCount: Int = 0,
        finalTriangleCount: Int = 0
    ) {
        self.mesh = mesh
        self.holesFilled = holesFilled
        self.trianglesCropped = trianglesCropped
        self.componentsRemoved = componentsRemoved
        self.originalTriangleCount = originalTriangleCount
        self.finalTriangleCount = finalTriangleCount
    }

    /// Summary string describing what was done
    public var summary: String {
        var parts: [String] = []
        if holesFilled > 0 {
            parts.append("\(holesFilled) hole\(holesFilled == 1 ? "" : "s") filled")
        }
        if trianglesCropped > 0 {
            parts.append("\(trianglesCropped) triangles cropped")
        }
        if componentsRemoved > 0 {
            parts.append("\(componentsRemoved) fragment\(componentsRemoved == 1 ? "" : "s") removed")
        }
        if parts.isEmpty {
            return "No changes made"
        }
        return parts.joined(separator: ", ")
    }
}
