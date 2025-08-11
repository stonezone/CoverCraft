import Foundation
#if canImport(UIKit)
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif
#endif

/// Represents a segmented panel of the mesh
public struct Panel: Identifiable, Sendable {
    public let id = UUID()
    
    /// Indices of vertices that belong to this panel
    public var vertexIndices: Set<Int>
    
    /// Triangle indices for this panel
    public var triangleIndices: [Int]
    
    /// Color for visualization
    #if canImport(UIKit)
    public var color: UIColor
    #elseif canImport(AppKit)
    public var color: NSColor
    #else
    public var color: String // Fallback to color name
    #endif
    
    #if canImport(UIKit)
    public init(vertexIndices: Set<Int>, triangleIndices: [Int], color: UIColor)
    #elseif canImport(AppKit)
    public init(vertexIndices: Set<Int>, triangleIndices: [Int], color: NSColor)
    #else
    public init(vertexIndices: Set<Int>, triangleIndices: [Int], color: String)
    #endif {
        self.vertexIndices = vertexIndices
        self.triangleIndices = triangleIndices
        self.color = color
    }
    
    /// Check if panel is valid
    public var isValid: Bool {
        !vertexIndices.isEmpty && !triangleIndices.isEmpty
    }
}

