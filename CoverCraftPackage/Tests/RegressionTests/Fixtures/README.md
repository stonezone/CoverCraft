# Regression Tests Fixtures

This directory contains test fixtures for Regression tests, providing historical bug scenarios, performance regression data, and edge case testing to prevent reoccurrence of known issues.

## Overview

The Regression fixtures focus on:
- **Historical Bug Prevention**: Test cases for previously reported and fixed bugs
- **Performance Regression Detection**: Monitoring for performance degradation
- **Edge Case Validation**: Boundary conditions that previously caused failures
- **Version Compatibility**: Ensuring fixes persist across releases

## Fixture Files

### RegressionFixtures.swift
Contains comprehensive regression testing data:

#### Historical Bug Test Cases
- `bug001_EmptyMeshCrash` - Crash with empty vertex arrays (v1.0.0 → v1.0.1)
- `bug002_CalibrationInfiniteLoop` - Scale calculation infinite loop (v1.0.1 → v1.0.2)
- `bug003_SegmentationMemoryLeak` - Memory leak in large mesh processing (v1.0.2 → v1.0.3)
- `bug004_SelfIntersectingPolygons` - Invalid 2D shapes from flattening (v1.0.3 → v1.0.4)
- `bug005_PDFCorruption` - Unicode character handling in exports (v1.0.4 → v1.0.5)
- `bug006_ARRotationCrash` - Device rotation during AR session (v1.0.5 → v1.0.6)
- `bug007_UIFreezeOnExport` - Main thread blocking during export (v1.0.6 → v1.0.7)
- `bug008_NegativeCoordinates` - Coordinate normalization issue (v1.0.7 → v1.0.8)

#### Performance Regression Cases
- `perfRegression001_MeshProcessing` - 3x performance degradation (v1.0.8 → v1.1.0)
- `perfRegression002_MemorySpike` - Memory usage doubled (v1.1.0 → v1.1.1)

#### Edge Case Regression Tests
- `edgeCase001_DataCorruption` - Degenerate triangles causing data corruption
- `edgeCase002_ExtremeScale` - Numeric overflow with extreme scale values

## Usage Patterns

### Bug Regression Testing
```swift
import Testing
@testable import CoverCraftCore

@Test func preventEmptyMeshCrash() {
    // Bug #001: Previously crashed when validating empty mesh
    let emptyMesh = RegressionFixtures.bug001_EmptyMeshCrash.testData.inputData
    
    if case .meshDTO(let mesh) = emptyMesh {
        // Should not crash - was fixed in v1.0.1
        let isValid = mesh.isValid
        #expect(isValid == false) // Should return false, not crash
        
        // Validate performance expectation
        let startTime = Date()
        _ = mesh.isValid
        let executionTime = Date().timeIntervalSince(startTime)
        
        let bug = RegressionFixtures.bug001_EmptyMeshCrash
        #expect(executionTime <= bug.testData.performanceExpectations.maxExecutionTime)
    }
}
```

### Performance Regression Monitoring
```swift
@Test func monitorMeshProcessingPerformance() {
    let regression = RegressionFixtures.perfRegression001_MeshProcessing
    let mesh = MeshFixtures.largeMesh
    
    let startTime = Date()
    let startMemory = getCurrentMemoryUsage()
    
    // Execute the operation that regressed
    let result = processMesh(mesh)
    
    let executionTime = Date().timeIntervalSince(startTime)
    let memoryUsed = getCurrentMemoryUsage() - startMemory
    
    // Should perform better than regression version
    let regressionMetrics = regression.testData.regressionMetrics
    #expect(executionTime < regressionMetrics.executionTime)
    #expect(memoryUsed < regressionMetrics.memoryUsage)
    
    // Should perform at least as well as baseline
    let baselineMetrics = regression.testData.baselineMetrics
    #expect(executionTime <= baselineMetrics.executionTime * 1.1) // 10% tolerance
}
```

### Edge Case Validation
```swift
@Test func preventDataCorruptionWithDegenerateTriangles() {
    let edgeCase = RegressionFixtures.edgeCase001_DataCorruption
    let mesh = edgeCase.inputData.mesh
    
    // Previously caused data corruption in segmentation
    let panels = segmentMesh(mesh)
    
    // Validate all criteria are met
    for criterion in edgeCase.validationCriteria {
        switch criterion {
        case .meshTopologyPreserved:
            #expect(validateTopology(mesh, panels))
        case .noDataCorruption:
            #expect(validateDataIntegrity(panels))
        case .gracefulDegenerateHandling:
            #expect(panels.allSatisfy { $0.isValid })
        default:
            break
        }
    }
}
```

