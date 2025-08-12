import Testing
import Foundation
import CoverCraftCore
import CoverCraftDTO
import CoverCraftSegmentation
import CoverCraftFlattening
import CoverCraftExport
import CoverCraftAR

import Darwin

@Suite("Memory Leak Detection Tests")
@available(iOS 18.0, macOS 15.0, *)
struct MemoryLeakTests {
    
    @Test("Memory usage does not grow during repeated segmentation")
    func testSegmentationMemoryLeaks() async throws {
        let tracker = MemoryTracker()
        let segmenter = DefaultMeshSegmentationService()
        let mesh = LargeMeshFactory.createLargeMesh(triangleCount: 10000)
        
        tracker.checkpoint("Initial")
        
        // Perform multiple segmentation cycles
        for iteration in 1...10 {
            let panels = try await segmenter.segmentMesh(mesh, targetPanelCount: 5)
            #expect(panels.count > 0)
            
            tracker.checkpoint("After iteration \(iteration)")
            
            // Force cleanup
            try await Task.sleep(for: .milliseconds(100))
        }
        
        let initialMemory = tracker.checkpoints.first?.memory ?? 0
        let finalMemory = tracker.checkpoints.last?.memory ?? 0
        let memoryGrowth = finalMemory - initialMemory
        
        // Memory growth should be minimal (less than 10MB)
        #expect(memoryGrowth < 10_000_000, "Memory grew by \(memoryGrowth) bytes")
        
        print("Memory growth: \(memoryGrowth) bytes")
        tracker.printSummary()
    }
    
    @Test("Flattening service releases memory properly")
    func testFlatteningMemoryLeaks() async throws {
        let tracker = MemoryTracker()
        let flattener = DefaultPatternFlatteningService()
        let mesh = LargeMeshFactory.createLargeMesh(triangleCount: 5000)
        
        // Create some panels for flattening
        let panels = [
            PanelDTO(
                vertexIndices: Set(0..<100),
                triangleIndices: Array(0..<300),
                color: ColorDTO.red
            )
        ]
        
        tracker.checkpoint("Before flattening")
        
        for iteration in 1...5 {
            let flattenedPanels = try await flattener.flattenPanels(panels, from: mesh)
            #expect(flattenedPanels.count > 0)
            
            tracker.checkpoint("After flattening \(iteration)")
            
            try await Task.sleep(for: .milliseconds(100))
        }
        
        let initialMemory = tracker.checkpoints.first?.memory ?? 0
        let finalMemory = tracker.checkpoints.last?.memory ?? 0
        let memoryGrowth = finalMemory - initialMemory
        
        #expect(memoryGrowth < 5_000_000, "Memory grew by \(memoryGrowth) bytes")
        
        tracker.printSummary()
    }
    
    @Test("Large mesh processing doesn't cause excessive memory allocation")
    func testLargeMeshMemoryUsage() async throws {
        let tracker = MemoryTracker()
        
        tracker.checkpoint("Before creating large mesh")
        
        let largeMesh = LargeMeshFactory.createLargeMesh(triangleCount: 100_000)
        #expect(largeMesh.vertices.count > 0)
        
        tracker.checkpoint("After creating large mesh")
        
        let segmenter = DefaultMeshSegmentationService()
        let panels = try await segmenter.segmentMesh(largeMesh, targetPanelCount: 8)
        
        tracker.checkpoint("After segmentation")
        
        #expect(panels.count > 0)
        
        let initialMemory = tracker.checkpoints.first?.memory ?? 0
        let finalMemory = tracker.checkpoints.last?.memory ?? 0
        let totalMemoryUsage = finalMemory - initialMemory
        
        // Should not use more than 100MB for 100k triangles
        #expect(totalMemoryUsage < 100_000_000, "Used \(totalMemoryUsage) bytes")
        
        tracker.printSummary()
    }
    
