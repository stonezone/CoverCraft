// MeshProcessingOptions.swift
// CoverCraft DTO Module - Mesh Processing Configuration

import Foundation
import simd

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

    // MARK: - Bounds Cropping

    /// Whether to crop geometry outside a normalized axis-aligned bounds box
    public var enableBoundsCropping: Bool

    /// Normalized crop bounds mapped over the mesh bounding box
    public var cropBounds: NormalizedCropBounds

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
        enableBoundsCropping: Bool = false,
        cropBounds: NormalizedCropBounds = .full,
        enableComponentIsolation: Bool = false,
        minComponentTriangles: Int = 100
    ) {
        self.enableHoleFilling = enableHoleFilling
        self.maxHoleEdges = maxHoleEdges
        self.enablePlaneCropping = enablePlaneCropping
        self.cropPlaneHeightFraction = cropPlaneHeightFraction
        self.cropDirection = cropDirection
        self.enableBoundsCropping = enableBoundsCropping
        self.cropBounds = cropBounds.normalized
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
            enableBoundsCropping: false,
            enableComponentIsolation: true,
            minComponentTriangles: 100
        )
    }
}

/// Normalized axis-aligned crop box for mesh isolation.
///
/// Values are fractions across the mesh bounding box. A full range keeps all geometry.
@available(iOS 18.0, macOS 15.0, *)
public struct NormalizedCropBounds: Sendable, Codable, Equatable {
    public var minX: Float
    public var maxX: Float
    public var minY: Float
    public var maxY: Float
    public var minZ: Float
    public var maxZ: Float

    public init(
        minX: Float = 0,
        maxX: Float = 1,
        minY: Float = 0,
        maxY: Float = 1,
        minZ: Float = 0,
        maxZ: Float = 1
    ) {
        let clampedMinX = Self.clamp(minX)
        let clampedMaxX = Self.clamp(maxX)
        let clampedMinY = Self.clamp(minY)
        let clampedMaxY = Self.clamp(maxY)
        let clampedMinZ = Self.clamp(minZ)
        let clampedMaxZ = Self.clamp(maxZ)

        self.minX = min(clampedMinX, clampedMaxX)
        self.maxX = max(clampedMinX, clampedMaxX)
        self.minY = min(clampedMinY, clampedMaxY)
        self.maxY = max(clampedMinY, clampedMaxY)
        self.minZ = min(clampedMinZ, clampedMaxZ)
        self.maxZ = max(clampedMinZ, clampedMaxZ)
    }

    public static let full = NormalizedCropBounds()

    public var normalized: NormalizedCropBounds {
        NormalizedCropBounds(
            minX: minX,
            maxX: maxX,
            minY: minY,
            maxY: maxY,
            minZ: minZ,
            maxZ: maxZ
        )
    }

    public var isFullRange: Bool {
        minX == 0 && maxX == 1 &&
        minY == 0 && maxY == 1 &&
        minZ == 0 && maxZ == 1
    }

    func contains(
        _ point: SIMD3<Float>,
        in bounds: (min: SIMD3<Float>, max: SIMD3<Float>)
    ) -> Bool {
        let normalizedPoint = normalizedPoint(point, in: bounds)
        return normalizedPoint.x >= minX && normalizedPoint.x <= maxX &&
        normalizedPoint.y >= minY && normalizedPoint.y <= maxY &&
        normalizedPoint.z >= minZ && normalizedPoint.z <= maxZ
    }

    private func normalizedPoint(
        _ point: SIMD3<Float>,
        in bounds: (min: SIMD3<Float>, max: SIMD3<Float>)
    ) -> SIMD3<Float> {
        let size = bounds.max - bounds.min
        return SIMD3<Float>(
            Self.normalize(point.x, origin: bounds.min.x, size: size.x),
            Self.normalize(point.y, origin: bounds.min.y, size: size.y),
            Self.normalize(point.z, origin: bounds.min.z, size: size.z)
        )
    }

    private static func clamp(_ value: Float) -> Float {
        min(max(value, 0), 1)
    }

    private static func normalize(_ value: Float, origin: Float, size: Float) -> Float {
        guard abs(size) > .ulpOfOne else { return 0.5 }
        return clamp((value - origin) / size)
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

    /// Number of triangles removed by bounds cropping
    public let boundsCroppedTriangles: Int

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
        boundsCroppedTriangles: Int = 0,
        componentsRemoved: Int = 0,
        originalTriangleCount: Int = 0,
        finalTriangleCount: Int = 0
    ) {
        self.mesh = mesh
        self.holesFilled = holesFilled
        self.trianglesCropped = trianglesCropped
        self.boundsCroppedTriangles = boundsCroppedTriangles
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
        if boundsCroppedTriangles > 0 {
            parts.append("\(boundsCroppedTriangles) outside-trim triangle\(boundsCroppedTriangles == 1 ? "" : "s") removed")
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