### Bug Lifecycle Testing
```swift
@Test func verifyBugLifecycle() {
    // Test that a previously fixed bug remains fixed
    let bugCase = RegressionFixtures.bug002_CalibrationInfiniteLoop
    
    #expect(bugCase.reproduced == true) // Bug was successfully reproduced
    #expect(bugCase.fixed == true)      // Bug has been fixed
    #expect(bugCase.severity == .high)  // Appropriate severity classification
    
    // Verify fix version is after reported version
    let reportedVersion = Version(bugCase.reportedVersion)
    let fixedVersion = Version(bugCase.fixedVersion!)
    #expect(fixedVersion > reportedVersion)
}
```

### Scenario Reproduction Testing
```swift
@Test func reproduceExactBugScenario() {
    let bug = RegressionFixtures.bug005_PDFCorruption
    let scenario = bug.scenario
    
    // Follow exact reproduction steps
    // 1. Create project with Unicode name
    let projectName = "T-Shirt™ Design № 1" // Contains Unicode characters
    let project = createProject(name: projectName)
    
    // 2. Export to PDF
    let exportConfig = ExportFixtures.pdfPatternConfig
    let result = exportToPDF(project: project, config: exportConfig)
    
    // 3. Verify PDF is valid (was corrupted before fix)
    #expect(result.isSuccess)
    if let pdfData = result.outputData {
        #expect(validatePDFStructure(pdfData)) // Should be valid now
    }
}
```

### Memory Leak Detection
```swift
@Test func detectMemoryLeakRegression() {
    let bug = RegressionFixtures.bug003_SegmentationMemoryLeak
    
    guard case .meshDTO(let largeMesh) = bug.testData.inputData else {
        #expect(false, "Expected mesh input data")
        return
    }
    
    let initialMemory = getCurrentMemoryUsage()
    
    // Run segmentation multiple times (previously caused memory growth)
    for iteration in 1...10 {
        autoreleasepool {
            let panels = segmentMesh(largeMesh)
            #expect(panels.count > 0)
        }
        
        // Force garbage collection
        if iteration % 3 == 0 {
            performGarbageCollection()
        }
    }
    
    let finalMemory = getCurrentMemoryUsage()
    let memoryGrowth = finalMemory - initialMemory
    
    // Memory growth should be minimal (previously grew 50MB per iteration)
    let maxAllowedGrowth = 20 * 1024 * 1024 // 20MB tolerance
    #expect(memoryGrowth < maxAllowedGrowth)
}
```

### Version-Specific Testing
```swift
@Test func testFixedInSpecificVersion() {
    let bugsFixedIn105 = RegressionFixtures.testsForVersion("1.0.5")
    
    for bug in bugsFixedIn105 {
        #expect(bug.fixed == true)
        
        // Execute the test case to ensure fix persists
        let result = executeBugTestCase(bug)
        #expect(result.bugDidNotReoccur)
    }
}
```

## Test Categories

### Critical Bug Prevention
Use critical severity fixtures:
- Crash bugs that affect app stability
- Data corruption issues
- Security vulnerabilities

### Performance Monitoring
Use performance regression fixtures:
- Execution time regressions
- Memory usage increases
- CPU utilization spikes

### Edge Case Robustness
Use edge case fixtures:
- Boundary condition failures
- Input validation bypasses
- Numeric overflow/underflow

### Feature Regression
Use feature-specific fixtures:
- UI behavior changes
- Export format compatibility
- AR functionality regressions

## Bug Classification System

### Severity Levels
```swift
public enum BugSeverity: String, CaseIterable {
    case critical = "critical"   // Crashes, data loss, security
    case high = "high"          // Major functionality broken
    case medium = "medium"      // Minor functionality issues
    case low = "low"           // Cosmetic, usability issues
}
```

### Bug Lifecycle States
- **Reported**: Bug identified and documented
- **Reproduced**: Bug reproduction confirmed in test environment
- **Fixed**: Solution implemented and verified
- **Regression**: Bug reoccurred in later version

### Test Data Structure
```swift
public struct RegressionTestCase {
    let bugId: String              // Unique identifier
    let title: String              // Descriptive title
    let description: String        // Detailed description
    let severity: BugSeverity      // Impact classification
    let reportedVersion: String    // Version where bug appeared
    let fixedVersion: String?      // Version where bug was fixed
    let scenario: BugScenario      // Reproduction steps
    let testData: RegressionTestData // Test inputs and expectations
    let reproduced: Bool           // Successfully reproduced
    let fixed: Bool               // Currently fixed
}
```

