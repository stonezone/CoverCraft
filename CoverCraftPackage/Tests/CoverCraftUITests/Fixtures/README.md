# UI Tests Fixtures

This directory contains test fixtures for the UI module, providing app state data, navigation scenarios, and device configurations for testing SwiftUI interfaces and user interactions.

## Overview

The UI fixtures provide:
- **App State Management**: Complete application state scenarios
- **Navigation Flows**: Multi-screen navigation patterns  
- **Scan State Data**: AR scanning workflow states
- **Project Management**: Project listing and editing states
- **Settings Configuration**: User preference scenarios
- **Device Capabilities**: Hardware-specific testing data

## Fixture Files

### UIStateFixtures.swift
Contains comprehensive UI testing scenarios:

#### App State Scenarios
- `freshLaunchState` - First-time user onboarding required
- `returningUserState` - Existing user with projects
- `scanningState` - Active AR scanning in progress
- `errorState` - Error condition (AR not supported)
- `deepNavigationState` - Complex nested navigation

#### Scan State Progression
- `initialScanState` - Setup phase before scanning
- `activeScanningState` - AR scanning in progress
- `processingState` - Mesh processing after scan
- `completedScanState` - Successful scan completion
- `failedScanState` - Scan failure scenario

#### Project Management States
- `emptyProjectsState` - No projects (new user)
- `populatedProjectsState` - List with multiple projects
- `loadingProjectsState` - Loading projects from storage
- `searchingProjectsState` - Filtered search results

#### Panel Editor States
- `editingFrontPanelState` - Active editing mode
- `viewOnlyPanelState` - Read-only viewing mode
- `multiSelectPanelState` - Multiple points selected

#### Settings and Configuration
- `defaultSettingsState` - Default application settings
- `customizedSettingsState` - User-customized preferences

#### Device Capabilities
- `iphone15ProCapabilities` - Latest iPhone with LiDAR
- `iPadProCapabilities` - iPad Pro with larger screen
- `iphoneSECapabilities` - Limited capabilities device

### ProjectFixtures.swift (Embedded)
Sample project data:
- `basicTshirtProject` - Simple t-shirt pattern
- `complexGarmentProject` - Wedding dress with history
- `sampleProjects` - Collection of various projects

## Usage Patterns

### App State Testing
```swift
import Testing
import SwiftUI
@testable import CoverCraftUI

@Test func appLaunchStateHandling() {
    let freshState = UIStateFixtures.freshLaunchState
    
    #expect(freshState.isFirstLaunch == true)
    #expect(freshState.hasCompletedOnboarding == false)
    #expect(freshState.currentProject == nil)
    #expect(freshState.selectedTab == .scan)
}
```

### Navigation Testing
```swift
@Test func deepNavigationHandling() {
    let deepState = UIStateFixtures.deepNavigationState
    
    #expect(deepState.navigationPath.count == 3)
    #expect(deepState.navigationPath.contains(.projects))
    #expect(deepState.currentProject != nil)
}
```

### Scan Flow Testing
```swift
@Test func scanProgressionTesting() {
    // Test scan state progression
    let states = [
        UIStateFixtures.initialScanState,
        UIStateFixtures.activeScanningState,
        UIStateFixtures.processingState,
        UIStateFixtures.completedScanState
    ]
    
    for (index, state) in states.enumerated() {
        switch index {
        case 0: #expect(state.phase == .setup)
        case 1: #expect(state.phase == .scanning)
        case 2: #expect(state.phase == .processing)
        case 3: #expect(state.phase == .completed)
        default: break
        }
    }
}
```

### Project List Testing
```swift
@Test func projectListStates() {
    let empty = UIStateFixtures.emptyProjectsState
    let populated = UIStateFixtures.populatedProjectsState
    let searching = UIStateFixtures.searchingProjectsState
    
    #expect(empty.projects.isEmpty)
    #expect(populated.projects.count > 0)
    #expect(searching.searchText == "Shirt")
    #expect(searching.projects.allSatisfy { $0.name.contains("Shirt") })
}
```

