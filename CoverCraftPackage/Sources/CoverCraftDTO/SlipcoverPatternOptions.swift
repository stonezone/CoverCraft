import Foundation

@available(iOS 18.0, macOS 15.0, *)
public enum SlipcoverTopStyle: String, Sendable, Codable, CaseIterable {
    case closed = "Closed Top (Water Protection)"
    case open = "Open Top"
}

@available(iOS 18.0, macOS 15.0, *)
public enum SlipcoverPanelization: String, Sendable, Codable, CaseIterable {
    case quads = "Quads"
    case triangles = "Triangles"
}

/// Options for generating a simple "bottom-open" slipcover pattern.
///
/// Units:
/// - `easeMillimeters` is in millimeters and is applied to X/Z extents.
@available(iOS 18.0, macOS 15.0, *)
public struct SlipcoverPatternOptions: Sendable, Codable, Equatable {
    public var topStyle: SlipcoverTopStyle
    public var easeMillimeters: Double
    public var segmentsPerSide: Int
    public var verticalSegments: Int
    public var panelization: SlipcoverPanelization

    public init(
        topStyle: SlipcoverTopStyle = .closed,
        easeMillimeters: Double = 20,
        segmentsPerSide: Int = 1,
        verticalSegments: Int = 1,
        panelization: SlipcoverPanelization = .quads
    ) {
        self.topStyle = topStyle
        self.easeMillimeters = max(0, easeMillimeters)
        self.segmentsPerSide = max(1, segmentsPerSide)
        self.verticalSegments = max(1, verticalSegments)
        self.panelization = panelization
    }
}

