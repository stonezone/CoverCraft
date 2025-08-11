# Integration Tests Fixtures

This directory contains test fixtures for Integration tests, providing cross-module workflow scenarios, performance benchmarks, and compatibility testing data.

## Overview

The Integration fixtures focus on:
- **Complete Workflows**: End-to-end user scenarios across modules
- **Error Recovery**: Handling failures and recovering gracefully
- **Module Integration**: Data flow between AR, Segmentation, Flattening, Export
- **Performance Benchmarks**: Scalability and efficiency testing
- **Device Compatibility**: Cross-platform behavior validation

## Fixture Files

### IntegrationFixtures.swift
Contains comprehensive integration testing scenarios:

#### Complete Workflow Scenarios
- `tshirtWorkflow` - End-to-end T-shirt pattern creation
- `cubeWorkflow` - Simple geometric shape workflow
- `complexGarmentWorkflow` - High-complexity multi-panel garment

#### Error Recovery Scenarios
- `trackingLostRecovery` - AR tracking interruption recovery
- `calibrationFailureRecovery` - Failed calibration retry logic
- `memoryPressureRecovery` - Low memory condition handling

#### Module Integration Tests
- `arToSegmentationIntegration` - Mesh → Panel data flow
- `segmentationToFlatteningIntegration` - Panel → 2D pattern flow
- `flatteningToExportIntegration` - Pattern → File export flow

#### Performance Benchmarks
- `largeMeshBenchmark` - Complex mesh processing performance
- `realTimeARBenchmark` - AR session frame rate testing

#### Compatibility Tests
- `iPhoneCompatibility` - iPhone device family testing
- `iPadCompatibility` - iPad-specific optimizations

## Usage Patterns

### End-to-End Workflow Testing
```swift
import Testing
@testable import CoverCraftCore

@Test func completeWorkflowExecution() async {
    let workflow = IntegrationFixtures.tshirtWorkflow
    
    // Execute complete workflow
    let result = await executeWorkflow(workflow)
    
    #expect(result.isSuccess)
    #expect(result.completedSteps.count == workflow.steps.count)
    #expect(result.executionTime <= workflow.expectedDuration)
    
    // Validate output data
    if case .exportData(let exportData) = result.finalOutput {
        #expect(exportData.count > 0)
        #expect(exportData.starts(with: "%PDF".data(using: .utf8)!))
    }
}
```

### Module Integration Testing
```swift
@Test func dataFlowIntegration() async {
    let integration = IntegrationFixtures.arToSegmentationIntegration
    let mesh = MeshFixtures.tshirtMesh
    
    // Test data flow from AR to Segmentation
    let segmentationResult = await processDataFlow(integration.dataFlow, input: mesh)
    
    #expect(segmentationResult.isSuccess)
    
    if case .panelData(let panels) = segmentationResult.output {
        #expect(panels.count > 0)
        #expect(panels.allSatisfy { $0.isValid })
        
        // Validate data flow rules
        for rule in integration.dataFlow.validationRules {
            #expect(validateRule(rule, input: mesh, output: panels))
        }
    }
}
```

### Error Recovery Testing
```swift
@Test func errorRecoveryHandling() async {
    let recovery = IntegrationFixtures.trackingLostRecovery
    
    // Simulate error condition
    let initialState = recovery.initialState
    let errorCondition = recovery.errorCondition
    
    // Execute recovery steps
    let recoveryResult = await executeErrorRecovery(
        from: initialState,
        error: errorCondition,
        steps: recovery.expectedRecoverySteps
    )
    
    #expect(recoveryResult.wasSuccessful)
    #expect(recoveryResult.executionTime <= recovery.recoveryTimeoutSeconds)
    
    // If recovery failed, check fallback action
    if !recoveryResult.wasSuccessful {
        let fallbackResult = await executeFallbackAction(recovery.fallbackAction)
        #expect(fallbackResult.isSuccess)
    }
}
```

### Performance Benchmark Testing
```swift
@Test func performanceBenchmarkValidation() async {
    let benchmark = IntegrationFixtures.largeMeshBenchmark
    
    let startTime = Date()
    let startMemory = getCurrentMemoryUsage()
    
    // Execute benchmark test case
    let result = await executeBenchmark(benchmark.testCase)
    
    let executionTime = Date().timeIntervalSince(startTime)
    let memoryUsage = getCurrentMemoryUsage() - startMemory
    
    // Validate performance metrics
    #expect(executionTime <= benchmark.expectedMetrics.maxProcessingTime)
    #expect(memoryUsage <= benchmark.expectedMetrics.maxMemoryUsage)
    
    // Check device requirements
    let currentDevice = getCurrentDeviceCapabilities()
    #expect(currentDevice.meets(benchmark.deviceRequirements))
}
```

