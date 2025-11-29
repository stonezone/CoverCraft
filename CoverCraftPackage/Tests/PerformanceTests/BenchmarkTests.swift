import Testing
import Foundation
import CoverCraftCore
import CoverCraftDTO
import CoverCraftSegmentation
import CoverCraftFlattening
import CoverCraftExport

@preconcurrency import Darwin

@Suite("Performance Benchmark Tests")
struct BenchmarkTests {
    
    // MARK: - Test Data Factory
    
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
    
    // MARK: - Segmentation Performance Tests
    
    @Test("Segmentation performance - Target: 100K triangles in 2s")
    func testSegmentationPerformance() async throws {
        let segmenter = DefaultMeshSegmentationService()
        let mesh = LargeMeshFactory.createLargeMesh(triangleCount: 100_000)
        
        let startTime = Date()
        let panels = try await segmenter.segmentMesh(mesh, targetPanelCount: 8)
        let endTime = Date()
        
        let duration = endTime.timeIntervalSince(startTime)
        
        print("Segmentation took \(String(format: "%.2f", duration)) seconds for \(mesh.triangleCount) triangles")
        print("Generated \(panels.count) panels")
        
        // Performance target: should complete within 2 seconds
        #expect(duration < 2.0, "Segmentation took \(duration) seconds, expected < 2.0")
        #expect(panels.count > 0, "Should generate at least one panel")
        #expect(panels.count <= 8, "Should not exceed target panel count significantly")
    }
    
    @Test("Segmentation scalability test")
    func testSegmentationScalability() async throws {
        let segmenter = DefaultMeshSegmentationService()
        let sizes = [1_000, 5_000, 10_000, 25_000]
        
        var results: [(triangles: Int, duration: Double)] = []
        
        for triangleCount in sizes {
            let mesh = LargeMeshFactory.createLargeMesh(triangleCount: triangleCount)
            
            let startTime = Date()
            let panels = try await segmenter.segmentMesh(mesh, targetPanelCount: 5)
            let endTime = Date()
            
            let duration = endTime.timeIntervalSince(startTime)
            results.append((triangles: triangleCount, duration: duration))
            
            print("\(triangleCount) triangles: \(String(format: "%.3f", duration))s, \(panels.count) panels")
        }
        
        // Verify that performance scales reasonably
        for result in results {
            let expectedMaxTime = Double(result.triangles) / 50_000.0 // 50K triangles per second
            #expect(result.duration < expectedMaxTime, "Performance degraded for \(result.triangles) triangles")
        }
    }
    
    // MARK: - Flattening Performance Tests
    
    @Test("Pattern flattening performance")
    func testFlatteningPerformance() async throws {
        let segmenter = DefaultMeshSegmentationService()
        let flattener = DefaultPatternFlatteningService()
        
        let mesh = LargeMeshFactory.createLargeMesh(triangleCount: 50_000)
        let panels = try await segmenter.segmentMesh(mesh, targetPanelCount: 6)
        
        let startTime = Date()
        let flattenedPanels = try await flattener.flattenPanels(panels, from: mesh)
        let endTime = Date()
        
        let duration = endTime.timeIntervalSince(startTime)
        
        print("Flattening took \(String(format: "%.2f", duration)) seconds for \(panels.count) panels")
        print("Generated \(flattenedPanels.count) flattened panels")
        
        // Performance target: should complete within 1 second for moderate complexity
        #expect(duration < 1.0, "Flattening took \(duration) seconds, expected < 1.0")
        #expect(flattenedPanels.count == panels.count, "Should preserve panel count")
    }
    
    // MARK: - Export Performance Tests
    
    @Test("Export performance test")
    func testExportPerformance() async throws {
        let segmenter = DefaultMeshSegmentationService()
        let flattener = DefaultPatternFlatteningService()
        let exporter = DefaultPatternExportService()
        
        let mesh = LargeMeshFactory.createLargeMesh(triangleCount: 25_000)
        let panels = try await segmenter.segmentMesh(mesh, targetPanelCount: 5)
        let flattenedPanels = try await flattener.flattenPanels(panels, from: mesh)
        
        let exportOptions = ExportOptions(
            includeSeamAllowance: true,
            seamAllowanceWidth: 5.0,
            includeRegistrationMarks: true,
            paperSize: .a4,
            scale: 1.0,
            includeInstructions: false
        )
        
        let startTime = Date()
        let result = try await exporter.exportPatterns(flattenedPanels, format: .pdf, options: exportOptions)
        let endTime = Date()
        
        let duration = endTime.timeIntervalSince(startTime)
        
        print("Export took \(String(format: "%.2f", duration)) seconds")
        print("Generated \(result.data.count) bytes")
        
        #expect(duration < 0.5, "Export took \(duration) seconds, expected < 0.5")
        #expect(result.data.count > 0, "Should generate export data")
    }
    
