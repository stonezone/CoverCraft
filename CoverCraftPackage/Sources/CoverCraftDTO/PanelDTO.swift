// Version: 1.0.0
// CoverCraft DTO Module - Panel Data Transfer Object

import Foundation
import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

/// Immutable data transfer object representing a cover panel
/// 
/// This DTO is designed for stable serialization and transfer between modules.
/// Breaking changes require a version bump and migration path.
@available(iOS 18.0, macOS 15.0, *)
public struct PanelDTO: Sendable, Codable, Equatable, Identifiable {
    
    // MARK: - Properties
    
    /// Unique identifier for this panel
    public let id: UUID
    
    /// Indices of vertices that belong to this panel
    public let vertexIndices: Set<Int>
    
    /// Triangle indices that make up this panel
    public let triangleIndices: [Int]
    
    /// Display color for this panel
    public let color: ColorDTO
    
    /// Version of the panel data format
    public let version: String
    
    /// Timestamp when this panel was created
    public let createdAt: Date
    
    // MARK: - Initialization
    
    /// Creates a new panel DTO
    /// - Parameters:
    ///   - vertexIndices: Set of vertex indices belonging to this panel
    ///   - triangleIndices: Triangle indices that make up this panel
    ///   - color: Display color for this panel
    ///   - id: Unique identifier (defaults to new UUID)
    ///   - createdAt: Creation timestamp (defaults to now)
    public init(
        vertexIndices: Set<Int>,
        triangleIndices: [Int],
        color: ColorDTO,
        id: UUID = UUID(),
        createdAt: Date = Date()
    ) {
        self.id = id
        self.vertexIndices = vertexIndices
        self.triangleIndices = triangleIndices
        self.color = color
        self.version = "1.0.0"
        self.createdAt = createdAt
    }
    
    // MARK: - Computed Properties
    
    /// Whether this panel is valid (has vertices and triangles)
    public var isValid: Bool {
        !vertexIndices.isEmpty && 
        !triangleIndices.isEmpty &&
        triangleIndices.count % 3 == 0
    }
    
    /// Number of triangles in this panel
    public var triangleCount: Int {
        triangleIndices.count / 3
    }
}

/// Color data transfer object for stable serialization
@available(iOS 18.0, macOS 15.0, *)
public struct ColorDTO: Sendable, Codable, Equatable {
    
    // MARK: - Properties
    
    /// Red component (0.0 to 1.0)
    public let red: Double
    
    /// Green component (0.0 to 1.0) 
    public let green: Double
    
    /// Blue component (0.0 to 1.0)
    public let blue: Double
    
    /// Alpha component (0.0 to 1.0)
    public let alpha: Double
    
    // MARK: - Initialization
    
    /// Creates a new color DTO
    /// - Parameters:
    ///   - red: Red component (0.0 to 1.0)
    ///   - green: Green component (0.0 to 1.0)
    ///   - blue: Blue component (0.0 to 1.0)
    ///   - alpha: Alpha component (0.0 to 1.0, defaults to 1.0)
    public init(red: Double, green: Double, blue: Double, alpha: Double = 1.0) {
        self.red = max(0.0, min(1.0, red))
        self.green = max(0.0, min(1.0, green))
        self.blue = max(0.0, min(1.0, blue))
        self.alpha = max(0.0, min(1.0, alpha))
    }
    
    // MARK: - Predefined Colors
    
    public static let red = ColorDTO(red: 1.0, green: 0.0, blue: 0.0)
    public static let green = ColorDTO(red: 0.0, green: 1.0, blue: 0.0)
    public static let blue = ColorDTO(red: 0.0, green: 0.0, blue: 1.0)
    public static let yellow = ColorDTO(red: 1.0, green: 1.0, blue: 0.0)
    public static let orange = ColorDTO(red: 1.0, green: 0.5, blue: 0.0)
    public static let purple = ColorDTO(red: 0.5, green: 0.0, blue: 0.5)
    public static let cyan = ColorDTO(red: 0.0, green: 1.0, blue: 1.0)
    public static let magenta = ColorDTO(red: 1.0, green: 0.0, blue: 1.0)
}

// MARK: - SwiftUI Integration

@available(iOS 18.0, macOS 15.0, *)
public extension ColorDTO {
    
    /// Convert to SwiftUI Color
    @available(iOS 18.0, macOS 15.0, *)
    var swiftUIColor: Color {
        Color(red: red, green: green, blue: blue, opacity: alpha)
    }
    
    /// Create ColorDTO from SwiftUI Color
    /// - Parameter color: SwiftUI Color to convert
    /// - Returns: ColorDTO representation
    @available(iOS 18.0, macOS 15.0, *)
    static func from(swiftUIColor color: Color) -> ColorDTO {
        // Note: This is a simplified conversion
        // In practice, you might need more sophisticated color extraction
        #if canImport(UIKit)
        let uiColor = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        return ColorDTO(
            red: Double(red),
            green: Double(green),
            blue: Double(blue),
            alpha: Double(alpha)
        )
        #else
        // Fallback for platforms without UIKit
        return ColorDTO(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
        #endif
    }
}