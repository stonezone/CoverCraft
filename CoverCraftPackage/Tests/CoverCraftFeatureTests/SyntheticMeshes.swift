import Testing
import simd
@testable import CoverCraftFeature

/// Synthetic mesh generators for testing segmentation and flattening algorithms
enum SyntheticMeshes {
    
    /// Generate a unit cube mesh with proper normals
    static func cube() -> Mesh {
        // 8 vertices of a unit cube centered at origin
        let vertices: [SIMD3<Float>] = [
            // Front face (z = 0.5)
            SIMD3<Float>(-0.5, -0.5,  0.5), // 0: bottom-left-front
            SIMD3<Float>( 0.5, -0.5,  0.5), // 1: bottom-right-front
            SIMD3<Float>( 0.5,  0.5,  0.5), // 2: top-right-front
            SIMD3<Float>(-0.5,  0.5,  0.5), // 3: top-left-front
            
            // Back face (z = -0.5)
            SIMD3<Float>(-0.5, -0.5, -0.5), // 4: bottom-left-back
            SIMD3<Float>( 0.5, -0.5, -0.5), // 5: bottom-right-back
            SIMD3<Float>( 0.5,  0.5, -0.5), // 6: top-right-back
            SIMD3<Float>(-0.5,  0.5, -0.5)  // 7: top-left-back
        ]
        
        // 12 triangles (2 per face, 6 faces)
        // Counter-clockwise winding when viewed from outside
        let triangles: [Int] = [
            // Front face (z = 0.5) - normal: (0, 0, 1)
            0, 1, 2,  0, 2, 3,
            
            // Back face (z = -0.5) - normal: (0, 0, -1)
            5, 4, 7,  5, 7, 6,
            
            // Right face (x = 0.5) - normal: (1, 0, 0)
            1, 5, 6,  1, 6, 2,
            
            // Left face (x = -0.5) - normal: (-1, 0, 0)
            4, 0, 3,  4, 3, 7,
            
            // Top face (y = 0.5) - normal: (0, 1, 0)
            3, 2, 6,  3, 6, 7,
            
            // Bottom face (y = -0.5) - normal: (0, -1, 0)
            4, 5, 1,  4, 1, 0
        ]
        
        return Mesh(vertices: vertices, triangleIndices: triangles)
    }
    
    /// Generate a cylinder mesh with specified parameters
    static func cylinder(segments: Int, height: Float, radius: Float) -> Mesh {
        guard segments >= 3 else {
            // Fallback to triangle for invalid input
            return triangle()
        }
        
        var vertices: [SIMD3<Float>] = []
        var triangles: [Int] = []
        
        let halfHeight = height * 0.5
        
        // Generate vertices
        // Bottom center
        vertices.append(SIMD3<Float>(0, -halfHeight, 0)) // index 0
        
        // Top center  
        vertices.append(SIMD3<Float>(0, halfHeight, 0)) // index 1
        
        // Bottom ring vertices
        for i in 0..<segments {
            let angle = Float(i) * 2.0 * Float.pi / Float(segments)
            let x = radius * cos(angle)
            let z = radius * sin(angle)
            vertices.append(SIMD3<Float>(x, -halfHeight, z)) // indices 2...(segments+1)
        }
        
        // Top ring vertices
        for i in 0..<segments {
            let angle = Float(i) * 2.0 * Float.pi / Float(segments)
            let x = radius * cos(angle)
            let z = radius * sin(angle)
            vertices.append(SIMD3<Float>(x, halfHeight, z)) // indices (segments+2)...(2*segments+1)
        }
        
        // Generate triangles
        let bottomStart = 2
        let topStart = 2 + segments
        
        // Bottom face triangles (pointing down)
        for i in 0..<segments {
            let current = bottomStart + i
            let next = bottomStart + ((i + 1) % segments)
            
            // Triangle: center -> next -> current (clockwise from bottom)
            triangles.append(contentsOf: [0, next, current])
        }
        
        // Top face triangles (pointing up) 
        for i in 0..<segments {
            let current = topStart + i
            let next = topStart + ((i + 1) % segments)
            
            // Triangle: center -> current -> next (counter-clockwise from top)
            triangles.append(contentsOf: [1, current, next])
        }
        
        // Side face triangles
        for i in 0..<segments {
            let bottomCurrent = bottomStart + i
            let bottomNext = bottomStart + ((i + 1) % segments)
            let topCurrent = topStart + i
            let topNext = topStart + ((i + 1) % segments)
            
            // First triangle of the quad: bottom-current -> bottom-next -> top-current
            triangles.append(contentsOf: [bottomCurrent, bottomNext, topCurrent])
            
            // Second triangle of the quad: bottom-next -> top-next -> top-current
            triangles.append(contentsOf: [bottomNext, topNext, topCurrent])
        }
        
        return Mesh(vertices: vertices, triangleIndices: triangles)
    }
    