### Cross-Platform Compatibility Testing
```swift
@Test func deviceCompatibilityValidation() async {
    let compatibility = IntegrationFixtures.iPhoneCompatibility
    
    for deviceProfile in compatibility.targetDevices {
        // Simulate device capabilities
        configureForDevice(deviceProfile.capabilities)
        
        for scenario in compatibility.testScenarios {
            let result = await executeWorkflow(scenario)
            
            // Check expected behaviors
            for behavior in compatibility.expectedBehaviors {
                #expect(validateBehavior(behavior, result: result, device: deviceProfile))
            }
        }
    }
}
```

### Stress Testing
```swift
@Test func systemStressTesting() async {
    let complexWorkflow = IntegrationFixtures.complexGarmentWorkflow
    
    // Execute workflow multiple times concurrently
    let concurrentTasks = (0..<5).map { _ in
        Task {
            await executeWorkflow(complexWorkflow)
        }
    }
    
    let results = await withTaskGroup(of: WorkflowResult.self) { group in
        concurrentTasks.forEach { task in
            group.addTask { await task.value }
        }
        
        var allResults: [WorkflowResult] = []
        for await result in group {
            allResults.append(result)
        }
        return allResults
    }
    
    // All concurrent executions should succeed
    #expect(results.allSatisfy { $0.isSuccess })
    
    // Performance should not degrade significantly
    let averageTime = results.map { $0.executionTime }.reduce(0, +) / Double(results.count)
    #expect(averageTime <= complexWorkflow.expectedDuration * 1.5)
}
```

## Test Categories

### End-to-End Workflow Tests
Use complete scenarios:
- `tshirtWorkflow` for standard user flow
- `complexGarmentWorkflow` for advanced scenarios
- `cubeWorkflow` for simple validation

### Module Boundary Tests
Use integration fixtures:
- Data format compatibility
- Error propagation between modules
- Performance impact of module transitions

### Error Handling and Recovery Tests
Use recovery scenarios:
- Network failures during export
- Memory pressure during processing
- AR tracking interruptions

### Performance and Scalability Tests
Use benchmark fixtures:
- Large data set processing
- Concurrent user simulation
- Memory usage validation

### Platform Compatibility Tests
Use device-specific fixtures:
- Feature availability on different devices
- Performance scaling across hardware
- UI adaptation to screen sizes

## Workflow Execution Patterns

### Sequential Step Execution
```swift
@Test func sequentialWorkflowExecution() async {
    let workflow = IntegrationFixtures.tshirtWorkflow
    var currentState: WorkflowState = .initializing
    
    for step in workflow.steps {
        let stepResult = await executeWorkflowStep(step, currentState: currentState)
        #expect(stepResult.isSuccess)
        currentState = stepResult.newState
    }
    
    #expect(currentState == .completed)
}
```

### Parallel Processing Testing
```swift
@Test func parallelProcessingCapability() async {
    let panels = PanelFixtures.tshirtPanelSet
    
    // Process panels in parallel
    let results = await withTaskGroup(of: FlattenedPanelDTO.self) { group in
        for panel in panels {
            group.addTask {
                await flattenPanel(panel)
            }
        }
        
        var flattenedPanels: [FlattenedPanelDTO] = []
        for await result in group {
            flattenedPanels.append(result)
        }
        return flattenedPanels
    }
    
    #expect(results.count == panels.count)
    #expect(results.allSatisfy { $0.isValid })
}
```

### State Persistence Testing
```swift
@Test func workflowStatePersistence() async {
    let workflow = IntegrationFixtures.complexGarmentWorkflow
    
    // Execute partial workflow
    let partialResult = await executeWorkflowUntilStep(workflow, stepIndex: 3)
    
    // Save state
    let savedState = partialResult.currentState
    await saveWorkflowState(savedState)
    
    // Restore and continue
    let restoredState = await loadWorkflowState()
    let finalResult = await continueWorkflowFromState(workflow, state: restoredState)
    
    #expect(finalResult.isSuccess)
}
```

## Performance Testing Patterns

