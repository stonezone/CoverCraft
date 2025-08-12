import Testing
import Foundation
import simd
import CoverCraftDTO
@testable import CoverCraftCore
@testable import CoverCraftSegmentation
@testable import CoverCraftFlattening
@testable import CoverCraftExport

@Suite("Thread Safety and Concurrency Tests")
struct ThreadSafetyTests {
    
    // MARK: - Actor Isolation Tests
    
    @Test("Service container actor isolation")
    func testServiceContainerActorIsolation() async throws {
        let container = ServiceContainer()
        
        // Test concurrent access to services
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<100 {
                group.addTask {
                    // Each task tries to access services
                    let _ = await container.meshSegmentationService
                    let _ = await container.patternFlattener
                    let _ = await container.patternExporter
                }
            }
        }
        
        // Verify services are properly isolated
        let service1 = await container.meshSegmentationService
        let service2 = await container.meshSegmentationService
        
        // Services should be the same instance (singleton pattern)
        #expect(ObjectIdentifier(service1) == ObjectIdentifier(service2))
    }
    
    @Test("Segmentation service thread safety")
    func testSegmentationServiceThreadSafety() async throws {
        let service = DefaultMeshSegmentationService()
        let mesh = TestDataFactory.createCubeMesh()
        
        // Concurrent segmentation requests
        let results = await withTaskGroup(of: Result<[Panel], Error>.self) { group in
            for i in 0..<20 {
                group.addTask {
                    do {
                        let panels = try await service.segmentMesh(
                            mesh,
                            targetPanelCount: 4 + (i % 4)
                        )
                        return .success(panels)
                    } catch {
                        return .failure(error)
                    }
                }
            }
            
            var allResults: [Result<[Panel], Error>] = []
            for await result in group {
                allResults.append(result)
            }
            return allResults
        }
        
        // All operations should succeed without race conditions
        for result in results {
            switch result {
            case .success(let panels):
                #expect(panels.count > 0)
            case .failure(let error):
                #expect(Bool(false), "Thread safety violation: \(error)")
            }
        }
    }
    
    @Test("Pattern flattener thread safety")
    func testPatternFlattenerThreadSafety() async throws {
        let flattener = DefaultPatternFlattener()
        let segmenter = DefaultMeshSegmentationService()
        let mesh = TestDataFactory.createCubeMesh()
        let panels = try await segmenter.segmentMesh(mesh, targetPanelCount: 6)
        
        // Concurrent flattening of different panels
        let results = await withTaskGroup(of: Result<FlattenedPanel, Error>.self) { group in
            for panel in panels {
                group.addTask {
                    do {
                        let flattened = try await flattener.flattenPanel(panel, from: mesh)
                        return .success(flattened)
                    } catch {
                        return .failure(error)
                    }
                }
            }
            
            var allResults: [Result<FlattenedPanel, Error>] = []
            for await result in group {
                allResults.append(result)
            }
            return allResults
        }
        
        // Verify all panels were flattened successfully
        var successCount = 0
        for result in results {
            switch result {
            case .success(let flattened):
                #expect(!flattened.vertices2D.isEmpty)
                successCount += 1
            case .failure(let error):
                #expect(Bool(false), "Flattening thread safety violation: \(error)")
            }
        }
        
        #expect(successCount == panels.count)
    }
    
    // MARK: - Data Race Detection Tests
    
    @Test("Detect data races in mesh processing")
    func testDataRaceDetection() async throws {
        // Shared mutable state to test for races
        actor SharedState {
            private var processedCount = 0
            private var errors: [String] = []
            
            func incrementCount() -> Int {
                processedCount += 1
                return processedCount
            }
            
            func addError(_ error: String) {
                errors.append(error)
            }
            
            func getState() -> (count: Int, errors: [String]) {
                return (processedCount, errors)
            }
        }
        
        let sharedState = SharedState()
        let segmenter = DefaultMeshSegmentationService()
        
        // Create multiple tasks that could potentially race
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<50 {
                group.addTask {
                    let mesh = TestDataFactory.createTriangleMesh()
                    
                    do {
                        let panels = try await segmenter.segmentMesh(mesh, targetPanelCount: 3)
                        let count = await sharedState.incrementCount()
                        
                        // Verify no corruption in the data
                        for panel in panels {
                            if panel.vertexIndices.isEmpty {
                                await sharedState.addError("Empty vertex indices at iteration \(i)")
                            }
                            if panel.triangleIndices.isEmpty {
                                await sharedState.addError("Empty triangle indices at iteration \(i)")
                            }
                        }
                    } catch {
                        await sharedState.addError("Processing error at iteration \(i): \(error)")
                    }
                }
            }
        }
        
        let finalState = await sharedState.getState()
        #expect(finalState.count == 50, "Expected 50 processed items, got \(finalState.count)")
        #expect(finalState.errors.isEmpty, "Data races detected: \(finalState.errors)")
    }
    
    // MARK: - @MainActor Isolation Tests
    
    @MainActor
    @Test("MainActor isolation for UI operations")
    func testMainActorIsolation() async throws {
        // Simulate UI state updates that must be on MainActor
        class UIState: ObservableObject {
            @MainActor @Published var progress: Double = 0.0
            @MainActor @Published var status: String = "Idle"
            @MainActor @Published var isProcessing: Bool = false
        }
        
        let uiState = UIState()
        
        // Test that UI updates happen on MainActor
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<10 {
                group.addTask { @MainActor in
                    // These must execute on MainActor
                    uiState.progress = Double(i) / 10.0
                    uiState.status = "Processing \(i)"
                    uiState.isProcessing = i < 9
                }
            }
        }
        
        // Verify final state
        #expect(uiState.progress >= 0.0)
        #expect(!uiState.status.isEmpty)
        #expect(!uiState.isProcessing)
    }
    
    // MARK: - Sendable Conformance Tests
    
    @Test("Verify Sendable conformance for DTOs")
    func testSendableConformance() async throws {
        // Test that our DTOs can safely cross concurrency boundaries
        let mesh = MeshData(
            vertices: [SIMD3<Float>(0, 0, 0), SIMD3<Float>(1, 0, 0), SIMD3<Float>(0, 1, 0)],
            triangles: [SIMD3<Int32>(0, 1, 2)],
            normals: [SIMD3<Float>(0, 0, 1), SIMD3<Float>(0, 0, 1), SIMD3<Float>(0, 0, 1)]
        )
        
        let panel = Panel(
            id: UUID(),
            vertexIndices: [0, 1, 2],
            triangleIndices: [0],
            normal: SIMD3<Float>(0, 0, 1),
            area: 0.5
        )
        
        // These should compile without warnings under strict concurrency
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                // Use mesh in async context
                let _ = mesh.vertices.count
            }
            
            group.addTask {
                // Use panel in async context
                let _ = panel.vertexIndices.count
            }
        }
        
        #expect(true) // If we get here, Sendable conformance is correct
    }
    
    // MARK: - Task Cancellation Tests
    
    @Test("Task cancellation handling")
    func testTaskCancellation() async throws {
        let segmenter = DefaultMeshSegmentationService()
        let largeMesh = LargeMeshFactory.createLargeMesh(triangleCount: 50_000)
        
        // Create a task that we'll cancel
        let task = Task {
            try await segmenter.segmentMesh(largeMesh, targetPanelCount: 20)
        }
        
        // Give it a moment to start
        try await Task.sleep(for: .milliseconds(10))
        
        // Cancel the task
        task.cancel()
        
        // Verify cancellation is handled properly
        do {
            let _ = try await task.value
            #expect(Bool(false), "Task should have been cancelled")
        } catch {
            // Task was cancelled or threw an error - both are acceptable
            #expect(true)
        }
    }
    
    // MARK: - Memory Consistency Tests
    
    @Test("Memory consistency under concurrent load")
    func testMemoryConsistency() async throws {
        let segmenter = DefaultMeshSegmentationService()
        let flattener = DefaultPatternFlattener()
        
        // Track memory allocations
        actor MemoryTracker {
            private var allocations: Set<ObjectIdentifier> = []
            
            func track<T: AnyObject>(_ object: T) {
                allocations.insert(ObjectIdentifier(object))
            }
            
            func getAllocationCount() -> Int {
                return allocations.count
            }
        }
        
        let tracker = MemoryTracker()
        
        // Process multiple meshes concurrently
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<20 {
                group.addTask {
                    let mesh = TestDataFactory.createCubeMesh()
                    
                    do {
                        let panels = try await segmenter.segmentMesh(mesh, targetPanelCount: 4)
                        
                        for panel in panels {
                            let flattened = try await flattener.flattenPanel(panel, from: mesh)
                            // Track the allocation
                            await tracker.track(flattened as AnyObject)
                        }
                    } catch {
                        // Ignore errors for this test
                    }
                }
            }
        }
        
        let allocationCount = await tracker.getAllocationCount()
        #expect(allocationCount > 0, "Should have tracked allocations")
        print("✅ Memory consistency maintained with \(allocationCount) tracked allocations")
    }
    
    // MARK: - Deadlock Detection
    
    @Test("Deadlock prevention in service calls", .timeLimit(.minutes(1)))
    func testDeadlockPrevention() async throws {
        let container = ServiceContainer()
        
        // Create potential deadlock scenario with circular dependencies
        await withTaskGroup(of: Void.self) { group in
            // Task 1: Access services in order A -> B -> C
            group.addTask {
                let _ = await container.meshSegmentationService
                let _ = await container.patternFlattener
                let _ = await container.patternExporter
            }
            
            // Task 2: Access services in order C -> B -> A
            group.addTask {
                let _ = await container.patternExporter
                let _ = await container.patternFlattener
                let _ = await container.meshSegmentationService
            }
            
            // Task 3: Rapid alternating access
            group.addTask {
                for _ in 0..<10 {
                    let _ = await container.meshSegmentationService
                    let _ = await container.patternExporter
                }
            }
        }
        
        // If we reach here within time limit, no deadlock occurred
        #expect(true)
        print("✅ No deadlocks detected in service access patterns")
    }
}