### Panel Editor Testing
```swift
@Test func panelEditorStates() {
    let editing = UIStateFixtures.editingFrontPanelState
    let viewing = UIStateFixtures.viewOnlyPanelState
    let multiSelect = UIStateFixtures.multiSelectPanelState
    
    // Editing state
    #expect(editing.isEditing == true)
    #expect(editing.selectedTool != .none)
    #expect(editing.showGrid == true)
    
    // View-only state
    #expect(viewing.isEditing == false)
    #expect(viewing.selectedTool == .none)
    
    // Multi-select state
    if case .multiplePoints(let indices) = multiSelect.selectionState {
        #expect(indices.count > 1)
    } else {
        #expect(false, "Expected multiple point selection")
    }
}
```

### Settings Testing
```swift
@Test func settingsConfiguration() {
    let defaults = UIStateFixtures.defaultSettingsState
    let custom = UIStateFixtures.customizedSettingsState
    
    // Default settings
    #expect(defaults.theme == .system)
    #expect(defaults.units == .metric)
    #expect(defaults.enableHapticFeedback == true)
    
    // Customized settings
    #expect(custom.theme == .dark)
    #expect(custom.units == .imperial)
    #expect(custom.enableHapticFeedback == false)
    #expect(custom.debugMode == true)
}
```

### Device Capability Testing
```swift
@Test func deviceCapabilityHandling() {
    let iphone = UIStateFixtures.iphone15ProCapabilities
    let ipad = UIStateFixtures.iPadProCapabilities
    let se = UIStateFixtures.iphoneSECapabilities
    
    // iPhone 15 Pro capabilities
    #expect(iphone.hasLiDAR == true)
    #expect(iphone.supportsARWorldTracking == true)
    #expect(iphone.supportsDynamicIsland == true)
    
    // iPad Pro capabilities
    #expect(ipad.hasLiDAR == true)
    #expect(ipad.ramSize > iphone.ramSize)
    #expect(ipad.supportsDynamicIsland == false)
    
    // iPhone SE limitations
    #expect(se.hasLiDAR == false)
    #expect(se.ramSize < iphone.ramSize)
    #expect(se.supportsARWorldTracking == true) // Still supports AR
}
```

### SwiftUI View Testing
```swift
@Test func swiftUIViewStateTesting() {
    let scanState = UIStateFixtures.activeScanningState
    
    // Create view with state
    let view = ScanView(state: scanState)
    
    // Test view properties
    #expect(view.state.phase == .scanning)
    #expect(view.state.hasValidTracking == true)
}
```

## Test Categories

### Unit Tests - Individual Components
Use focused fixtures:
- Single app states for isolated testing
- Specific device capabilities
- Individual panel editor tools

### Integration Tests - User Flows
Use workflow fixtures:
- Complete scan progression
- Project creation to export
- Settings changes affecting behavior

### State Management Tests
Use state fixtures:
- State transitions and validation
- Navigation path management
- Error state handling

### UI Rendering Tests
Use visual fixtures:
- Different themes and appearances
- Device-specific layouts
- Accessibility configurations

### Performance Tests
Use complex fixtures:
- Large project lists
- Heavy scan data processing
- Complex navigation stacks

## SwiftUI Testing Patterns

### View State Injection
```swift
struct TestableView: View {
    let appState: AppState
    
    var body: some View {
        ContentView()
            .environment(appState)
    }
}

@Test func viewWithInjectedState() {
    let state = UIStateFixtures.returningUserState
    let view = TestableView(appState: state)
    
    // Test view behavior with specific state
}
```

### Navigation Testing
```swift
@Test func navigationFlowTesting() {
    let initialState = UIStateFixtures.freshLaunchState
    var currentState = initialState
    
    // Simulate navigation actions
    currentState = navigateToScan(from: currentState)
    #expect(currentState.selectedTab == .scan)
    
    currentState = navigateToProjects(from: currentState)
    #expect(currentState.selectedTab == .projects)
}
```