## Automated Regression Detection

### Continuous Monitoring
```swift
@Test func continuousRegressionMonitoring() {
    // Run all fixed bug tests to ensure no regressions
    let fixedBugs = RegressionFixtures.fixedBugTests
    
    for bug in fixedBugs {
        let result = executeBugTestCase(bug)
        
        if !result.bugDidNotReoccur {
            reportRegression(bug: bug, evidence: result.failureEvidence)
        }
        
        #expect(result.bugDidNotReoccur, "Bug \(bug.bugId) has regressed!")
    }
}
```

### Performance Baseline Validation
```swift
@Test func validatePerformanceBaselines() {
    let performanceTests = RegressionFixtures.allPerformanceRegressionTests
    
    for perfTest in performanceTests {
        let currentMetrics = measureCurrentPerformance(perfTest.operation)
        let baselineMetrics = perfTest.testData.baselineMetrics
        
        // Current performance should be at least as good as baseline
        #expect(currentMetrics.executionTime <= baselineMetrics.executionTime * 1.2)
        #expect(currentMetrics.memoryUsage <= baselineMetrics.memoryUsage * 1.1)
    }
}
```

### Automated Bug Detection
```swift
@Test func automatedBugDetection() {
    // Test for common bug patterns
    let testInputs = [
        MeshFixtures.emptyMesh,
        MeshFixtures.degenerateTriangles,
        MeshFixtures.nonManifoldMesh,
        CalibrationFixtures.zeroDistance,
        CalibrationFixtures.negativeDistance
    ]
    
    for input in testInputs {
        // Should handle all edge cases gracefully
        let result = processInput(input)
        
        #expect(result.didNotCrash)
        #expect(result.didNotHang)
        #expect(result.hasValidOutput || result.hasExpectedError)
    }
}
```

## Factory Methods

### Bug Test Creation
```swift
// Get regression test for specific bug
let bugTest = RegressionFixtures.regressionTestForBug("BUG-001")

// Get all tests for version
let v105Tests = RegressionFixtures.testsForVersion("1.0.5")

// Get tests by severity
let criticalTests = RegressionFixtures.testsBySeverity(.critical)

// Get performance test data
let perfData = RegressionFixtures.performanceTestDataFor(.meshProcessing)
```

### Custom Regression Test Creation
```swift
func createCustomRegressionTest(
    bugId: String,
    inputData: Any,
    expectedBehavior: String,
    previousBehavior: String
) -> RegressionTestCase {
    // Implementation for creating custom regression tests
}
```

## Best Practices

### Bug Documentation
```swift
// Always document reproduction steps clearly
let scenario = BugScenario(
    preconditions: ["Clear, actionable prerequisites"],
    reproductionSteps: ["Step-by-step reproduction guide"],
    expectedBehavior: "What should happen",
    actualBehavior: "What actually happened"
)
```

### Performance Testing
```swift
// Use realistic performance expectations
let expectations = PerformanceExpectation(
    maxExecutionTime: 5.0,          // Reasonable timeout
    maxMemoryUsage: 256 * 1024 * 1024 // 256MB limit
)

// Always clean up after performance tests
defer {
    performGarbageCollection()
    clearCaches()
}
```

### Error Condition Testing
```swift
// Test all error conditions mentioned in bug reports
for errorCondition in bug.testData.errorConditions {
    switch errorCondition {
    case .shouldNotCrash:
        #expect(/* no crash occurred */)
    case .shouldNotHang:
        #expect(/* completed within timeout */)
    case .memoryLeakDetection:
        #expect(/* memory returned to baseline */)
    }
}
```

### Version Tracking
```swift
// Always track version information
let currentVersion = getAppVersion()
let bugFixVersion = Version(bug.fixedVersion!)

// Ensure we're testing with version that includes fix
#expect(currentVersion >= bugFixVersion)
```

## Fixture Maintenance

### Adding New Bug Tests
1. Assign unique bug ID (BUG-XXX format)
2. Classify severity appropriately
3. Document reproduction steps clearly
4. Include performance expectations
5. Verify test can reproduce original bug

### Performance Regression Updates
1. Update baseline metrics for new hardware
2. Account for legitimate performance improvements
3. Set reasonable tolerance ranges
4. Monitor for sustained regressions

### Edge Case Coverage
1. Add edge cases as they're discovered
2. Include boundary value testing
3. Test error propagation paths
4. Validate recovery mechanisms

### Quality Assurance
- All regression tests should be deterministic
- Bug scenarios should be reproducible
- Performance benchmarks should be stable
- Edge cases should be well-documented