### Memory Usage Monitoring
```swift
@Test func memoryUsageValidation() async {
    let benchmark = IntegrationFixtures.largeMeshBenchmark
    
    let initialMemory = getCurrentMemoryUsage()
    
    // Execute memory-intensive operation
    let result = await executeBenchmark(benchmark.testCase)
    
    let peakMemory = getPeakMemoryUsage()
    let finalMemory = getCurrentMemoryUsage()
    
    // Memory should return to near-initial levels (allowing for some overhead)
    #expect(finalMemory - initialMemory < 50 * 1024 * 1024) // 50MB tolerance
    #expect(peakMemory <= benchmark.expectedMetrics.maxMemoryUsage)
}
```

### CPU Usage Monitoring
```swift
@Test func cpuUsageValidation() async {
    let benchmark = IntegrationFixtures.realTimeARBenchmark
    
    let monitor = CPUUsageMonitor()
    monitor.start()
    
    let result = await executeBenchmark(benchmark.testCase)
    
    let avgCPUUsage = monitor.stop()
    
    #expect(avgCPUUsage <= benchmark.expectedMetrics.maxCPUUsage)
    #expect(result.frameRate >= benchmark.expectedMetrics.targetFrameRate)
}
```

### Throughput Testing
```swift
@Test func throughputMeasurement() async {
    let operations = 100
    let startTime = Date()
    
    // Process multiple operations
    let results = await processOperationsBatch(count: operations)
    
    let executionTime = Date().timeIntervalSince(startTime)
    let throughput = Double(operations) / executionTime
    
    #expect(throughput >= 10.0) // Minimum 10 operations per second
    #expect(results.count == operations)
}
```

## Factory Methods

### Dynamic Workflow Creation
```swift
// Create workflow with specific mesh
let customWorkflow = IntegrationFixtures.workflowWithMesh(myMesh)

// Get random workflow for varied testing
let randomWorkflow = IntegrationFixtures.randomWorkflowScenario()

// Create benchmark for specific operation
let benchmark = IntegrationFixtures.benchmarkForOperation(.meshProcessing)
```

### Error Scenario Generation
```swift
// Create error recovery scenario
func createMemoryPressureScenario(initialData: MeshDTO) -> ErrorRecoveryScenario {
    ErrorRecoveryScenario(
        name: "Memory Pressure Recovery",
        description: "Recovery from low memory during processing",
        initialState: .processing(initialData, progress: 0.8),
        errorCondition: .insufficientMemory("Low memory warning"),
        expectedRecoverySteps: [.reduceMeshResolution, .clearTemporaryData],
        recoveryTimeoutSeconds: 15.0,
        fallbackAction: .simplifyMesh,
        testData: ErrorRecoveryTestData(/* ... */)
    )
}
```

## Best Practices

### Workflow Design
- Keep workflows focused and testable
- Include realistic timing expectations
- Test both success and failure paths
- Validate data integrity throughout pipeline

### Error Recovery Testing
```swift
// Always test recovery timeout
let recoveryStart = Date()
let result = await executeErrorRecovery(scenario)
let recoveryTime = Date().timeIntervalSince(recoveryStart)

#expect(recoveryTime <= scenario.recoveryTimeoutSeconds)

// Test fallback actions
if !result.wasSuccessful {
    let fallback = await executeFallbackAction(scenario.fallbackAction)
    #expect(fallback.providesValidState)
}
```

### Performance Testing Guidelines
- Use realistic data sizes
- Test on target hardware
- Monitor resource usage continuously
- Set reasonable performance expectations

### Cross-Module Validation
```swift
// Validate data compatibility between modules
func validateDataFlow<Input, Output>(
    _ flow: DataFlowScenario,
    input: Input,
    output: Output
) -> Bool {
    for rule in flow.validationRules {
        if !rule.validate(input: input, output: output) {
            return false
        }
    }
    return true
}
```

## Fixture Maintenance

### Adding New Workflows
1. Define clear step-by-step progression
2. Include realistic timing expectations
3. Add validation checkpoints
4. Test on multiple device types

### Performance Benchmark Updates
1. Update metrics based on new hardware
2. Test on minimum supported devices
3. Validate benchmark reliability
4. Monitor for performance regressions

### Error Scenario Coverage
1. Cover all major failure modes
2. Test recovery mechanisms
3. Validate fallback actions
4. Ensure graceful degradation

### Quality Assurance
- All workflows should be deterministic
- Performance benchmarks should be repeatable
- Error scenarios should be recoverable
- Integration points should be well-defined