    /// Generate a simple triangle for minimal testing
    static func triangle() -> Mesh {
        let vertices: [SIMD3<Float>] = [
            SIMD3<Float>(0, 1, 0),    // top
            SIMD3<Float>(-1, -1, 0),  // bottom-left
            SIMD3<Float>(1, -1, 0)    // bottom-right
        ]
        
        let triangles: [Int] = [0, 1, 2]
        
        return Mesh(vertices: vertices, triangleIndices: triangles)
    }
    
    /// Generate a more complex mesh for stress testing
    static func icosahedron() -> Mesh {
        let phi = (1.0 + sqrt(5.0)) / 2.0 // Golden ratio
        let inv_norm = 1.0 / sqrt(phi * phi + 1.0)
        
        let a = Float(inv_norm)
        let b = Float(phi * inv_norm)
        
        // 12 vertices of icosahedron
        let vertices: [SIMD3<Float>] = [
            SIMD3<Float>(-a,  b,  0), SIMD3<Float>( a,  b,  0), SIMD3<Float>(-a, -b,  0), SIMD3<Float>( a, -b,  0),
            SIMD3<Float>( 0, -a,  b), SIMD3<Float>( 0,  a,  b), SIMD3<Float>( 0, -a, -b), SIMD3<Float>( 0,  a, -b),
            SIMD3<Float>( b,  0, -a), SIMD3<Float>( b,  0,  a), SIMD3<Float>(-b,  0, -a), SIMD3<Float>(-b,  0,  a)
        ]
        
        // 20 triangular faces
        let triangles: [Int] = [
            // 5 faces around point 0
            0, 11, 5,  0, 5, 1,  0, 1, 7,  0, 7, 10,  0, 10, 11,
            
            // Adjacent faces
            1, 5, 9,  5, 11, 4,  11, 10, 2,  10, 7, 6,  7, 1, 8,
            
            // 5 faces around point 3
            3, 9, 4,  3, 4, 2,  3, 2, 6,  3, 6, 8,  3, 8, 9,
            
            // Adjacent faces
            4, 9, 5,  2, 4, 11,  6, 2, 10,  8, 6, 7,  9, 8, 1
        ]
        
        return Mesh(vertices: vertices, triangleIndices: triangles)
    }
}

// MARK: - Test Utilities

extension SyntheticMeshes {
    /// Validate mesh has proper structure
    static func validateMesh(_ mesh: Mesh) -> Bool {
        // Check triangle indices are valid
        for index in mesh.triangleIndices {
            if index < 0 || index >= mesh.vertices.count {
                return false
            }
        }
        
        // Check triangle count matches indices
        return mesh.triangleIndices.count % 3 == 0
    }
    
    /// Get expected panel count for known meshes
    static func expectedPanelCount(for mesh: Mesh, target: Int) -> Int {
        let triangleCount = mesh.triangleCount
        
        if triangleCount <= 4 { // Triangle or small mesh
            return 1
        } else if triangleCount <= 12 { // Cube
            return min(target, 6) // Cube has 6 faces maximum
        } else { // Complex mesh
            return min(target, triangleCount / 2) // Reasonable maximum
        }
    }
}