    // MARK: - Memory Usage Tests
    
    @Test("Memory usage for large mesh - Target: <1GB")
    func testMemoryUsage() async throws {
        let initialMemory = getMemoryUsage()
        
        // Create and process a large mesh
        let segmenter = DefaultMeshSegmentationService()
        let flattener = DefaultPatternFlatteningService()
        let exporter = DefaultPatternExportService()
        
        let mesh = LargeMeshFactory.createLargeMesh(triangleCount: 100_000)
        let meshMemory = getMemoryUsage()
        let meshSize = meshMemory - initialMemory
        
        print("  Mesh memory usage: \(meshSize / 1_048_576) MB")
        
        let panels = try await segmenter.segmentMesh(mesh, targetPanelCount: 12)
        let segmentationMemory = getMemoryUsage()
        let segmentationSize = segmentationMemory - meshMemory
        
        print("  Segmentation memory delta: \(segmentationSize / 1_048_576) MB")
        
        var flattenedPanels: [FlattenedPanelDTO] = []
        for panel in panels {
            let flattened = try await flattener.flattenPanels([panel], from: mesh)
            flattenedPanels.append(contentsOf: flattened)
        }
        
        let flatteningMemory = getMemoryUsage()
        let flatteningSize = flatteningMemory - segmentationMemory
        
        print("  Flattening memory delta: \(flatteningSize / 1_048_576) MB")
        
        let exportOptions = ExportOptions(
            includeSeamAllowance: true,
            seamAllowanceWidth: 5.0,
            includeRegistrationMarks: false,
            paperSize: .a4,
            scale: 1.0,
            includeInstructions: false
        )
        
        let _ = try await exporter.exportPatterns(flattenedPanels, format: .pdf, options: exportOptions)
        let exportMemory = getMemoryUsage()
        let exportSize = exportMemory - flatteningMemory
        
        print("  Export memory delta: \(exportSize / 1_048_576) MB")
        
        let totalMemoryUsage = exportMemory - initialMemory
        print("  Total memory usage: \(totalMemoryUsage / 1_048_576) MB")
        
        // Memory target: should not exceed 1GB
        #expect(totalMemoryUsage < 1_073_741_824, "Total memory usage exceeded 1GB")
    }
    
    // MARK: - Concurrency Tests
    
    @Test("Concurrent segmentation stress test")
    func testConcurrentSegmentation() async throws {
        let segmenter = DefaultMeshSegmentationService()
        let meshes = (0..<10).map { _ in 
            LargeMeshFactory.createLargeMesh(triangleCount: 10_000)
        }
        
        let startTime = Date()
        
        // Process meshes concurrently
        let results = await withTaskGroup(of: Result<[PanelDTO], Error>.self) { group in
            for mesh in meshes {
                group.addTask {
                    do {
                        let panels = try await segmenter.segmentMesh(mesh, targetPanelCount: 5)
                        return .success(panels)
                    } catch {
                        return .failure(error)
                    }
                }
            }
            
            var allResults: [Result<[PanelDTO], Error>] = []
            for await result in group {
                allResults.append(result)
            }
            return allResults
        }
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        print("Concurrent segmentation of \(meshes.count) meshes took \(String(format: "%.2f", duration)) seconds")
        
        // Verify all succeeded
        let successCount = results.compactMap { result in
            switch result {
            case .success(let panels):
                return panels
            case .failure:
                return nil
            }
        }.count
        
        #expect(successCount == meshes.count, "All concurrent operations should succeed")
        #expect(duration < 5.0, "Concurrent processing should complete within 5 seconds")
    }
    
    // MARK: - Utility Functions
    
    private nonisolated func getMemoryUsage() -> Int64 {
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
}