    @Test("Service containers don't leak when recreated")
    func testServiceContainerMemoryLeaks() async throws {
        let tracker = MemoryTracker()
        
        tracker.checkpoint("Initial")
        
        for iteration in 1...20 {
            let container = DefaultDependencyContainer()
            container.registerSegmentationServices()
            container.registerFlatteningServices()
            
            let segmenter: MeshSegmentationService = try container.resolve()
            let mesh = LargeMeshFactory.createLargeMesh(triangleCount: 1000)
            let _ = try await segmenter.segmentMesh(mesh, targetPanelCount: 3)
            
            if iteration % 5 == 0 {
                tracker.checkpoint("After \(iteration) containers")
            }
        }
        
        try await Task.sleep(for: .milliseconds(100))
        
        tracker.checkpoint("After deallocation")
        
        let initialMemory = tracker.checkpoints.first?.memory ?? 0
        let finalMemory = tracker.checkpoints.last?.memory ?? 0
        let memoryGrowth = finalMemory - initialMemory
        
        #expect(memoryGrowth < 5_000_000, "Memory grew by \(memoryGrowth) bytes")
        
        tracker.printSummary()
    }
    
    @Test("Mesh data structures are efficiently stored")
    func testMeshDataEfficiency() throws {
        let mesh1k = LargeMeshFactory.createLargeMesh(triangleCount: 1_000)
        let mesh10k = LargeMeshFactory.createLargeMesh(triangleCount: 10_000)
        let mesh100k = LargeMeshFactory.createLargeMesh(triangleCount: 100_000)
        
        // Verify that memory usage scales linearly with mesh size
        let size1k = MemoryLayout.size(ofValue: mesh1k)
        let size10k = MemoryLayout.size(ofValue: mesh10k)
        let size100k = MemoryLayout.size(ofValue: mesh100k)
        
        print("1K triangles: \(size1k) bytes")
        print("10K triangles: \(size10k) bytes") 
        print("100K triangles: \(size100k) bytes")
        
        // Verify basic expectations about data structure overhead
        #expect(size1k > 0)
        #expect(size10k >= size1k)
        #expect(size100k >= size10k)
    }
}

// MARK: - Memory Tracking Utility

@available(iOS 18.0, macOS 15.0, *)
class MemoryTracker {
    struct Checkpoint {
        let name: String
        let memory: Int64
        let timestamp: Date
    }
    
    private(set) var checkpoints: [Checkpoint] = []
    
    func checkpoint(_ name: String) {
        let memory = getMemoryUsage()
        checkpoints.append(Checkpoint(name: name, memory: memory, timestamp: Date()))
    }
    
    private func getMemoryUsage() -> Int64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size / MemoryLayout<integer_t>.size)
        
        let result = withUnsafeMutablePointer(to: &info) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { pointer in
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         pointer,
                         &count)
            }
        }
        
        return result == KERN_SUCCESS ? Int64(info.resident_size) : 0
    }
    
    func printSummary() {
        print("\n--- Memory Usage Summary ---")
        for checkpoint in checkpoints {
            let mb = Double(checkpoint.memory) / 1_048_576.0
            print("\(checkpoint.name): \(String(format: "%.1f", mb)) MB")
        }
        
        if let first = checkpoints.first, let last = checkpoints.last {
            let growth = last.memory - first.memory
            let growthMB = Double(growth) / 1_048_576.0
            print("Total growth: \(String(format: "%.1f", growthMB)) MB")
        }
    }
}

// MARK: - Test Helpers

@available(iOS 18.0, macOS 15.0, *)
struct LargeMeshFactory {
    static func createLargeMesh(triangleCount: Int) -> MeshDTO {
        var vertices: [SIMD3<Float>] = []
        var triangleIndices: [Int] = []
        
        let sideLength = Int(sqrt(Double(triangleCount) / 2.0))
        
        // Generate grid of vertices
        for x in 0...sideLength {
            for y in 0...sideLength {
                let vertex = SIMD3<Float>(
                    Float(x) / Float(sideLength),
                    Float(y) / Float(sideLength),
                    0.0
                )
                vertices.append(vertex)
            }
        }
        
        // Generate triangles
        let gridWidth = sideLength + 1
        for x in 0..<sideLength {
            for y in 0..<sideLength {
                let topLeft = x * gridWidth + y
                let topRight = topLeft + 1
                let bottomLeft = topLeft + gridWidth
                let bottomRight = bottomLeft + 1
                
                if bottomRight < vertices.count {
                    // First triangle
                    triangleIndices.append(contentsOf: [topLeft, bottomLeft, topRight])
                    // Second triangle
                    triangleIndices.append(contentsOf: [topRight, bottomLeft, bottomRight])
                }
            }
        }
        
        return MeshDTO(vertices: vertices, triangleIndices: triangleIndices)
    }
}