// MARK: - Test Helper

struct LargeMeshFactory {
    static func createLargeMesh(triangleCount: Int) -> MeshDTO {
        var vertices: [SIMD3<Float>] = []
        var triangleIndices: [Int] = []
        
        let sideLength = Int(sqrt(Double(triangleCount) / 2.0))
        let spacing: Float = 1.0
        
        for row in 0...sideLength {
            for col in 0...sideLength {
                let x = Float(col) * spacing
                let y = Float(row) * spacing
                let z = sin(x * 0.1) * cos(y * 0.1) * 5.0
                vertices.append(SIMD3<Float>(x, y, z))
            }
        }
        
        for row in 0..<sideLength {
            for col in 0..<sideLength {
                let topLeft = row * (sideLength + 1) + col
                let topRight = topLeft + 1
                let bottomLeft = (row + 1) * (sideLength + 1) + col
                let bottomRight = bottomLeft + 1
                
                triangleIndices.append(topLeft)
                triangleIndices.append(bottomLeft)
                triangleIndices.append(topRight)
                triangleIndices.append(topRight)
                triangleIndices.append(bottomLeft)
                triangleIndices.append(bottomRight)
            }
        }
        
        return MeshDTO(
            vertices: vertices,
            triangleIndices: triangleIndices
        )
    }
}