### Theme and Appearance Testing
```swift
@Test func themeHandling() {
    let lightState = UIStateFixtures.defaultSettingsState
    let darkState = UIStateFixtures.customizedSettingsState
    
    #expect(lightState.theme == .system)
    #expect(darkState.theme == .dark)
    
    // Test theme application
    let lightView = ThemedView(theme: lightState.theme)
    let darkView = ThemedView(theme: darkState.theme)
}
```

### Error State UI Testing
```swift
@Test func errorStatePresentation() {
    let errorState = UIStateFixtures.errorState
    
    #expect(errorState.error != nil)
    
    if case .arNotSupported(let message) = errorState.error {
        #expect(!message.isEmpty)
        // Test error UI presentation
    }
}
```

## Factory Methods

### Dynamic State Creation
```swift
// Create app state with specific project
let projectState = UIStateFixtures.appStateWithProject(myProject)

// Create scan state with specific phase
let scanningState = UIStateFixtures.scanStateWithPhase(.scanning)

// Create editor state with specific tool
let editingState = UIStateFixtures.panelEditorStateWithTool(.move)

// Get random state for varied testing
let randomState = UIStateFixtures.randomAppState()
```

### State Transitions
```swift
// Helper methods for state transitions
func transitionToScanning(from state: AppState) -> AppState {
    // Implementation
}

func completeOnboarding(from state: AppState) -> AppState {
    // Implementation  
}

func handleARError(_ error: AppError, in state: AppState) -> AppState {
    // Implementation
}
```

## Best Practices

### State Management Testing
```swift
// Always test state consistency
#expect(state.isFirstLaunch != state.hasCompletedOnboarding)

// Validate navigation path integrity
for destination in state.navigationPath {
    #expect(destination.isValid)
}

// Check device capability constraints
if !state.deviceCapabilities.hasLiDAR {
    #expect(state.selectedTab != .scan) // Should disable AR features
}
```

### Error State Testing
```swift
// Test all error scenarios
let errorStates = [
    UIStateFixtures.errorState,
    // Add more error states as needed
]

for errorState in errorStates {
    #expect(errorState.error != nil)
    #expect(!errorState.isLoading) // Should stop loading on error
}
```

### Performance State Testing
```swift
// Test with large data sets
let largeProjectList = Array(repeating: ProjectFixtures.basicTshirtProject, count: 1000)
let state = ProjectsState(
    projects: largeProjectList,
    selectedProject: nil,
    isLoading: false,
    searchText: "",
    sortOption: .name,
    filterOption: .all
)

// Validate performance doesn't degrade
measureTime {
    let filtered = filterProjects(state.projects, searchText: "Test")
    #expect(filtered.count >= 0)
}
```

### Accessibility Testing
```swift
@Test func accessibilityStateHandling() {
    let settings = UIStateFixtures.defaultSettingsState
    
    // Test accessibility-friendly settings
    let accessibleView = AccessibleView(settings: settings)
    // Validate accessibility labels, hints, etc.
}
```

## Fixture Maintenance

### Adding New States
1. Follow naming convention: `descriptiveScenarioState`
2. Ensure state consistency and validity
3. Include in appropriate collections
4. Document usage patterns

### State Validation
```swift
// All states should be internally consistent
func validateState(_ state: AppState) -> Bool {
    // Navigation path should be valid for current tab
    // Current project should exist if in project detail
    // Error state should prevent normal operations
    // etc.
}
```

### Device-Specific Testing
- Test on different screen sizes
- Validate capability-based feature availability
- Check memory constraints on limited devices
- Test performance on older hardware

### Quality Assurance
- All states represent realistic user scenarios
- State transitions are logical and tested
- Error states provide actionable information
- Performance states don't cause test timeouts